package mg.rakoto.ka7

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.provider.DocumentsContract
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * `pick` from app/lib/platform/android_folders.dart: Android's folder picker
 * (any folder, SD card included). Ka7 keeps the right to write there across
 * restarts, and answers {uri, label}, or null when closed.
 */
class FolderPicker(private val activity: Activity, messenger: BinaryMessenger) {
    private var waiting: MethodChannel.Result? = null

    init {
        MethodChannel(messenger, "mg.rakoto.ka7/folders").setMethodCallHandler { call, result ->
            if (call.method != "pick") return@setMethodCallHandler result.notImplemented()
            waiting?.success(null)
            waiting = result
            val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).addFlags(
                Intent.FLAG_GRANT_READ_URI_PERMISSION or
                    Intent.FLAG_GRANT_WRITE_URI_PERMISSION or
                    Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION,
            )
            activity.startActivityForResult(intent, REQUEST)
        }
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
