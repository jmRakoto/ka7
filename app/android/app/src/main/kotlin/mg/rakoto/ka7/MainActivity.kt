package mg.rakoto.ka7

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var share: MethodChannel? = null
    private var folders: FolderPicker? = null

    /** Text shared before Dart was listening (cold start from YouTube). */
    private var pending: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        YtDlpChannel(applicationContext, messenger)
        BackgroundChannel(this, messenger)
        MediaStoreChannel(applicationContext, messenger)
        folders = FolderPicker(this, messenger)
        share = MethodChannel(messenger, "mg.rakoto.ka7/share").apply {
            // Dart asks once it listens: hands over what arrived meanwhile.
            setMethodCallHandler { call, result ->
                if (call.method == "initial") {
                    result.success(pending)
                    pending = null
                } else {
                    result.notImplemented()
                }
            }
        }
        // "Download the update": the release page, in the browser.
        MethodChannel(messenger, "mg.rakoto.ka7/open").setMethodCallHandler { call, result ->
            val url = call.argument<String>("url")
            if (call.method == "url" && url != null) {
                startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url)))
                result.success(null)
            } else {
                result.notImplemented()
            }
        }
        pending = sharedText(intent)
        if (pending != null) ShareShortcut.reportUsed(applicationContext)
        ShareShortcut.publish(applicationContext)
    }

    @Deprecated("The picker answers here; Flutter's activity has no result API")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (folders?.onResult(requestCode, resultCode, data) != true) {
            @Suppress("DEPRECATION")
            super.onActivityResult(requestCode, resultCode, data)
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        sharedText(intent)?.let {
            ShareShortcut.reportUsed(applicationContext)
            share?.invokeMethod("shared", it)
        }
    }

    /** "Share → Ka7" from YouTube or a browser sends the link as text. */
    private fun sharedText(intent: Intent?): String? =
        if (intent?.action == Intent.ACTION_SEND && intent.type == "text/plain") {
            intent.getStringExtra(Intent.EXTRA_TEXT)
        } else {
            null
        }
}
