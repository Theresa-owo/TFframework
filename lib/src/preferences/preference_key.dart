import 'package:flutter/foundation.dart';

/// 偏好值的校验函数，返回 false 表示该值不允许保存。
typedef TfPreferenceValidator<T> = bool Function(T value);

/// 一个偏好项的定义：名字 + 类型 + 默认值 + 可选校验。
///
/// 支持的类型：`bool`、`int`、`double`（有限值）、`String`、`List<String>`。
/// 枚举请用 [TfEnumPreference]；其他复杂类型请自行转成字符串（例如 JSON）。
///
/// 建议把应用的所有偏好集中定义在一个类里，并加上前缀避免与框架冲突
/// （框架自己的键以 `tf.` 开头）：
///
/// ```dart
/// abstract final class AppKeys {
///   static const token = TfPreferenceKey<String>('app.token', defaultValue: '');
///   static const fontSize = TfPreferenceKey<double>(
///     'app.fontSize',
///     defaultValue: 14,
///     validator: _validFontSize,
///   );
///   static bool _validFontSize(double v) => v >= 10 && v <= 30;
/// }
/// ```
@immutable
class TfPreferenceKey<T extends Object> {
  const TfPreferenceKey(this.name, {required this.defaultValue, this.validator});

  /// 存储时使用的键名，在整个应用中必须唯一。
  final String name;

  /// 没有保存过值、或保存的值无效时返回的默认值。
  final T defaultValue;

  /// 校验函数（可选）。
  final TfPreferenceValidator<T>? validator;

  /// [value] 的类型正确且通过校验时返回 true。
  bool accepts(Object? value) {
    if (value is! T || !isSupportedValue(value)) return false;
    return validator?.call(value) ?? true;
  }

  /// [value] 是否属于支持存储的类型。
  static bool isSupportedValue(Object? value) =>
      value is bool || value is int || value is String || value is List<String> || (value is double && value.isFinite);

  @override
  String toString() => 'TfPreferenceKey<$T>($name)';
}

/// 枚举类型的偏好：以枚举值的名字（[Enum.name]）存为字符串。
///
/// 枚举值被重命名或删除后，读到的旧值会回退为 [defaultValue]。
///
/// ```dart
/// enum Sort { newest, popular }
///
/// final sortPref = TfEnumPreference<Sort>('app.sort', values: Sort.values, defaultValue: Sort.newest);
///
/// preferences.getEnum(sortPref);               // Sort.newest
/// await preferences.setEnum(sortPref, Sort.popular);
/// ```
class TfEnumPreference<E extends Enum> {
  TfEnumPreference(String name, {required this.values, required this.defaultValue})
    : key = TfPreferenceKey<String>(
        name,
        defaultValue: defaultValue.name,
        validator: (raw) => values.any((value) => value.name == raw),
      );

  /// 所有枚举值，通常传 `MyEnum.values`。
  final List<E> values;

  /// 默认值。
  final E defaultValue;

  /// 底层的字符串偏好。
  final TfPreferenceKey<String> key;

  /// 把保存的字符串转回枚举值，无法识别时返回 [defaultValue]。
  E decode(String raw) => values.asNameMap()[raw] ?? defaultValue;
}
