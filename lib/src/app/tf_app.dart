import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../design/appearance.dart';
import '../design/design_system.dart';
import '../l10n/tf_strings.dart';
import '../preferences/preference_keys.dart';
import 'framework.dart';

/// 应用的根控件，用来代替 `MaterialApp`。
///
/// 它根据偏好设置自动应用组件库、主题模式、强调色、语言、字体大小、紧凑布局和
/// 减少动态效果；这些设置变化时立即刷新，页面栈不受影响。
/// 路由相关参数与 `MaterialApp` 相同。
///
/// ```dart
/// runApp(TfApp(
///   framework: framework,
///   title: '我的应用',
///   home: const HomePage(),
///   routes: {'/settings': (_) => const TfSettingsPage()},
///   strings: {'ja': const MyJapaneseStrings()},
///   supportedLocales: const [Locale('en'), Locale('zh'), Locale('ja')],
/// ));
/// ```
class TfApp extends StatefulWidget {
  const TfApp({
    super.key,
    required this.framework,
    this.title = '',
    this.home,
    this.routes = const {},
    this.initialRoute,
    this.onGenerateRoute,
    this.navigatorKey,
    this.navigatorObservers = const [],
    this.builder,
    this.locale,
    this.strings = const {},
    this.localizationsDelegates = const [],
    this.supportedLocales = const [Locale('en'), Locale('zh')],
    this.debugShowCheckedModeBanner = false,
  });

  /// 由 [TfFramework.initialize] 创建的框架实例。
  final TfFramework framework;

  /// 应用名称，显示在系统任务切换器中。
  final String title;

  /// 首页。
  final Widget? home;

  /// 命名路由表。
  final Map<String, WidgetBuilder> routes;

  /// 初始路由名。
  final String? initialRoute;

  /// 命名路由不在 [routes] 中时用它生成路由。
  final RouteFactory? onGenerateRoute;

  /// 用于在没有 `BuildContext` 的地方导航。
  final GlobalKey<NavigatorState>? navigatorKey;

  /// 路由观察者，例如页面统计。
  final List<NavigatorObserver> navigatorObservers;

  /// 在导航器外再包一层控件，例如全局遮罩。
  final TransitionBuilder? builder;

  /// 语言设置为“跟随系统”时强制使用的语言；为 null 时真正跟随系统。
  final Locale? locale;

  /// 自定义或新增的框架文案，键为语言代码。
  final Map<String, TfStrings> strings;

  /// 应用自己的本地化代理，排在框架自带的代理之后。
  final List<LocalizationsDelegate<dynamic>> localizationsDelegates;

  /// 支持的语言，默认为英文和中文。
  final List<Locale> supportedLocales;

  /// 是否显示右上角的 DEBUG 标记。
  final bool debugShowCheckedModeBanner;

  @override
  State<TfApp> createState() => _TfAppState();
}

class _TfAppState extends State<TfApp> {
  // Design systems wrap the navigator in different widget trees. A global key
  // lets the navigator move between them without losing its routes.
  final _navigatorHostKey = GlobalKey(debugLabel: 'TfApp navigator host');

  @override
  Widget build(BuildContext context) {
    final framework = widget.framework;
    return TfFrameworkScope(
      framework: framework,
      child: ListenableBuilder(
        listenable: framework.preferences,
        builder: (context, _) {
          final design = framework.activeDesignSystem;
          final appearance = TfAppearance.fromPreferences(framework.preferences);
          final languageCode = framework.preferences.get(TfPreferenceKeys.locale);
          return MaterialApp(
            title: widget.title,
            theme: design.buildTheme(appearance, Brightness.light),
            darkTheme: design.buildTheme(appearance, Brightness.dark),
            themeMode: appearance.themeMode,
            themeAnimationDuration: appearance.reduceMotion ? Duration.zero : kThemeAnimationDuration,
            home: widget.home,
            routes: widget.routes,
            initialRoute: widget.initialRoute,
            onGenerateRoute: widget.onGenerateRoute,
            navigatorKey: widget.navigatorKey,
            navigatorObservers: widget.navigatorObservers,
            locale: languageCode.isEmpty ? widget.locale : Locale(languageCode),
            localizationsDelegates: [
              TfStringsDelegate(overrides: widget.strings),
              GlobalMaterialLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              ...widget.localizationsDelegates,
            ],
            supportedLocales: widget.supportedLocales,
            debugShowCheckedModeBanner: widget.debugShowCheckedModeBanner,
            builder: (context, navigator) {
              final media = MediaQuery.of(context);
              Widget child = KeyedSubtree(key: _navigatorHostKey, child: navigator ?? const SizedBox.shrink());
              child = widget.builder?.call(context, child) ?? child;
              child = design.wrapApp(context, appearance, framework.preferences, child);
              return MediaQuery(
                data: media.copyWith(
                  textScaler: TextScaler.linear(media.textScaler.scale(1) * appearance.textScale),
                  disableAnimations: media.disableAnimations || appearance.reduceMotion,
                ),
                child: TfDesign(system: design, appearance: appearance, child: child),
              );
            },
          );
        },
      ),
    );
  }
}
