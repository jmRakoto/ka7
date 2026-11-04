package mg.rakoto.ka7

import android.Manifest
import android.content.ContentValues
import android.content.Context
import android.content.pm.PackageManager
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import androidx.documentfile.provider.DocumentFile
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors

/**
 * `exists` {folder, name, mime}: whether a filed download is still there.
 * `publishTree` {path, tree, folder, name} / `existsTree` {tree, folder, name}:
 * the same in a folder the user picked (FolderPicker.kt).
 * `publish` {path, folder, name, mime} from app/lib/platform/media_store.dart:
 * moves a finished file from the app's own folder to the shared library
 * (`folder` is "Music/Ka7/<playlist>" or "Movies/Ka7"), where every music and
 * video app finds it.
 */
class MediaStoreChannel(private val context: Context, messenger: BinaryMessenger) {
    private val worker = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    init {
        MethodChannel(messenger, "mg.rakoto.ka7/media").setMethodCallHandler { call, result ->
            if (call.method == "publishTree" || call.method == "existsTree") {
                val tree = Uri.parse(call.argument<String>("tree")!!)
                val folder = call.argument<String>("folder")!!
                val name = call.argument<String>("name")!!
                val path = call.argument<String>("path")
                worker.execute {
                    try {
                        val answer: Any? = if (path != null) {
                            publishToTree(File(path), tree, folder, name)
                            null
                        } else {
                            existsInTree(tree, folder, name)
                        }
                        main.post { result.success(answer) }
                    } catch (e: Exception) {
                        // Unsure whether it is there: keep it « already there ».
                        main.post {
                            if (path == null) result.success(true) else result.error("media", e.message, null)
                        }
                    }
                }
                return@setMethodCallHandler
            }
            if (call.method == "exists") {
                val folder = call.argument<String>("folder")!!
                val name = call.argument<String>("name")!!
                val mime = call.argument<String>("mime")!!
                worker.execute {
                    val found = try {
                        exists(folder, name, mime)
                    } catch (_: Exception) {
                        true // Unsure: keep it « already there », as before.
                    }
                    main.post { result.success(found) }
                }
                return@setMethodCallHandler
            }
            if (call.method != "publish") return@setMethodCallHandler result.notImplemented()
            val source = File(call.argument<String>("path")!!)
            val folder = call.argument<String>("folder")!!
            val name = call.argument<String>("name")!!
            val mime = call.argument<String>("mime")!!
            worker.execute {
                try {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        publishToMediaStore(source, folder, name, mime)
                    } else {
                        publishToSharedFolder(source, folder, name, mime)
                    }
                    main.post { result.success(null) }
                } catch (e: Exception) {
                    main.post { result.error("media", e.message, null) }
                }
            }
        }
    }

    /** Whether `folder/name` is still in the shared library (deleted by hand?). */
    private fun exists(folder: String, name: String, mime: String): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            context.contentResolver.query(
                collectionOf(mime),
                arrayOf(MediaStore.MediaColumns._ID),
                "${MediaStore.MediaColumns.RELATIVE_PATH} = ? AND ${MediaStore.MediaColumns.DISPLAY_NAME} = ?",
                arrayOf("$folder/", name),
                null,
            ).use { return (it?.count ?: 0) > 0 }
        }
        @Suppress("DEPRECATION")
        return File(Environment.getExternalStorageDirectory(), "$folder/$name").exists()
    }

    private fun collectionOf(mime: String) = if (mime.startsWith("video/")) {
        MediaStore.Video.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
    } else {
        MediaStore.Audio.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
    }

    /** Into the folder the user picked: its subfolders made as needed. */
    private fun publishToTree(source: File, tree: Uri, folder: String, name: String) {
        var dir = DocumentFile.fromTreeUri(context, tree) ?: error("Folder gone: $tree")
        for (part in folder.split('/').filter { it.isNotEmpty() }) {
            dir = dir.findFile(part)?.takeIf { it.isDirectory }
                ?: dir.createDirectory(part)
                ?: error("Cannot make $part")
        }
        // Downloaded again: replace our copy, not "name (1)".
        dir.findFile(name)?.delete()
        // No type: the provider keeps the name as given, extension included.
        val target = dir.createFile("application/octet-stream", name) ?: error("Cannot write $name")
        try {
            context.contentResolver.openOutputStream(target.uri)!!.use { out ->
                source.inputStream().use { it.copyTo(out) }
            }
        } catch (e: Exception) {
            target.delete()
            throw e
        }
        source.delete()
    }

    private fun existsInTree(tree: Uri, folder: String, name: String): Boolean {
        var dir = DocumentFile.fromTreeUri(context, tree) ?: return false
        for (part in folder.split('/').filter { it.isNotEmpty() }) {
            dir = dir.findFile(part)?.takeIf { it.isDirectory } ?: return false
        }
        return dir.findFile(name)?.exists() == true
    }

    /** Android 10+: no permission needed for files the app adds itself. */
    private fun publishToMediaStore(source: File, folder: String, name: String, mime: String) {
        val resolver = context.contentResolver
        val collection = collectionOf(mime)
        // Downloaded again after "Forget": replace our own copy, not "name (1)".
        try {
            resolver.delete(
                collection,
                "${MediaStore.MediaColumns.RELATIVE_PATH} = ? AND ${MediaStore.MediaColumns.DISPLAY_NAME} = ?",
                arrayOf("$folder/", name),
            )
        } catch (_: SecurityException) {
            // Someone else's file: Android picks another name.
        }
        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, name)
            put(MediaStore.MediaColumns.MIME_TYPE, mime)
            put(MediaStore.MediaColumns.RELATIVE_PATH, folder)
            put(MediaStore.MediaColumns.IS_PENDING, 1)
        }
        val uri = resolver.insert(collection, values) ?: error("MediaStore refused $name")
        try {
            resolver.openOutputStream(uri)!!.use { out -> source.inputStream().use { it.copyTo(out) } }
            resolver.update(uri, ContentValues().apply { put(MediaStore.MediaColumns.IS_PENDING, 0) }, null, null)
        } catch (e: Exception) {
            resolver.delete(uri, null, null)
            throw e
        }
        source.delete()
    }

    /** Android 7 to 9: the public folders, with the storage permission. */
    private fun publishToSharedFolder(source: File, folder: String, name: String, mime: String) {
        val permission = Manifest.permission.WRITE_EXTERNAL_STORAGE
        // Refused: the file stays in Ka7's own folder, still downloaded.
        if (context.checkSelfPermission(permission) != PackageManager.PERMISSION_GRANTED) return
        @Suppress("DEPRECATION")
        val target = File(Environment.getExternalStorageDirectory(), "$folder/$name")
        target.parentFile!!.mkdirs()
        source.copyTo(target, overwrite = true)
        source.delete()
        MediaScannerConnection.scanFile(context, arrayOf(target.path), arrayOf(mime), null)
    }
}
