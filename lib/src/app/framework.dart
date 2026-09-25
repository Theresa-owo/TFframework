import 'package:flutter/widgets.dart';

import '../design/design_system.dart';
import '../preferences/preference_keys.dart';
import '../preferences/preference_store.dart';
import '../preferences/preferences_controller.dart';
import '../settings/setting.dart';

/// 根据 [BuildContext] 生成应用自己的设置分组，常用于按当前语言生成标题。
typedef TfSettingsBuilder = List<TfSettingsSection> Function(BuildContext context);

/// 框架的总入口：统一管理组件库、偏好设置和设置页内容。
///
/// 在 `runApp` 之前用 [TfFramework.initialize] 创建，然后交给 [TfApp]。
/// 任何页面都可以用 [TfFramework.of] 取到它。
///
/// ```dart
/// Future<void> main() async {
///   final framework = await TfFramework.initialize(
///     designSystems: const [Material3DesignSystem(), LiquidGlassDesignSystem()],
///     settingsBuilder: (context) => [
///       TfSettingsSection(title: '账号', settings: [...]),
///     ],
///   );
///   runApp(TfApp(framework: framework, home: const HomePage()));
/// }
///
/// // 页面中：
/// final framework = TfFramework.of(context);
/// framework.preferences.get(AppKeys.token);
/// framework.switchDesignSystem(LiquidGlassDesignSystem.systemId);
/// ```
class TfFramework {
  TfFramework._({
    required this.preferences,
    required this.designSystems,
    required this.settings,
    required this.settingsBuilder,
  });

  /// 读取已保存的偏好，并初始化所有组件库（例如预热液态玻璃着色器）。
  ///
  /// - [designSystems]：可切换的组件库，第一个为默认值，`id` 不能重复。
  /// - [store]：偏好的存储位置，默认为 [TfSharedPreferenceStore]；
  ///   测试时可传入 [TfMemoryPreferenceStore]。
  /// - [settings] / [settingsBuilder]：应用自己的设置分组，显示在
  ///   [TfSettingsPage] 的内置设置之后。需要多语言标题时用 [settingsBuilder]。
  static Future<TfFramework> initialize({
    required List<TfDesignSystem> designSystems,
    TfPreferenceStore? store,
    List<TfSettingsSection> settings = const [],
    TfSettingsBuilder? settingsBuilder,
  }) async {
    if (designSystems.isEmpty) {
      throw ArgumentError.value(designSystems, 'designSystems', 'At least one design system is required');
    }
    final ids = designSystems.map((system) => system.id).toSet();
    if (ids.length != designSystems.length) {
      throw ArgumentError.value(ids, 'designSystems', 'Design system ids must be unique');
    }
    WidgetsFlutterBinding.ensureInitialized();
    final preferences = TfPreferencesController(store: store);
    await Future.wait([preferences.load(), for (final system in designSystems) system.initialize()]);
    return TfFramework._(
      preferences: preferences,
      designSystems: List.unmodifiable(designSystems),
      settings: List.unmodifiable(settings),
      settingsBuilder: settingsBuilder,
    );
  }

  /// 所有偏好的读写入口。
  final TfPreferencesController preferences;

  /// 注册的组件库，第一个为默认值。
  final List<TfDesignSystem> designSystems;

  /// 应用注册的固定设置分组。
  final List<TfSettingsSection> settings;

  /// 应用注册的动态设置分组。
  final TfSettingsBuilder? settingsBuilder;

  /// 合并 [settings] 和 [settingsBuilder] 的结果。
  List<TfSettingsSection> settingsFor(BuildContext context) => [...settings, ...?settingsBuilder?.call(context)];

  /// 默认组件库（[designSystems] 的第一个）。
  TfDesignSystem get defaultDesignSystem => designSystems.first;

  /// 当前使用的组件库；保存的 id 无效时回退到默认组件库。
  TfDesignSystem get activeDesignSystem {
    final id = preferences.get(TfPreferenceKeys.designSystem);
    return designSystems.firstWhere((system) => system.id == id, orElse: () => defaultDesignSystem);
  }

  /// 切换到指定 [id] 的组件库，界面立即刷新并保存选择；页面栈保持不变。
  ///
  /// [id] 未注册时抛出 `ArgumentError`。
  Future<void> switchDesignSystem(String id) {
    if (!designSystems.any((system) => system.id == id)) {
      throw ArgumentError.value(id, 'id', 'Unknown design system');
    }
    return preferences.set(TfPreferenceKeys.designSystem, id);
  }

  /// 获取 [TfApp] 提供的框架实例。
  static TfFramework of(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<TfFrameworkScope>();
    assert(scope != null, 'No TfFramework found. Wrap the app in TfApp.');
    return scope!.framework;
  }
}

/// 向下提供 [TfFramework] 的内部控件，[TfApp] 会自动创建，一般无需直接使用。
class TfFrameworkScope extends InheritedWidget {
  const TfFrameworkScope({super.key, required this.framework, required super.child});

  /// 提供的框架实例。
  final TfFramework framework;

  @override
  bool updateShouldNotify(TfFrameworkScope oldWidget) => framework != oldWidget.framework;
}
