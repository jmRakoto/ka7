package mg.rakoto.ka7

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.DocumentsContract
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import androidx.documentfile.provider.DocumentFile

/**
 * `pick` from app/lib/platform/android_folders.dart: Android's folder picker
 * (any folder, SD card included). Ka7 keeps the right to write there across
 * restarts, and answers {uri, label}, or null when closed.
 *
 * `list` {uri}: every file under that folder, subfolders too, as
 * {uri, name, path} (path: its place in the folder); Dart keeps the
 * playable ones. Read off the main thread: a big folder takes a while.
 */
class FolderPicker(private val activity: Activity, messenger: BinaryMessenger) {
    private var waiting: MethodChannel.Result? = null

    init {
        MethodChannel(messenger, "mg.rakoto.ka7/folders").setMethodCallHandler { call, result ->
            if (call.method == "list") {
                val tree = Uri.parse(call.argument<String>("uri"))
                Thread {
                    val answer = runCatching { listTree(tree) }
                    main.post {
                        answer.fold(
                            { result.success(it) },
                            { result.error("unreadable", it.message, null) },
                        )
                    }
                }.start()
                return@setMethodCallHandler
            }
            if (call.method != "pick") return@setMethodCallHandler result.notImplemented()
            waiting?.success(null)
            waiting = result
            val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).addFlags(
                Intent.FLAG_GRANT_READ_URI_PERMISSION or
                    Intent.FLAG_GRANT_WRITE_URI_PERMISSION or
                    Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION,
            )
            // Opens on `from` (a folder picked before), else Music/Ka7.
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                intent.putExtra(DocumentsContract.EXTRA_INITIAL_URI, startOf(call.argument<String>("from")))
            }
            activity.startActivityForResult(intent, REQUEST)
        }
    }

    private val main = Handler(Looper.getMainLooper())

    private fun startOf(from: String?): Uri {
        if (from != null) {
            val tree = Uri.parse(from)
            return DocumentsContract.buildDocumentUriUsingTree(
                tree,
                DocumentsContract.getTreeDocumentId(tree),
            )
        }
        return DocumentsContract.buildDocumentUri(
            "com.android.externalstorage.documents",
            "primary:Music/Ka7",
        )
    }

    private fun listTree(tree: Uri): List<Map<String, String>> {
        val root = DocumentFile.fromTreeUri(activity, tree) ?: error("Folder gone: $tree")
        if (!root.exists()) error("Folder gone: $tree")
        val found = mutableListOf<Map<String, String>>()
        fun walk(dir: DocumentFile, prefix: String) {
            for (child in dir.listFiles()) {
                val name = child.name ?: continue
                if (child.isDirectory) {
                    walk(child, "$prefix$name/")
                } else {
                    found += mapOf("uri" to child.uri.toString(), "name" to name, "path" to "$prefix$name")
                }
            }
        }
        walk(root, "")
        return found
    }

    /** From MainActivity.onActivityResult; false when not ours. */
    fun onResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST) return false
        val result = waiting ?: return true
        waiting = null
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            result.success(null)
            return true
        }
        activity.contentResolver.takePersistableUriPermission(
            uri,
            Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION,
        )
        result.success(mapOf("uri" to uri.toString(), "label" to labelOf(uri)))
        return true
    }

    /** `primary:Music/Mozika` → `Music/Mozika`; on an SD card, `SD/…`. */
    private fun labelOf(uri: Uri): String {
        val id = DocumentsContract.getTreeDocumentId(uri)
        val volume = id.substringBefore(':')
        val path = id.substringAfter(':', "")
        return when {
            volume == "primary" && path.isEmpty() -> "/"
            volume == "primary" -> path
            path.isEmpty() -> "SD"
            else -> "SD/$path"
        }
    }

    private companion object {
        const val REQUEST = 4207
    }
}
