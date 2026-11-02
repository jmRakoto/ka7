package mg.rakoto.ka7

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var share: MethodChannel? = null

    /** Text shared before Dart was listening (cold start from YouTube). */
    private var pending: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        YtDlpChannel(applicationContext, messenger)
        BackgroundChannel(this, messenger)
        MediaStoreChannel(applicationContext, messenger)
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
        pending = sharedText(intent)
        if (pending != null) ShareShortcut.reportUsed(applicationContext)
        ShareShortcut.publish(applicationContext)
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
