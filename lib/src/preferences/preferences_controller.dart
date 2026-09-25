import 'package:flutter/foundation.dart';

import 'preference_key.dart';
import 'preference_store.dart';

/// 所有偏好（框架和应用的）的唯一读写入口，通过 `TfFramework.of(context).preferences` 获取。
///
/// - 读取是同步的；没有保存过或保存的值无效时返回默认值。
/// - 写入后立即通知监听者（界面刷新），并在后台保存；连续快速写入
///   （例如拖动滑块）会合并成尽量少的存储操作。
/// - 它是一个 `ChangeNotifier`，可用 `ListenableBuilder` 监听变化。
///
/// ```dart
/// final prefs = TfFramework.of(context).preferences;
///
/// prefs.get(AppKeys.fontSize);                 // 读
/// await prefs.set(AppKeys.fontSize, 16);       // 写
/// await prefs.reset(AppKeys.fontSize);         // 恢复默认
///
/// ListenableBuilder(                           // 值变化时自动重建
///   listenable: prefs,
///   builder: (context, _) => Text('字号 ${prefs.get(AppKeys.fontSize)}'),
/// )
///
/// final backup = prefs.export();               // 备份
/// await prefs.import(backup);                  // 恢复
/// ```
class TfPreferencesController extends ChangeNotifier {
  TfPreferencesController({TfPreferenceStore? store}) : store = store ?? TfSharedPreferenceStore();

  /// 存储后端。
  final TfPreferenceStore store;
  final Map<String, Object> _values = {};

  bool _loaded = false;
  bool _dirty = false;
  Future<void>? _saving;

  /// [load] 是否已完成。
  bool get isLoaded => _loaded;

  /// 从 [store] 读取已保存的值。`TfFramework.initialize` 会自动调用。
  Future<void> load() async {
    try {
      final stored = await store.load();
      _values
        ..clear()
        ..addAll(stored);
    } catch (error, stack) {
      _report(error, stack, 'loading preferences');
    }
    _loaded = true;
    notifyListeners();
  }

  /// 读取 [key] 的值；未保存或值无效时返回默认值。
  T get<T extends Object>(TfPreferenceKey<T> key) {
    final value = _values[key.name];
    return key.accepts(value) ? value as T : key.defaultValue;
  }

  /// 读取枚举偏好。
  E getEnum<E extends Enum>(TfEnumPreference<E> preference) => preference.decode(get(preference.key));

  /// 保存 [key] 的值，并通知监听者。
  ///
  /// 值未通过 [TfPreferenceKey.validator] 时抛出 `ArgumentError`。
  /// 返回的 Future 在写入存储后完成；不需要确认保存结果时可以不 await。
  Future<void> set<T extends Object>(TfPreferenceKey<T> key, T value) {
    if (!key.accepts(value)) {
      throw ArgumentError.value(value, key.name, 'Rejected by $key');
    }
    if (_equals(_values[key.name], value)) return flush();
    _values[key.name] = value is List<String> ? List<String>.unmodifiable(value) : value;
    notifyListeners();
    return _persist();
  }

  /// 保存枚举偏好。
  Future<void> setEnum<E extends Enum>(TfEnumPreference<E> preference, E value) => set(preference.key, value.name);

  /// [key] 是否保存过有效的值（即不是默认值）。
  bool isCustomized(TfPreferenceKey<Object> key) => key.accepts(_values[key.name]);

  /// 把 [key] 恢复为默认值。
  Future<void> reset(TfPreferenceKey<Object> key) {
    if (_values.remove(key.name) == null) return flush();
    notifyListeners();
    return _persist();
  }

  /// 把所有偏好恢复为默认值。
  Future<void> resetAll() {
    if (_values.isEmpty) return flush();
    _values.clear();
    notifyListeners();
    return _persist();
  }

  /// 导出所有已保存的值，可用于备份或多设备同步。
  Map<String, Object> export() => Map.unmodifiable(_values);

  /// 用 [values] 替换所有值；不支持的类型会被丢弃。
  Future<void> import(Map<String, Object?> values) {
    _values
      ..clear()
      ..addAll(sanitizePreferenceValues(values));
    notifyListeners();
    return _persist();
  }

  /// 等待所有尚未完成的写入保存到存储中，例如在退出应用前调用。
  Future<void> flush() => _saving ?? Future.value();

  Future<void> _persist() {
    _dirty = true;
    return _saving ??= _drain();
  }

  Future<void> _drain() async {
    try {
      while (_dirty) {
        _dirty = false;
        await store.save(Map.of(_values));
      }
    } catch (error, stack) {
      _report(error, stack, 'saving preferences');
    } finally {
      _saving = null;
    }
  }

  static bool _equals(Object? a, Object? b) => a is List<String> && b is List<String> ? listEquals(a, b) : a == b;

  static void _report(Object error, StackTrace stack, String context) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'tf_framework',
        context: ErrorDescription('while $context'),
      ),
    );
  }
}
