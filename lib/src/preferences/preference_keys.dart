import 'package:flutter/material.dart';

import 'preference_key.dart';

/// 框架内置的偏好项，都以 `tf.` 开头。
///
/// 通常通过设置页修改；也可以在代码里直接读写：
///
/// ```dart
/// final prefs = TfFramework.of(context).preferences;
/// await prefs.setEnum(TfPreferenceKeys.themeMode, ThemeMode.dark);
/// await prefs.set(TfPreferenceKeys.locale, 'zh');
/// ```
abstract final class TfPreferenceKeys {
  /// 当前组件库的 id；无效时使用默认组件库。建议用 `TfFramework.switchDesignSystem` 修改。
  static const designSystem = TfPreferenceKey<String>('tf.designSystem', defaultValue: '');

  /// 主题模式：浅色 / 深色 / 跟随系统。
  static final themeMode = TfEnumPreference<ThemeMode>(
    'tf.themeMode',
    values: ThemeMode.values,
    defaultValue: ThemeMode.system,
  );

  /// 强调色（ARGB 整数），所有配色由它生成。
  static const seedColor = TfPreferenceKey<int>('tf.seedColor', defaultValue: 0xFF4F6BED);

  /// 字体缩放倍数，范围 0.8～1.6。
  static const textScale = TfPreferenceKey<double>('tf.textScale', defaultValue: 1.0, validator: _isValidTextScale);

  /// 界面语言代码，例如 `en`、`zh`；为空时跟随系统。
  static const locale = TfPreferenceKey<String>('tf.locale', defaultValue: '');

  /// 是否使用紧凑布局。
  static const compact = TfPreferenceKey<bool>('tf.compact', defaultValue: false);

  /// 是否减少动态效果。
  static const reduceMotion = TfPreferenceKey<bool>('tf.reduceMotion', defaultValue: false);

  static bool _isValidTextScale(double value) => value >= 0.8 && value <= 1.6;
}
