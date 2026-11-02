package mg.rakoto.ka7

import android.Manifest
import android.app.Activity
import android.content.pm.PackageManager
import android.os.Build
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * `keep` {title, text, done, total} and `release` from
 * app/lib/platform/android_background.dart, for [DownloadService].
 */
class BackgroundChannel(private val activity: Activity, messenger: BinaryMessenger) {
    private var askedForNotifications = false

    init {
        MethodChannel(messenger, "mg.rakoto.ka7/background").setMethodCallHandler { call, result ->
            when (call.method) {
                "keep" -> {
                    askForNotificationsOnce()
                    DownloadService.keep(
                        activity.applicationContext,
                        call.argument<String>("title")!!,
                        call.argument<String>("text")!!,
                        call.argument<Int>("done")!!,
                        call.argument<Int>("total")!!,
                    )
                    result.success(null)
                }
                "release" -> {
                    DownloadService.release(activity.applicationContext)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    /**
     * Asked once, when downloads start. Android 13+: notifications (without
     * them the progress stays hidden, downloads still run). Android 7 to 9:
     * storage, to file music in Music (MediaStoreChannel).
     */
    private fun askForNotificationsOnce() {
        if (askedForNotifications) return
        askedForNotifications = true
        val wanted = when {
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU -> Manifest.permission.POST_NOTIFICATIONS
            Build.VERSION.SDK_INT < Build.VERSION_CODES.Q -> Manifest.permission.WRITE_EXTERNAL_STORAGE
            else -> return
        }
        if (activity.checkSelfPermission(wanted) != PackageManager.PERMISSION_GRANTED) {
            activity.requestPermissions(arrayOf(wanted), 0)
        }
    }
}
