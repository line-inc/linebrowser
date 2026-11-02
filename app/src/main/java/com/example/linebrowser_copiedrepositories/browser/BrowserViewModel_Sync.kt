/*
 * Line Browser - A premium, private, and secure web browser.
 * Copyright (C) 2026 Line Inc.
 */

package com.example.linebrowser_copiedrepositories.browser

import android.util.Log
import org.mozilla.geckoview.GeckoRuntime
import org.mozilla.geckoview.WebExtensionController

internal const val OMNI_SYNC_EXTENSION_ID = "line-sync@linebrowser.org"

internal fun BrowserViewModel.installLineSyncExtension(runtime: GeckoRuntime) {
    runtime.webExtensionController.ensureBuiltIn(
        "resource://android/assets/web_extensions/line_sync/",
        OMNI_SYNC_EXTENSION_ID
    ).accept(
        { ext ->
            ext?.let {
                runtime.webExtensionController.setAllowedInPrivateBrowsing(it, true)
                runtime.webExtensionController.enable(it, WebExtensionController.EnableSource.APP)
                Log.i(BrowserViewModel.Companion.TAG, "Line Sync pre-installed built-in WebExtension active.")
            }
        },
        { error ->
            Log.e(BrowserViewModel.Companion.TAG, "Failed to load Line Sync WebExtension", error)
        }
    )
}
