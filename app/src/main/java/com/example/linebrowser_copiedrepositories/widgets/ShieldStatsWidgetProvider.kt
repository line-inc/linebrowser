/*
 * Copyright (C) 2026 Line Inc.
 */

package com.example.linebrowser_copiedrepositories.widgets

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import com.example.linebrowser_copiedrepositories.MainActivity
import com.example.linebrowser_copiedrepositories.R

class ShieldStatsWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        fun updateWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            val views = RemoteViews(context.packageName, R.layout.widget_shield_stats)

            val sp = context.getSharedPreferences("privacy_stats_prefs", Context.MODE_PRIVATE)
            val trackers = sp.getInt("trackers_blocked", 0)
            val dataMb = sp.getInt("data_saved_mb", 0)

            val formattedTrackers = String.format(java.util.Locale.getDefault(), "%,d", trackers)
            views.setTextViewText(R.id.txt_trackers_count, formattedTrackers)
            views.setTextViewText(R.id.txt_data_saved, "$dataMb MB")

            // Click root -> opens Line Browser
            val intent = Intent(context, MainActivity::class.java).apply {
                action = Intent.ACTION_VIEW
                putExtra("extra_widget_action", "privacy_report")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pendingIntent = PendingIntent.getActivity(
                context, 301, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_shield_root, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
