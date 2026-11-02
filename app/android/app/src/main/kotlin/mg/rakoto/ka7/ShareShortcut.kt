package mg.rakoto.ka7

import android.content.Context
import android.content.Intent
import android.content.pm.ShortcutInfo
import android.content.pm.ShortcutManager
import android.graphics.drawable.Icon
import android.os.Build

/**
 * "Ka7" in the top row of Android's share sheet (direct share), declared by
 * `res/xml/shortcuts.xml`. Android ranks it by use: [reportUsed] each time a
 * link is shared to Ka7.
 */
object ShareShortcut {
    private const val ID = "ka7-share"
    private const val CATEGORY = "mg.rakoto.ka7.category.SHARE_TARGET"

    /** Android 10+; publishing again only refreshes it. */
    fun publish(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return
        val manager = context.getSystemService(ShortcutManager::class.java) ?: return
        val shortcut = ShortcutInfo.Builder(context, ID)
            .setShortLabel("Ka7")
            .setIcon(Icon.createWithResource(context, R.mipmap.ic_launcher))
            .setIntent(Intent(context, MainActivity::class.java).setAction(Intent.ACTION_VIEW))
            .setCategories(setOf(CATEGORY))
            .apply {
                // Kept by the system across restarts, as share targets should.
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) setLongLived(true)
            }
            .build()
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                manager.pushDynamicShortcut(shortcut)
            } else {
                manager.addDynamicShortcuts(listOf(shortcut))
            }
        } catch (e: IllegalStateException) {
            // Rate-limited by the system: the shortcut published before stays.
        }
    }

    fun reportUsed(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return
        context.getSystemService(ShortcutManager::class.java)?.reportShortcutUsed(ID)
    }
}
