import 'package:flutter/material.dart';

import '../preferences/preference_keys.dart';
import '../preferences/preferences_controller.dart';

/// 与组件库无关的外观参数，由偏好设置解析得到。
///
/// 组件库在 `buildTheme` 中用它生成主题。页面中可以用
/// `TfDesign.appearanceOf(context)` 读取，例如在“减少动态效果”打开时跳过动画：
///
/// ```dart
/// final animate = !TfDesign.appearanceOf(context).reduceMotion;
/// ```
@immutable
class TfAppearance {
  const TfAppearance({
    this.themeMode = ThemeMode.system,
    this.seedColor = const Color(0xFF4F6BED),
    this.textScale = 1.0,
    this.compact = false,
    this.reduceMotion = false,
  });

  /// 从偏好设置中读取外观参数。
  factory TfAppearance.fromPreferences(TfPreferencesController preferences) => TfAppearance(
    themeMode: preferences.getEnum(TfPreferenceKeys.themeMode),
    seedColor: Color(preferences.get(TfPreferenceKeys.seedColor)),
    textScale: preferences.get(TfPreferenceKeys.textScale),
    compact: preferences.get(TfPreferenceKeys.compact),
    reduceMotion: preferences.get(TfPreferenceKeys.reduceMotion),
  );

  /// 浅色 / 深色 / 跟随系统。
  final ThemeMode themeMode;

  /// 强调色，所有配色都由它生成。
  final Color seedColor;

  /// 字体缩放倍数，会乘在系统字体大小上。
  final double textScale;

  /// 是否使用紧凑布局。
  final bool compact;

  /// 是否减少动态效果。
  final bool reduceMotion;

  /// 对应的控件密度。
  VisualDensity get visualDensity => compact ? VisualDensity.compact : VisualDensity.standard;

  /// 由 [seedColor] 生成的配色方案。
  ColorScheme colorScheme(Brightness brightness) => ColorScheme.fromSeed(seedColor: seedColor, brightness: brightness);

  @override
  bool operator ==(Object other) =>
      other is TfAppearance &&
      other.themeMode == themeMode &&
      other.seedColor == seedColor &&
      other.textScale == textScale &&
      other.compact == compact &&
      other.reduceMotion == reduceMotion;

  @override
  int get hashCode => Object.hash(themeMode, seedColor, textScale, compact, reduceMotion);
}
