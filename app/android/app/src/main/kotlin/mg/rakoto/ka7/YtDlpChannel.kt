package mg.rakoto.ka7

import android.content.Context
import android.os.Handler
import android.os.Looper
import com.yausername.ffmpeg.FFmpeg
import com.yausername.youtubedl_android.YoutubeDL
import com.yausername.youtubedl_android.YoutubeDLException
import com.yausername.youtubedl_android.YoutubeDLRequest
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

/**
 * yt-dlp embedded with youtubedl-android, seen from Dart as a process
 * (app/lib/platform/android_ytdlp.dart).
 *
 * - `init`: unpacks Python, yt-dlp and ffmpeg (first launch only).
 * - `update`: replaces yt-dlp with its latest stable release.
 * - `run` {args}: runs yt-dlp, answers {exitCode, out, err}.
 * - `start` {id, args}: starts yt-dlp, answers at once, then calls back
 *   `line` {id, line} for each output line and `exit` {id, exitCode, err}.
 * - `kill` {id}: stops a started run.
 */
class YtDlpChannel(private val context: Context, messenger: BinaryMessenger) :
    MethodChannel.MethodCallHandler {

    private val channel = MethodChannel(messenger, "mg.rakoto.ka7/ytdlp")
    private val worker = Executors.newCachedThreadPool()
    private val main = Handler(Looper.getMainLooper())

    init {
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "init" -> background(result) {
                YoutubeDL.getInstance().init(context)
                FFmpeg.getInstance().init(context)
                null
            }
            "run" -> background(result) { execute(call.args(), null) }
            "update" -> background(result) {
                YoutubeDL.getInstance().updateYoutubeDL(context, YoutubeDL.UpdateChannel.STABLE)?.name
            }
            "start" -> {
                val id = call.argument<String>("id")!!
                val args = call.args()
                worker.execute {
                    val outcome = execute(args, id) { line ->
                        main.post { channel.invokeMethod("line", mapOf("id" to id, "line" to line)) }
                    }
                    main.post { channel.invokeMethod("exit", outcome + ("id" to id)) }
                }
                result.success(null)
            }
            "kill" -> {
                YoutubeDL.getInstance().destroyProcessById(call.argument<String>("id")!!)
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    /** Runs yt-dlp; failures come back as an exit code and stderr, like a process. */
    private fun execute(
        args: List<String>,
        id: String?,
        onLine: ((String) -> Unit)? = null,
    ): Map<String, Any> = try {
        val request = YoutubeDLRequest(emptyList<String>()).addCommands(args)
        val response = YoutubeDL.getInstance().execute(request, id) { _, _, line ->
            onLine?.invoke(line)
        }
        mapOf("exitCode" to response.exitCode, "out" to response.out, "err" to response.err)
    } catch (e: YoutubeDL.CanceledException) {
        mapOf("exitCode" to -15, "out" to "", "err" to "")
    } catch (e: YoutubeDLException) {
        mapOf("exitCode" to 1, "out" to "", "err" to (e.message ?: ""))
    }

    private fun MethodCall.args(): List<String> = argument<List<String>>("args")!!

    private fun background(result: MethodChannel.Result, work: () -> Any?) {
        worker.execute {
            try {
                val value = work()
                main.post { result.success(value) }
            } catch (e: Exception) {
                main.post { result.error("ytdlp", e.message, null) }
            }
        }
    }
}
