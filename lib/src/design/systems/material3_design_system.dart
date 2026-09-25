import 'package:flutter/material.dart' hide showDialog;
import 'package:flutter/material.dart' as material show showDialog;

import '../appearance.dart';
import '../design_system.dart';

/// 使用 Flutter 自带 Material Design 3 控件的组件库。
///
/// 窗口宽度达到 [railBreakpoint] 时，底部导航栏改为侧边导航栏；
/// 达到 [extendedRailBreakpoint] 时，侧边导航栏展开显示文字。
///
/// ```dart
/// TfFramework.initialize(designSystems: const [
///   Material3DesignSystem(railBreakpoint: 600),
///   LiquidGlassDesignSystem(),
/// ]);
/// ```
class Material3DesignSystem extends TfDesignSystem {
  const Material3DesignSystem({this.railBreakpoint = 840, this.extendedRailBreakpoint = 1200});

  /// 本组件库的 id。
  static const systemId = 'material3';

  /// 窗口宽度达到该值时改用侧边导航栏。
  final double railBreakpoint;

  /// 窗口宽度达到该值时侧边导航栏显示文字。
  final double extendedRailBreakpoint;

  @override
  String get id => systemId;

  @override
  String get displayName => 'Material 3';

  @override
  IconData get icon => Icons.android;

  @override
  ThemeData buildTheme(TfAppearance appearance, Brightness brightness) => ThemeData(
    colorScheme: appearance.colorScheme(brightness),
    visualDensity: appearance.visualDensity,
    inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
  );

  @override
  Widget scaffold(
    BuildContext context, {
    required Widget body,
    String? title,
    Widget? leading,
    List<Widget> actions = const [],
    List<TfNavDestination>? destinations,
    int selectedIndex = 0,
    ValueChanged<int>? onDestinationSelected,
  }) {
    final width = MediaQuery.sizeOf(context).width;
    final useRail = destinations != null && width >= railBreakpoint;
    return Scaffold(
      appBar: title == null && actions.isEmpty && leading == null
          ? null
          : AppBar(title: title == null ? null : Text(title), leading: leading, actions: actions),
      body: useRail
          ? Row(
              children: [
                NavigationRail(
                  extended: width >= extendedRailBreakpoint,
                  labelType: width >= extendedRailBreakpoint ? null : NavigationRailLabelType.all,
                  selectedIndex: selectedIndex,
                  onDestinationSelected: onDestinationSelected,
                  destinations: [
                    for (final destination in destinations)
                      NavigationRailDestination(
                        icon: Icon(destination.icon),
                        selectedIcon: Icon(destination.selectedIcon ?? destination.icon),
                        label: Text(destination.label),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: body),
              ],
            )
          : body,
      bottomNavigationBar: destinations == null || useRail
          ? null
          : NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
              destinations: [
                for (final destination in destinations)
                  NavigationDestination(
                    icon: Icon(destination.icon),
                    selectedIcon: Icon(destination.selectedIcon ?? destination.icon),
                    label: destination.label,
                  ),
              ],
            ),
    );
  }

  @override
  Widget button(
    BuildContext context, {
    required String label,
    required VoidCallback? onPressed,
    IconData? icon,
    TfButtonVariant variant = TfButtonVariant.primary,
    bool loading = false,
    bool expanded = false,
  }) {
    final text = Text(label);
    final iconWidget = loading
        ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
        : (icon == null ? null : Icon(icon));
    final effectiveOnPressed = loading ? null : onPressed;
    final button = switch (variant) {
      TfButtonVariant.primary => FilledButton.icon(onPressed: effectiveOnPressed, icon: iconWidget, label: text),
      TfButtonVariant.secondary => OutlinedButton.icon(onPressed: effectiveOnPressed, icon: iconWidget, label: text),
      TfButtonVariant.text => TextButton.icon(onPressed: effectiveOnPressed, icon: iconWidget, label: text),
    };
    return expanded ? SizedBox(width: double.infinity, height: 44, child: button) : button;
  }

  @override
  Widget iconButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback? onPressed,
    String? tooltip,
  }) => IconButton(icon: Icon(icon), onPressed: onPressed, tooltip: tooltip);

  @override
  Widget card(
    BuildContext context, {
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
    VoidCallback? onTap,
  }) => Card.filled(
    margin: EdgeInsets.zero,
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: padding,
        child: TfSurfaceScope(child: child),
      ),
    ),
  );

  @override
  Widget section(BuildContext context, {required List<Widget> children, String? title, String? footer}) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(title, style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary)),
          ),
        Card.outlined(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: TfSurfaceScope(
            child: Column(
              children: [
                for (final (index, child) in children.indexed) ...[
                  if (index > 0) const Divider(height: 1, indent: 16, endIndent: 16),
                  child,
                ],
              ],
            ),
          ),
        ),
        if (footer != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(footer, style: theme.textTheme.bodySmall),
          ),
      ],
    );
  }

  @override
  Widget listTile(
    BuildContext context, {
    required Widget title,
    Widget? subtitle,
    Widget? leading,
    Widget? trailing,
    VoidCallback? onTap,
  }) => ListTile(title: title, subtitle: subtitle, leading: leading, trailing: trailing, onTap: onTap);

  @override
  Widget toggle(BuildContext context, {required bool value, required ValueChanged<bool>? onChanged}) =>
      Switch(value: value, onChanged: onChanged);

  @override
  Widget checkbox(BuildContext context, {required bool value, required ValueChanged<bool>? onChanged}) =>
      Checkbox(value: value, onChanged: onChanged == null ? null : (next) => onChanged(next ?? false));

  @override
  Widget slider(
    BuildContext context, {
    required double value,
    required ValueChanged<double>? onChanged,
    double min = 0,
    double max = 1,
    int? divisions,
  }) => Slider(value: value, onChanged: onChanged, min: min, max: max, divisions: divisions);

  @override
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
  }) => TextField(
    controller: controller,
    focusNode: focusNode,
    obscureText: obscureText,
    enabled: enabled,
    maxLines: obscureText ? 1 : maxLines,
    keyboardType: keyboardType,
    textInputAction: textInputAction,
    autofillHints: autofillHints,
    onChanged: onChanged,
    onSubmitted: onSubmitted,
    decoration: InputDecoration(
      labelText: placeholder,
      errorText: errorText,
      prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
      suffixIcon: suffixIcon == null
          ? null
          : IconButton(icon: Icon(suffixIcon), tooltip: suffixTooltip, onPressed: onSuffixTap),
    ),
  );

  @override
  Widget segmented<T>(
    BuildContext context, {
    required List<TfSegment<T>> segments,
    required T selected,
    required ValueChanged<T>? onChanged,
  }) => SegmentedButton<T>(
    showSelectedIcon: false,
    segments: [
      for (final segment in segments)
        ButtonSegment<T>(
          value: segment.value,
          label: segment.label == null ? null : Text(segment.label!),
          icon: segment.icon == null ? null : Icon(segment.icon),
        ),
    ],
    selected: {selected},
    onSelectionChanged: onChanged == null ? null : (selection) => onChanged(selection.single),
  );

  @override
  Widget chip(
    BuildContext context, {
    required String label,
    IconData? icon,
    bool selected = false,
    VoidCallback? onTap,
  }) => FilterChip(
    label: Text(label),
    avatar: icon == null || selected ? null : Icon(icon),
    selected: selected,
    onSelected: onTap == null ? null : (_) => onTap(),
  );

  @override
  Widget progress(BuildContext context, {double? value, bool circular = false}) => circular
      ? CircularProgressIndicator(value: value)
      : LinearProgressIndicator(value: value, borderRadius: BorderRadius.circular(4));

  @override
  Future<T?> showDialog<T>(
    BuildContext context, {
    required String title,
    required List<TfDialogAction<T>> actions,
    String? message,
    Widget? content,
    bool barrierDismissible = true,
  }) => material.showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (dialogContext) {
      final colors = Theme.of(dialogContext).colorScheme;
      Future<void> choose(TfDialogAction<T> action) async {
        if (await action.shouldClose() && dialogContext.mounted) Navigator.of(dialogContext).pop(action.value);
      }

      return AlertDialog(
        title: Text(title),
        content: message == null && content == null
            ? null
            : TfSurfaceScope(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (message != null) Text(message),
                    if (message != null && content != null) const SizedBox(height: 16),
                    ?content,
                  ],
                ),
              ),
        actions: [
          for (final action in actions)
            action.isPrimary
                ? FilledButton(
                    style: action.isDestructive
                        ? FilledButton.styleFrom(backgroundColor: colors.error, foregroundColor: colors.onError)
                        : null,
                    onPressed: () => choose(action),
                    child: Text(action.label),
                  )
                : TextButton(
                    style: action.isDestructive ? TextButton.styleFrom(foregroundColor: colors.error) : null,
                    onPressed: () => choose(action),
                    child: Text(action.label),
                  ),
        ],
      );
    },
  );

  @override
  Future<T?> showActionSheet<T>(
    BuildContext context, {
    required List<TfSheetAction<T>> actions,
    String? title,
    String? message,
  }) => showModalBottomSheet<T>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 4),
                child: Text(title, style: theme.textTheme.titleMedium),
              ),
            if (message != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Text(message, style: theme.textTheme.bodyMedium),
              ),
            for (final action in actions)
              ListTile(
                leading: action.icon == null ? null : Icon(action.icon),
                title: Text(action.label),
                iconColor: action.isDestructive ? theme.colorScheme.error : null,
                textColor: action.isDestructive ? theme.colorScheme.error : null,
                onTap: () => Navigator.of(sheetContext).pop(action.value),
              ),
          ],
        ),
      );
    },
  );

  @override
  Future<T?> showSheet<T>(BuildContext context, {required WidgetBuilder builder, String? title}) =>
      showModalBottomSheet<T>(
        context: context,
        showDragHandle: true,
        useSafeArea: true,
        isScrollControlled: true,
        builder: (sheetContext) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheetContext).bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (title != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                  child: Text(title, style: Theme.of(sheetContext).textTheme.titleLarge),
                ),
              Flexible(
                child: TfSurfaceScope(child: Builder(builder: builder)),
              ),
            ],
          ),
        ),
      );

  @override
  void showToast(BuildContext context, {required String message, TfToastType type = TfToastType.info}) {
    final colors = Theme.of(context).colorScheme;
    final (background, foreground) = switch (type) {
      TfToastType.error => (colors.errorContainer, colors.onErrorContainer),
      TfToastType.success => (colors.primaryContainer, colors.onPrimaryContainer),
      TfToastType.warning => (colors.tertiaryContainer, colors.onTertiaryContainer),
      TfToastType.info => (colors.inverseSurface, colors.onInverseSurface),
    };
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: background,
          content: Text(message, style: TextStyle(color: foreground)),
        ),
      );
  }
}
