import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'preference_key.dart';

/// 偏好的存储后端：每次保存完整的偏好快照。
///
/// 默认使用 [TfSharedPreferenceStore]。如需存到数据库、加密存储或服务器，
/// 实现本接口并传给 `TfFramework.initialize(store: ...)`：
///
/// ```dart
/// class SecureStore implements TfPreferenceStore {
///   @override
///   Future<Map<String, Object>> load() async =>
///       sanitizePreferenceValues(jsonDecode(await secure.read('prefs') ?? '{}'));
///
///   @override
///   Future<void> save(Map<String, Object> values) => secure.write('prefs', jsonEncode(values));
/// }
/// ```
abstract interface class TfPreferenceStore {
  /// 读取全部已保存的值；没有数据时返回空 Map。
  Future<Map<String, Object>> load();

  /// 保存全部值，覆盖之前的内容。
  Future<void> save(Map<String, Object> values);
}

/// 只存在内存中的存储，应用退出后丢失，适合单元测试和预览。
///
/// ```dart
/// final framework = await TfFramework.initialize(
///   designSystems: const [Material3DesignSystem()],
///   store: TfMemoryPreferenceStore({'tf.themeMode': 'dark'}),
/// );
/// ```
class TfMemoryPreferenceStore implements TfPreferenceStore {
  TfMemoryPreferenceStore([Map<String, Object>? initialValues])
    : _values = sanitizePreferenceValues(initialValues ?? const {});

  Map<String, Object> _values;

  @override
  Future<Map<String, Object>> load() async => Map.of(_values);

  @override
  Future<void> save(Map<String, Object> values) async {
    _values = sanitizePreferenceValues(values);
  }
}

/// 默认存储：把所有偏好编码为一个 JSON，保存在 shared_preferences 的
/// [storageKey] 条目下，不会影响应用自己存在 shared_preferences 里的其他数据。
///
/// 在 Windows 上保存在用户的 AppData 目录中，Android 上保存在 SharedPreferences
/// 中，iOS / macOS 上保存在 NSUserDefaults 中。数据损坏时视为空。
class TfSharedPreferenceStore implements TfPreferenceStore {
  TfSharedPreferenceStore({this.storageKey = 'tf_framework.preferences'});

  /// shared_preferences 中使用的键名。
  final String storageKey;

  @override
  Future<Map<String, Object>> load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.get(storageKey);
    if (raw is! String) return {};
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return {};
    return sanitizePreferenceValues(decoded);
  }

  @override
  Future<void> save(Map<String, Object> values) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(storageKey, jsonEncode(values));
    if (!saved) throw StateError('Failed to persist preferences to $storageKey.');
  }
}

/// 清理偏好数据：丢弃不支持的类型，并把 JSON 解码出的字符串列表转成 `List<String>`。
///
/// 自定义 [TfPreferenceStore] 在 `load` 时应调用它。
Map<String, Object> sanitizePreferenceValues(Map<String, Object?> values) {
  final result = <String, Object>{};
  for (final MapEntry(:key, :value) in values.entries) {
    final Object? normalized = value is List && value.every((e) => e is String)
        ? List<String>.unmodifiable(value.cast<String>())
        : value;
    if (key.isNotEmpty && TfPreferenceKey.isSupportedValue(normalized)) {
      result[key] = normalized!;
    }
  }
  return result;
}
