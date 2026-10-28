package com.example.linebrowser_copiedrepositories.browser

data class CustomSearchEngine(
    val name: String,
    val queryUrl: String,
    val suggestUrl: String = ""
)
