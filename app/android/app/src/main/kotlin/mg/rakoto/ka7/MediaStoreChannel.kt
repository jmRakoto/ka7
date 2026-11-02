package mg.rakoto.ka7

import android.Manifest
import android.content.ContentValues
import android.content.Context
import android.content.pm.PackageManager
import android.media.MediaScannerConnection
import android.os.Build
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors

/**
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

    /** Android 10+: no permission needed for files the app adds itself. */
    private fun publishToMediaStore(source: File, folder: String, name: String, mime: String) {
        val resolver = context.contentResolver
        val collection = if (mime.startsWith("video/")) {
            MediaStore.Video.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        } else {
            MediaStore.Audio.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        }
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
