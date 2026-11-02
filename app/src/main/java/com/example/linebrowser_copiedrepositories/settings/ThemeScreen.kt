/*
 * Line Browser - A premium, private, and secure web browser.
 * Copyright (C) 2026 Line Inc.
 */

package com.example.linebrowser_copiedrepositories.settings

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.rounded.ArrowBack
import androidx.compose.material.icons.rounded.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.linebrowser_copiedrepositories.R
import com.example.linebrowser_copiedrepositories.browser.BrowserViewModel

private data class ThemeAppIconPreset(val key: String, val label: String, val resId: Int, val colors: Pair<Color, Color>)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ThemeScreen(
    viewModel: BrowserViewModel,
    onNavigateBack: () -> Unit
) {
    BackHandler {
        onNavigateBack()
    }
    
    val context = LocalContext.current
    val accentColor = MaterialTheme.colorScheme.primary
    val bgColor = MaterialTheme.colorScheme.background
    val cardColor = MaterialTheme.colorScheme.surface
    val cardBorderColor = MaterialTheme.colorScheme.outline.copy(alpha = 0.4f)
    val textPrimaryColor = MaterialTheme.colorScheme.onSurface
    val textSecondaryColor = MaterialTheme.colorScheme.onSurfaceVariant
    val dividerColor = MaterialTheme.colorScheme.outline.copy(alpha = 0.4f)

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(stringResource(id = R.string.theme_settings_title), fontWeight = FontWeight.Bold, color = textPrimaryColor) },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Rounded.ArrowBack,
                            contentDescription = stringResource(id = R.string.back_desc),
                            tint = textPrimaryColor
                        )
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = bgColor),
                modifier = Modifier.border(BorderStroke(0.5.dp, cardBorderColor.copy(alpha = 0.2f)))
            )
        },
        containerColor = bgColor
    ) { paddingValues ->
        val adaptiveContentCap = com.example.linebrowser_copiedrepositories.ui.adaptive.rememberAdaptiveUiMetrics().screenContentMaxWidth
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .wrapContentWidth(Alignment.CenterHorizontally)
                .widthIn(max = adaptiveContentCap)
                .fillMaxHeight()
                .padding(paddingValues)
                .verticalScroll(rememberScrollState())
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(24.dp)
        ) {
            // ── THEME MODE SECTION ─────────────────────────────────────────────
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Text(stringResource(id = R.string.appearance_theme), color = accentColor, fontWeight = FontWeight.Bold, fontSize = 11.sp, modifier = Modifier.padding(start = 4.dp))
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(16.dp))
                        .background(cardColor)
                        .border(0.5.dp, cardBorderColor, RoundedCornerShape(16.dp))
                        .padding(horizontal = 16.dp, vertical = 14.dp),
                    verticalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    // Theme Mode: Light | Creamy | Dark | AMOLED
                    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                        Text(stringResource(id = R.string.theme_mode), color = textPrimaryColor, fontSize = 14.sp, fontWeight = FontWeight.SemiBold)
                        val themeMode = when {
                            viewModel.followSystemTheme -> 0
                            viewModel.isCreamyMode -> 2
                            viewModel.isAmoledMode -> 4
                            viewModel.isDarkThemeEnabled -> 3
                            else -> 1
                        }
                        SingleChoiceSegmentedButtonRow(modifier = Modifier.fillMaxWidth()) {
                            val options = listOf(
                                stringResource(id = R.string.theme_system),
                                stringResource(id = R.string.theme_light),
                                stringResource(id = R.string.theme_creamy),
                                stringResource(id = R.string.theme_dark),
                                stringResource(id = R.string.theme_amoled)
                            )
                            options.forEachIndexed { index, label ->
                                SegmentedButton(
                                    shape = SegmentedButtonDefaults.itemShape(index = index, count = options.size),
                                    onClick = {
                                        when (index) {
                                            0 -> {
                                                viewModel.saveFollowSystemTheme(context, true)
                                                viewModel.saveAmoledMode(context, false)
                                                viewModel.saveCreamyMode(context, false)
                                            }
                                            1 -> {
                                                viewModel.saveFollowSystemTheme(context, false)
                                                viewModel.saveDarkTheme(context, false)
                                                viewModel.saveAmoledMode(context, false)
                                                viewModel.saveCreamyMode(context, false)
                                            }
                                            2 -> {
                                                viewModel.saveFollowSystemTheme(context, false)
                                                viewModel.saveDarkTheme(context, false)
                                                viewModel.saveAmoledMode(context, false)
                                                viewModel.saveCreamyMode(context, true)
                                            }
                                            3 -> {
                                                viewModel.saveFollowSystemTheme(context, false)
                                                viewModel.saveDarkTheme(context, true)
                                                viewModel.saveAmoledMode(context, false)
                                                viewModel.saveCreamyMode(context, false)
                                            }
                                            4 -> {
                                                viewModel.saveFollowSystemTheme(context, false)
                                                viewModel.saveDarkTheme(context, true)
                                                viewModel.saveAmoledMode(context, true)
                                                viewModel.saveCreamyMode(context, false)
                                            }
                                        }
                                    },
                                    selected = themeMode == index,
                                    icon = {}
                                ) {
                                    Text(
                                        text = label,
                                        fontSize = 11.sp,
                                        fontWeight = if (themeMode == index) FontWeight.Bold else FontWeight.Medium,
                                        maxLines = 1,
                                        softWrap = false,
                                        overflow = TextOverflow.Ellipsis
                                    )
                                }
                            }
                        }
                    }

                    HorizontalDivider(color = dividerColor)

                    // Accent Color selector
                    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                        Text(
                            stringResource(id = R.string.accent_color),
                            color = textPrimaryColor,
                            fontSize = 14.sp,
                            fontWeight = FontWeight.SemiBold
                        )
                        val accentOptions = listOf(
                            "Ocean Blue" to Color(0xFF0A84FF),
                            "Crimson Red" to Color(0xFFFF3B5C),
                            "Emerald Green" to Color(0xFF00C853),
                            "Sunset Orange" to Color(0xFFFF6D00),
                            "Royal Purple" to Color(0xFF7C4DFF),
                            "Monochrome" to Color(0xFFAAAAAA)
                        )
                        Row(
                            horizontalArrangement = Arrangement.spacedBy(10.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            accentOptions.forEach { (name, color) ->
                                Box(
                                    modifier = Modifier
                                        .size(32.dp)
                                        .clip(CircleShape)
                                        .background(color)
                                        .then(
                                            if (viewModel.selectedAccentTheme == name)
                                                Modifier.border(3.dp, textPrimaryColor.copy(alpha = 0.4f), CircleShape)
                                            else Modifier
                                        )
                                        .clickable { viewModel.saveAccentTheme(context, name) },
                                    contentAlignment = Alignment.Center
                                ) {
                                    if (viewModel.selectedAccentTheme == name) {
                                        Icon(
                                            imageVector = Icons.Rounded.Check,
                                            contentDescription = "Selected",
                                            tint = Color.White,
                                            modifier = Modifier.size(16.dp)
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ── WEBSITE DARK MODE ─────────────────────────────────────────────
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(16.dp))
                    .background(cardColor)
                    .border(1.dp, cardBorderColor, RoundedCornerShape(16.dp))
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp, vertical = 12.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column(modifier = Modifier.weight(1f)) {
                        Text(stringResource(id = R.string.appearance_force_dark_websites), color = textPrimaryColor, fontSize = 16.sp, fontWeight = FontWeight.SemiBold)
                        Text(stringResource(id = R.string.appearance_force_dark_websites_desc), color = textSecondaryColor, fontSize = 12.sp)
                    }
                    Switch(
                        checked = viewModel.forceDarkWebsites,
                        onCheckedChange = { viewModel.saveForceDarkWebsites(context, it) },
                        colors = SwitchDefaults.colors(checkedThumbColor = Color.White, checkedTrackColor = accentColor)
                    )
                }
            }
        }
    }
}
