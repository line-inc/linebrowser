package com.example.linebrowser_copiedrepositories.browser

data class HomeShortcut(
    val id: String,
    val title: String,
    val url: String,
    val isFeature: Boolean = false,
    val isPermanent: Boolean = false
)
