import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide showDialog;
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../l10n/tf_strings.dart';
import '../../preferences/preference_key.dart';
import '../../preferences/preferences_controller.dart';
import '../../settings/setting.dart';
import '../appearance.dart';
import '../design_system.dart';

/// 生成液态玻璃页面背景（被玻璃折射的“壁纸”）的函数。
typedef TfGlassBackgroundBuilder = Widget Function(BuildContext context, TfAppearance appearance);

/// iOS 26 风格的液态玻璃组件库，基于 `liquid_glass_widgets` 包。
///
/// 顶栏、导航栏和独立的控件使用玻璃效果；放在玻璃表面（卡片、分组、对话框、
/// 面板）里的控件改用扁平的 Cupertino 控件，因为玻璃叠玻璃会产生重影和裁切。
///
/// 玻璃需要有内容可以折射，所以每个页面都有背景：默认为由强调色生成的渐变，
/// 可以用 [backgroundBuilder] 换成图片等。
///
/// 启用后设置页会多出“模糊程度”“渲染质量”“自适应质量”三项。
///
/// ```dart
/// LiquidGlassDesignSystem(
///   backgroundBuilder: (context, appearance) =>
///       Image.asset('assets/wallpaper.jpg', fit: BoxFit.cover),
/// )
/// ```
class LiquidGlassDesignSystem extends TfDesignSystem {
  const LiquidGlassDesignSystem({this.backgroundBuilder, this.warmUpShaders = true});

  /// 本组件库的 id。
  static const systemId = 'liquid_glass';

  /// 玻璃模糊程度偏好，范围 0～40。
  static const blur = TfPreferenceKey<double>('glass.blur', defaultValue: 12, validator: _isValidBlur);

  /// 玻璃渲染质量偏好：最低 / 标准 / 高级。
  static final quality = TfEnumPreference<GlassQuality>(
    'glass.quality',
    values: GlassQuality.values,
    defaultValue: GlassQuality.standard,
  );

  /// 是否在掉帧时自动降低渲染质量。
  static const adaptiveQuality = TfPreferenceKey<bool>('glass.adaptiveQuality', defaultValue: false);

  static bool _isValidBlur(double value) => value >= 0 && value <= 40;

  /// 页面背景；为 null 时使用由强调色生成的渐变。
  final TfGlassBackgroundBuilder? backgroundBuilder;

  /// 是否在 `TfFramework.initialize` 时预热着色器，避免首帧卡顿。
  /// 在 widget 测试中请设为 false，因为测试环境加载不到依赖包的着色器。
  final bool warmUpShaders;

  static const _surfaceShape = LiquidRoundedSuperellipse(borderRadius: 20);

  @override
  String get id => systemId;

  @override
  String get displayName => 'Liquid Glass';

  @override
  IconData get icon => Icons.water_drop_outlined;

  @override
  List<TfSettingsSection> settingsSections(TfStrings strings) => [
    TfSettingsSection(
      title: displayName,
      footer: strings.glassFooter,
      settings: [
        TfSliderSetting(
          key: blur,
          title: strings.glassBlur,
          icon: Icons.blur_on,
          min: 0,
          max: 40,
          divisions: 40,
          format: (value) => value.toStringAsFixed(0),
        ),
        TfChoiceSetting.enumeration(
          quality,
          title: strings.glassQuality,
          icon: Icons.high_quality_outlined,
          labels: {
            GlassQuality.minimal: strings.glassQualityMinimal,
            GlassQuality.standard: strings.glassQualityStandard,
            GlassQuality.premium: strings.glassQualityPremium,
          },
        ),
        TfToggleSetting(
          key: adaptiveQuality,
          title: strings.glassAdaptiveQuality,
          subtitle: strings.glassAdaptiveQualitySubtitle,
          icon: Icons.speed,
        ),
      ],
    ),
  ];

  @override
  Future<void> initialize() async {
    if (warmUpShaders) await LiquidGlassWidgets.initialize(enablePerformanceMonitor: false);
  }

  @override
  ThemeData buildTheme(TfAppearance appearance, Brightness brightness) {
    final colors = appearance.colorScheme(brightness);
    return ThemeData(
      colorScheme: colors,
      visualDensity: appearance.visualDensity,
      scaffoldBackgroundColor: colors.surface,
      cupertinoOverrideTheme: CupertinoThemeData(primaryColor: colors.primary, brightness: brightness),
    );
  }

  @override
  Widget wrapApp(BuildContext context, TfAppearance appearance, TfPreferencesController preferences, Widget child) =>
      LiquidGlassWidgets.wrap(
        brightnessResolver: Theme.maybeBrightnessOf,
        adaptiveQuality: preferences.get(adaptiveQuality),
        theme: GlassThemeData.simple(blur: preferences.get(blur), quality: preferences.getEnum(quality)),
        // Glass widgets are Material-free; text under MaterialApp needs a
        // Material ancestor to get a proper DefaultTextStyle.
        child: Material(type: MaterialType.transparency, child: child),
      );

  Widget _defaultBackground(BuildContext context, TfAppearance appearance) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.primaryContainer, colors.surface, colors.tertiaryContainer],
        ),
      ),
    );
  }

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
    final appearance = TfDesign.appearanceOf(context);
    final canPop = ModalRoute.of(context)?.impliesAppBarDismissal ?? false;
    final effectiveLeading =
        leading ??
        (canPop
            ? GlassIconButton(
                icon: const Icon(CupertinoIcons.back),
                onPressed: () => Navigator.of(context).maybePop(),
                semanticLabel: MaterialLocalizations.of(context).backButtonTooltip,
              )
            : null);
    final hasAppBar = title != null || actions.isNotEmpty || effectiveLeading != null;
    final appBar = hasAppBar
        ? GlassAppBar(
            title: title == null ? null : Text(title, style: Theme.of(context).textTheme.titleMedium),
            leading: effectiveLeading,
            actions: actions,
          )
        : null;
    final bottomBar = destinations == null
        ? null
        : GlassTabBar.bottom(
            selectedIndex: selectedIndex,
            onTabSelected: onDestinationSelected ?? (_) {},
            tabs: [
              for (final destination in destinations)
                GlassTab(
                  icon: Icon(destination.icon),
                  activeIcon: Icon(destination.selectedIcon ?? destination.icon),
                  label: destination.label,
                ),
            ],
          );

    // The body extends behind the translucent bars. Expose the bars as
    // MediaQuery padding so scrollables and TfListView inset their content.
    final media = MediaQuery.of(context);
    final paddedBody = MediaQuery(
      data: media.copyWith(
        padding: media.padding.copyWith(
          top: media.padding.top + (appBar?.preferredSize.height ?? 0),
          bottom: media.padding.bottom + (bottomBar?.preferredSize.height ?? 0),
        ),
      ),
      child: body,
    );

    return GlassScaffold(
      background: (backgroundBuilder ?? _defaultBackground)(context, appearance),
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: appBar,
      bottomBar: bottomBar,
      body: paddedBody,
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
    final colors = Theme.of(context).colorScheme;
    final foreground = variant == TfButtonVariant.text ? colors.primary : colors.onSurface;
    final effectiveOnPressed = loading ? null : onPressed;
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (loading)
          const Padding(padding: EdgeInsets.only(right: 8), child: CupertinoActivityIndicator(radius: 8))
        else if (icon != null) ...[
          Icon(icon, size: 18, color: foreground),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: foreground, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
    if (TfSurfaceScope.isInside(context)) {
      final button = variant == TfButtonVariant.primary
          ? CupertinoButton.tinted(onPressed: effectiveOnPressed, child: content)
          : CupertinoButton(onPressed: effectiveOnPressed, child: content);
      return expanded ? SizedBox(width: double.infinity, child: button) : button;
    }
    Widget glassButton(double? width) => GlassButton.custom(
      onTap: effectiveOnPressed ?? () {},
      enabled: effectiveOnPressed != null,
      label: label,
      width: width,
      height: 44,
      shape: const LiquidRoundedSuperellipse(borderRadius: 22),
      style: switch (variant) {
        TfButtonVariant.primary => GlassButtonStyle.prominent,
        TfButtonVariant.secondary => GlassButtonStyle.filled,
        TfButtonVariant.text => GlassButtonStyle.transparent,
      },
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: content),
    );
    if (!expanded) return glassButton(null);
    return LayoutBuilder(
      builder: (context, constraints) => glassButton(constraints.maxWidth.isFinite ? constraints.maxWidth : null),
    );
  }

  @override
  Widget iconButton(BuildContext context, {required IconData icon, required VoidCallback? onPressed, String? tooltip}) {
    if (TfSurfaceScope.isInside(context)) {
      return CupertinoButton(onPressed: onPressed, padding: EdgeInsets.zero, child: Icon(icon));
    }
    return GlassIconButton(icon: Icon(icon), onPressed: onPressed, semanticLabel: tooltip);
  }

  @override
  Widget card(
    BuildContext context, {
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
    VoidCallback? onTap,
  }) {
    // Own layer: cards also appear in dialogs and sheets, outside the
    // scaffold's shared glass layer.
    final card = GlassCard(
      padding: padding,
      shape: _surfaceShape,
      useOwnLayer: true,
      child: TfSurfaceScope(child: child),
    );
    return onTap == null ? card : GestureDetector(onTap: onTap, behavior: HitTestBehavior.opaque, child: card);
  }

  @override
  Widget section(BuildContext context, {required List<Widget> children, String? title, String? footer}) {
    final theme = Theme.of(context);
    final captionStyle = theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    return TfSurfaceScope(
      child: GlassGroupedSection(
        margin: EdgeInsets.zero,
        shape: _surfaceShape,
        useOwnLayer: true,
        header: title == null ? null : Text(title.toUpperCase(), style: captionStyle),
        footer: footer == null ? null : Text(footer, style: captionStyle),
        children: children,
      ),
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
  }) {
    if (TfSurfaceScope.isInside(context)) {
      return GlassListTile(title: title, subtitle: subtitle, leading: leading, trailing: trailing, onTap: onTap);
    }
    return GlassListTile.standalone(
      title: title,
      subtitle: subtitle,
      leading: leading,
      trailing: trailing,
      onTap: onTap,
    );
  }

  @override
  Widget toggle(BuildContext context, {required bool value, required ValueChanged<bool>? onChanged}) {
    final accent = Theme.of(context).colorScheme.primary;
    if (TfSurfaceScope.isInside(context) || onChanged == null) {
      return CupertinoSwitch(value: value, onChanged: onChanged, activeTrackColor: accent);
    }
    return GlassSwitch(value: value, onChanged: onChanged, activeColor: accent, useOwnLayer: true);
  }

  @override
  Widget checkbox(BuildContext context, {required bool value, required ValueChanged<bool>? onChanged}) =>
      CupertinoCheckbox(
        value: value,
        activeColor: Theme.of(context).colorScheme.primary,
        onChanged: onChanged == null ? null : (next) => onChanged(next ?? false),
      );

  @override
  Widget slider(
    BuildContext context, {
    required double value,
    required ValueChanged<double>? onChanged,
    double min = 0,
    double max = 1,
    int? divisions,
  }) {
    final accent = Theme.of(context).colorScheme.primary;
    if (TfSurfaceScope.isInside(context)) {
      return CupertinoSlider(
        value: value,
        onChanged: onChanged,
        min: min,
        max: max,
        divisions: divisions,
        activeColor: accent,
      );
    }
    return GlassSlider(
      value: value,
      onChanged: onChanged,
      min: min,
      max: max,
      divisions: divisions,
      activeColor: accent,
      useOwnLayer: true,
    );
  }

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
  }) {
    final colors = Theme.of(context).colorScheme;
    final Widget field;
    if (TfSurfaceScope.isInside(context)) {
      field = CupertinoTextField(
        controller: controller,
        focusNode: focusNode,
        placeholder: placeholder,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        prefix: prefixIcon == null
            ? null
            : Padding(
                padding: const EdgeInsets.only(left: 10),
                child: Icon(prefixIcon, size: 20, color: colors.onSurfaceVariant),
              ),
        suffix: suffixIcon == null
            ? null
            : CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                minimumSize: Size.zero,
                onPressed: onSuffixTap,
                child: Semantics(
                  label: suffixTooltip,
                  child: Icon(suffixIcon, size: 20, color: colors.onSurfaceVariant),
                ),
              ),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
          border: errorText == null ? null : Border.all(color: colors.error),
        ),
        style: TextStyle(color: colors.onSurface),
        obscureText: obscureText,
        enabled: enabled,
        maxLines: obscureText ? 1 : maxLines,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        autofillHints: autofillHints,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
      );
    } else {
      field = GlassTextField(
        controller: controller,
        focusNode: focusNode,
        placeholder: placeholder,
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, size: 20),
        suffixIcon: suffixIcon == null ? null : Icon(suffixIcon, size: 20),
        onSuffixTap: onSuffixTap,
        obscureText: obscureText,
        enabled: enabled,
        maxLines: obscureText ? 1 : maxLines,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        useOwnLayer: true,
      );
    }
    if (errorText == null) return field;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        field,
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
          child: Text(errorText, style: TextStyle(color: colors.error, fontSize: 12)),
        ),
      ],
    );
  }

  @override
  Widget segmented<T>(
    BuildContext context, {
    required List<TfSegment<T>> segments,
    required T selected,
    required ValueChanged<T>? onChanged,
  }) {
    final selectedIndex = segments.indexWhere((segment) => segment.value == selected);
    if (TfSurfaceScope.isInside(context) || segments.length < 2) {
      return CupertinoSlidingSegmentedControl<int>(
        groupValue: selectedIndex < 0 ? null : selectedIndex,
        onValueChanged: (index) {
          if (index != null) onChanged?.call(segments[index].value);
        },
        children: {
          for (final (index, segment) in segments.indexed)
            index: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: segment.label != null ? Text(segment.label!) : Icon(segment.icon),
            ),
        },
      );
    }
    return GlassSegmentedControl(
      selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
      onSegmentSelected: (index) => onChanged?.call(segments[index].value),
      useOwnLayer: true,
      segments: [
        for (final segment in segments)
          GlassSegment(label: segment.label, icon: segment.icon == null ? null : Icon(segment.icon)),
      ],
    );
  }

  @override
  Widget chip(
    BuildContext context, {
    required String label,
    IconData? icon,
    bool selected = false,
    VoidCallback? onTap,
  }) {
    if (TfSurfaceScope.isInside(context)) {
      final colors = Theme.of(context).colorScheme;
      return CupertinoButton(
        onPressed: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: Size.zero,
        color: selected ? colors.primary : colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        child: Text(label, style: TextStyle(color: selected ? colors.onPrimary : colors.onSurface, fontSize: 13)),
      );
    }
    return GlassChip(
      label: label,
      icon: icon == null ? null : Icon(icon),
      selected: selected,
      selectedColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.35),
      onTap: onTap,
      useOwnLayer: true,
    );
  }

  @override
  Widget progress(BuildContext context, {double? value, bool circular = false}) {
    if (TfSurfaceScope.isInside(context)) {
      return circular
          ? (value == null ? const CupertinoActivityIndicator(radius: 14) : CircularProgressIndicator(value: value))
          : LinearProgressIndicator(value: value, borderRadius: BorderRadius.circular(4));
    }
    final accent = Theme.of(context).colorScheme.primary;
    return circular
        ? GlassProgressIndicator.circular(value: value, size: 28, color: accent, useOwnLayer: true)
        : GlassProgressIndicator.linear(value: value, height: 6, minWidth: 0, color: accent, useOwnLayer: true);
  }

  @override
  Future<T?> showDialog<T>(
    BuildContext context, {
    required String title,
    required List<TfDialogAction<T>> actions,
    String? message,
    Widget? content,
    bool barrierDismissible = true,
  }) {
    final navigator = Navigator.of(context, rootNavigator: true);
    return GlassDialog.show<T>(
      context: context,
      title: title,
      message: message,
      content: content == null ? null : TfSurfaceScope(child: content),
      barrierDismissible: barrierDismissible,
      maxWidth: 320,
      actions: [
        for (final action in actions)
          GlassDialogAction(
            label: action.label,
            isPrimary: action.isPrimary,
            isDestructive: action.isDestructive,
            onPressed: () async {
              if (await action.shouldClose()) navigator.pop(action.value);
            },
          ),
      ],
    );
  }

  @override
  Future<T?> showActionSheet<T>(
    BuildContext context, {
    required List<TfSheetAction<T>> actions,
    String? title,
    String? message,
  }) async {
    // The glass sheet closes itself without a result; remember the choice.
    T? chosen;
    await showGlassActionSheet<void>(
      context: context,
      title: title,
      message: message,
      cancelLabel: TfStrings.of(context).cancel,
      actions: [
        for (final action in actions)
          GlassActionSheetAction(
            label: action.label,
            icon: action.icon == null ? null : Icon(action.icon),
            style: action.isDestructive ? GlassActionSheetStyle.destructive : GlassActionSheetStyle.defaultStyle,
            onPressed: () => chosen = action.value,
          ),
      ],
    );
    return chosen;
  }

  @override
  Future<T?> showSheet<T>(BuildContext context, {required WidgetBuilder builder, String? title}) =>
      GlassModalSheet.show<T>(
        context: context,
        halfSize: 0.6,
        builder: (sheetContext) => TfSurfaceScope(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (title != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                  child: Text(title, style: Theme.of(sheetContext).textTheme.titleLarge),
                ),
              Expanded(child: Builder(builder: builder)),
            ],
          ),
        ),
      );

  @override
  void showToast(BuildContext context, {required String message, TfToastType type = TfToastType.info}) {
    GlassToast.show(
      context,
      message: message,
      type: switch (type) {
        TfToastType.info => GlassToastType.info,
        TfToastType.success => GlassToastType.success,
        TfToastType.warning => GlassToastType.warning,
        TfToastType.error => GlassToastType.error,
      },
    );
  }
}
