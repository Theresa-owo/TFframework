import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/tf_strings.dart';
import '../preferences/preferences_controller.dart';
import '../settings/setting.dart';
import 'appearance.dart';

/// [TfButton] 的样式。
enum TfButtonVariant {
  /// 主要操作，最醒目。
  primary,

  /// 次要操作。
  secondary,

  /// 文字按钮，最轻量。
  text,
}

/// 提示的类型，决定 `showTfToast`、`TfBanner` 的颜色和图标。
enum TfToastType {
  /// 普通信息。
  info,

  /// 操作成功。
  success,

  /// 需要注意。
  warning,

  /// 出错。
  error,
}

/// [TfSegmentedControl] 的一个选项，[label] 和 [icon] 至少提供一个。
///
/// ```dart
/// const TfSegment(value: ViewMode.grid, icon: Icons.grid_view, label: '网格')
/// ```
@immutable
class TfSegment<T> {
  const TfSegment({required this.value, this.label, this.icon}) : assert(label != null || icon != null);

  /// 选中时回传的值。
  final T value;

  /// 文字。
  final String? label;

  /// 图标。
  final IconData? icon;
}

/// [TfScaffold] 导航栏中的一项。
///
/// ```dart
/// const TfNavDestination(icon: Icons.home_outlined, selectedIcon: Icons.home, label: '首页')
/// ```
@immutable
class TfNavDestination {
  const TfNavDestination({required this.icon, required this.label, this.selectedIcon});

  /// 未选中时的图标。
  final IconData icon;

  /// 选中时的图标；为 null 时使用 [icon]。
  final IconData? selectedIcon;

  /// 文字标签。
  final String label;
}

/// 对话框中的一个按钮，用于 `showTfDialog`。
///
/// ```dart
/// TfDialogAction(
///   label: '提交',
///   value: true,
///   isPrimary: true,
///   beforeClose: () => _formKey.currentState!.validate(), // 校验不通过时不关闭
/// )
/// ```
@immutable
class TfDialogAction<T> {
  const TfDialogAction({
    required this.label,
    this.value,
    this.isPrimary = false,
    this.isDestructive = false,
    this.beforeClose,
  });

  /// 按钮文字。
  final String label;

  /// 点击后对话框返回的值。
  final T? value;

  /// 是否为主要按钮（强调显示）。
  final bool isPrimary;

  /// 是否为危险操作（显示为警示色），例如“删除”。
  final bool isDestructive;

  /// 点击后、关闭前执行；返回 false 时对话框保持打开（例如表单校验不通过）。
  final FutureOr<bool> Function()? beforeClose;

  /// 执行 [beforeClose] 并返回是否应该关闭，由组件库实现调用。
  Future<bool> shouldClose() async => await beforeClose?.call() ?? true;
}

/// 操作表（`showTfActionSheet`）中的一个选项。
@immutable
class TfSheetAction<T> {
  const TfSheetAction({required this.label, required this.value, this.icon, this.isDestructive = false});

  /// 选项文字。
  final String label;

  /// 选中后返回的值。
  final T value;

  /// 图标（可选）。
  final IconData? icon;

  /// 是否为危险操作（显示为警示色）。
  final bool isDestructive;
}

/// 组件库接口：每个组件库（Material 3、液态玻璃……）都实现这个类。
///
/// 应用代码不直接使用任何第三方组件库，而是使用 `Tf*` 组件；每个 `Tf*` 组件
/// 都会调用当前组件库对应的方法来生成真正的控件。因此：
///
/// - 切换组件库时，所有页面自动换成另一套外观；
/// - 接入新的组件库时，只需继承本类、实现每个方法，然后注册到
///   `TfFramework.initialize(designSystems: [...])`，业务代码无需修改。
///
/// 放在卡片、分组、对话框、面板里的控件，其 `context` 中能找到
/// [TfSurfaceScope]，实现可以据此换用更轻量的样式。
///
/// 只想改个别组件时，可以继承已有实现并覆盖对应方法：
///
/// ```dart
/// class MyMaterial extends Material3DesignSystem {
///   const MyMaterial();
///
///   @override
///   String get id => 'my_material';
///
///   @override
///   Widget card(BuildContext context, {required Widget child, EdgeInsetsGeometry padding = const EdgeInsets.all(16), VoidCallback? onTap}) =>
///       Card.outlined(child: Padding(padding: padding, child: TfSurfaceScope(child: child)));
/// }
/// ```
abstract class TfDesignSystem {
  const TfDesignSystem();

  /// 唯一且稳定的 id，会保存在偏好中，发布后不要修改。
  String get id;

  /// 显示给用户的名称，例如“Material 3”。
  String get displayName;

  /// 在切换按钮等处显示的图标。
  IconData get icon;

  /// 该组件库专属的设置分组，只在它处于使用状态时显示在设置页中。
  List<TfSettingsSection> settingsSections(TfStrings strings) => const [];

  /// 一次性的异步初始化（例如预热着色器），由 `TfFramework.initialize` 调用。
  Future<void> initialize() async {}

  /// 根据外观参数生成浅色或深色主题。
  ThemeData buildTheme(TfAppearance appearance, Brightness brightness);

  /// 包裹整个应用（导航器及以下），用于提供组件库需要的全局配置。
  /// 不同组件库返回的控件树可以不同，切换时页面栈会保留。
  Widget wrapApp(BuildContext context, TfAppearance appearance, TfPreferencesController preferences, Widget child) =>
      child;

  /// 实现 [TfScaffold]。
  Widget scaffold(
    BuildContext context, {
    required Widget body,
    String? title,
    Widget? leading,
    List<Widget> actions = const [],
    List<TfNavDestination>? destinations,
    int selectedIndex = 0,
    ValueChanged<int>? onDestinationSelected,
  });

  /// 实现 [TfButton]：[loading] 时显示转圈并禁用，[expanded] 时撑满宽度。
  Widget button(
    BuildContext context, {
    required String label,
    required VoidCallback? onPressed,
    IconData? icon,
    TfButtonVariant variant = TfButtonVariant.primary,
    bool loading = false,
    bool expanded = false,
  });

  /// 实现 [TfIconButton]。
  Widget iconButton(BuildContext context, {required IconData icon, required VoidCallback? onPressed, String? tooltip});

  /// 实现 [TfCard]，内容需包在 [TfSurfaceScope] 中。
  Widget card(
    BuildContext context, {
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
    VoidCallback? onTap,
  });

  /// 实现 [TfSection]，内容需包在 [TfSurfaceScope] 中。
  Widget section(BuildContext context, {required List<Widget> children, String? title, String? footer});

  /// 实现 [TfListTile]。
  Widget listTile(
    BuildContext context, {
    required Widget title,
    Widget? subtitle,
    Widget? leading,
    Widget? trailing,
    VoidCallback? onTap,
  });

  /// 实现 [TfSwitch]。
  Widget toggle(BuildContext context, {required bool value, required ValueChanged<bool>? onChanged});

  /// 实现 [TfCheckbox] 的方框部分。
  Widget checkbox(BuildContext context, {required bool value, required ValueChanged<bool>? onChanged});

  /// 实现 [TfSlider]。
  Widget slider(
    BuildContext context, {
    required double value,
    required ValueChanged<double>? onChanged,
    double min = 0,
    double max = 1,
    int? divisions,
  });

  /// 实现 [TfTextField]：[errorText] 不为 null 时显示为错误状态并在下方显示该文字。
  Widget textField(
    BuildContext context, {
    TextEditingController? controller,
    FocusNode? focusNode,
    String? placeholder,
    IconData? prefixIcon,
    IconData? suffixIcon,
    String? suffixTooltip,
    VoidCallback? onSuffixTap,
    String? errorText,
    bool obscureText = false,
    bool enabled = true,
    int maxLines = 1,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    Iterable<String>? autofillHints,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
  });

  /// 实现 [TfSegmentedControl]。
  Widget segmented<T>(
    BuildContext context, {
    required List<TfSegment<T>> segments,
    required T selected,
    required ValueChanged<T>? onChanged,
  });

  /// 实现 [TfChip]。
  Widget chip(
    BuildContext context, {
    required String label,
    IconData? icon,
    bool selected = false,
    VoidCallback? onTap,
  });

  /// 实现 [TfProgress]：[value] 为 null 时为不确定进度。
  Widget progress(BuildContext context, {double? value, bool circular = false});

  /// 实现 `showTfDialog`：[content] 显示在 [message] 下方，需包在 [TfSurfaceScope] 中；
  /// 点击按钮时先调用 [TfDialogAction.shouldClose]。
  Future<T?> showDialog<T>(
    BuildContext context, {
    required String title,
    required List<TfDialogAction<T>> actions,
    String? message,
    Widget? content,
    bool barrierDismissible = true,
  });

  /// 实现 `showTfActionSheet`：返回所选值，取消时返回 null。
  Future<T?> showActionSheet<T>(
    BuildContext context, {
    required List<TfSheetAction<T>> actions,
    String? title,
    String? message,
  });

  /// 实现 `showTfSheet`：内容需包在 [TfSurfaceScope] 中，pop 时的值作为返回值。
  Future<T?> showSheet<T>(BuildContext context, {required WidgetBuilder builder, String? title});

  /// 实现 `showTfToast`。
  void showToast(BuildContext context, {required String message, TfToastType type = TfToastType.info});
}

/// 向下提供当前组件库和外观参数，[TfApp] 会自动创建。
///
/// ```dart
/// final design = TfDesign.of(context);          // 当前组件库
/// Text('当前使用：${design.displayName}');
///
/// final appearance = TfDesign.appearanceOf(context);
/// if (appearance.reduceMotion) { /* 跳过动画 */ }
/// ```
class TfDesign extends InheritedWidget {
  const TfDesign({super.key, required this.system, required this.appearance, required super.child});

  /// 当前组件库。
  final TfDesignSystem system;

  /// 当前外观参数。
  final TfAppearance appearance;

  static TfDesign _of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<TfDesign>();
    assert(scope != null, 'No TfDesign found. Wrap the app in TfApp.');
    return scope!;
  }

  /// 获取当前组件库；组件库切换时调用处会自动重建。
  static TfDesignSystem of(BuildContext context) => _of(context).system;

  /// 获取当前外观参数。
  static TfAppearance appearanceOf(BuildContext context) => _of(context).appearance;

  @override
  bool updateShouldNotify(TfDesign oldWidget) => system != oldWidget.system || appearance != oldWidget.appearance;
}

/// 标记“这片区域已经在一个表面上”（卡片、分组、对话框、面板）。
///
/// 组件库会据此在表面内使用更轻量的控件，例如液态玻璃在卡片里改用扁平的
/// Cupertino 控件，避免玻璃叠玻璃。框架的卡片、分组、对话框已自动添加它；
/// 自己做了带背景的容器时，也可以把内容包在里面。
///
/// ```dart
/// DecoratedBox(
///   decoration: myPanelDecoration,
///   child: TfSurfaceScope(child: TfSwitch(value: on, onChanged: setOn)),
/// )
/// ```
class TfSurfaceScope extends InheritedWidget {
  const TfSurfaceScope({super.key, required super.child});

  /// [context] 是否位于某个表面之内。
  static bool isInside(BuildContext context) => context.getInheritedWidgetOfExactType<TfSurfaceScope>() != null;

  @override
  bool updateShouldNotify(TfSurfaceScope oldWidget) => false;
}
