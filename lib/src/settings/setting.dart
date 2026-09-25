import 'package:flutter/material.dart';

import '../app/framework.dart';
import '../components/components.dart';
import '../design/design_system.dart';
import '../kits/overlays.dart';
import '../l10n/tf_strings.dart';
import '../preferences/preference_key.dart';
import '../preferences/preference_keys.dart';
import '../preferences/preferences_controller.dart';

/// 设置页中的一个分组：标题 + 若干设置项 + 可选的底部说明。
///
/// ```dart
/// const TfSettingsSection(
///   title: '通知',
///   footer: '关闭后将不再收到推送。',
///   settings: [
///     TfToggleSetting(key: AppKeys.push, title: '推送通知'),
///     TfToggleSetting(key: AppKeys.sound, title: '提示音'),
///   ],
/// )
/// ```
@immutable
class TfSettingsSection {
  const TfSettingsSection({required this.title, required this.settings, this.footer});

  /// 分组标题。
  final String title;

  /// 分组下方的说明文字（可选）。
  final String? footer;

  /// 分组中的设置项，按顺序显示。
  final List<TfSetting> settings;
}

/// 所有设置项的基类。
///
/// 框架内置了开关、单选、滑块、颜色、文本、跳转、信息、操作、语言等设置项。
/// 需要新类型时继承本类并实现 [build]：读值用 `preferences.get`，
/// 写值用 `preferences.set`，界面会自动刷新。
///
/// ```dart
/// class TfStepperSetting extends TfSetting {
///   const TfStepperSetting({required this.key, required super.title});
///
///   final TfPreferenceKey<int> key;
///
///   @override
///   Widget build(BuildContext context, TfPreferencesController preferences) {
///     final value = preferences.get(key);
///     return TfListTile(
///       title: Text(title),
///       trailing: Row(mainAxisSize: MainAxisSize.min, children: [
///         TfIconButton(icon: Icons.remove, onPressed: () => preferences.set(key, value - 1)),
///         Text('$value'),
///         TfIconButton(icon: Icons.add, onPressed: () => preferences.set(key, value + 1)),
///       ]),
///     );
///   }
/// }
/// ```
abstract class TfSetting {
  const TfSetting({required this.title, this.subtitle, this.icon});

  /// 标题。
  final String title;

  /// 副标题（可选）。
  final String? subtitle;

  /// 左侧图标（可选）。
  final IconData? icon;

  /// 构建这一行的界面，会被放在 [TfSection] 中。
  Widget build(BuildContext context, TfPreferencesController preferences);

  /// 由 [icon] 生成的左侧图标。
  Widget? get leading => icon == null ? null : Icon(icon);

  /// 由 [subtitle] 生成的副标题。
  Widget? get subtitleWidget => subtitle == null ? null : Text(subtitle!);
}

/// 开关设置项：对应一个 `bool` 偏好，点击整行或开关都能切换。
///
/// ```dart
/// const TfToggleSetting(key: AppKeys.autoPlay, title: '自动播放', icon: Icons.play_circle_outline)
/// ```
class TfToggleSetting extends TfSetting {
  const TfToggleSetting({required this.key, required super.title, super.subtitle, super.icon});

  /// 保存开关状态的偏好。
  final TfPreferenceKey<bool> key;

  @override
  Widget build(BuildContext context, TfPreferencesController preferences) {
    final value = preferences.get(key);
    return TfListTile(
      leading: leading,
      title: Text(title),
      subtitle: subtitleWidget,
      trailing: TfSwitch(value: value, onChanged: (next) => preferences.set(key, next)),
      onTap: () => preferences.set(key, !value),
    );
  }
}

/// [TfChoiceSetting] 的一个选项：保存的值 + 显示的文字 + 可选图标。
@immutable
class TfChoice<T> {
  const TfChoice(this.value, this.label, {this.icon});

  /// 选中时保存到偏好里的值。
  final T value;

  /// 显示给用户的文字。
  final String label;

  /// 图标（可选）。
  final IconData? icon;
}

/// 单选设置项：从 [options] 中选一个值保存。
///
/// 选项不超过 [inlineLimit] 个时直接显示为分段选择器；更多时显示当前值，
/// 点击后弹出对话框选择。偏好值是枚举时，用 [TfChoiceSetting.enumeration]。
///
/// ```dart
/// const TfChoiceSetting<int>(
///   key: AppKeys.syncInterval,
///   title: '同步间隔',
///   options: [TfChoice(15, '15 分钟'), TfChoice(60, '1 小时'), TfChoice(1440, '每天')],
/// )
/// ```
class TfChoiceSetting<T extends Object> extends TfSetting {
  const TfChoiceSetting({
    required this.key,
    required this.options,
    required super.title,
    super.subtitle,
    super.icon,
    this.inlineLimit = 3,
  });

  /// 枚举类型的单选：[labels] 中没有列出的枚举值不会显示。
  ///
  /// ```dart
  /// TfChoiceSetting.enumeration(
  ///   AppKeys.quality,   // TfEnumPreference<VideoQuality>
  ///   title: '画质',
  ///   labels: const {VideoQuality.sd: '标清', VideoQuality.hd: '高清'},
  /// )
  /// ```
  static TfChoiceSetting<String> enumeration<E extends Enum>(
    TfEnumPreference<E> preference, {
    required String title,
    required Map<E, String> labels,
    Map<E, IconData> icons = const {},
    String? subtitle,
    IconData? icon,
  }) => TfChoiceSetting<String>(
    key: preference.key,
    title: title,
    subtitle: subtitle,
    icon: icon,
    options: [
      for (final value in preference.values)
        if (labels[value] case final label?) TfChoice(value.name, label, icon: icons[value]),
    ],
  );

  /// 保存所选值的偏好。
  final TfPreferenceKey<T> key;

  /// 全部选项。
  final List<TfChoice<T>> options;

  /// 选项数不超过它时直接显示分段选择器，否则弹出对话框。
  final int inlineLimit;

  @override
  Widget build(BuildContext context, TfPreferencesController preferences) {
    final current = preferences.get(key);
    if (options.length <= inlineLimit) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TfListTile(leading: leading, title: Text(title), subtitle: subtitleWidget),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TfSegmentedControl<T>(
              selected: current,
              onChanged: (value) => preferences.set(key, value),
              segments: [
                for (final option in options) TfSegment(value: option.value, label: option.label, icon: option.icon),
              ],
            ),
          ),
        ],
      );
    }
    final currentLabel = options.where((option) => option.value == current).firstOrNull?.label ?? '';
    return TfListTile(
      leading: leading,
      title: Text(title),
      subtitle: subtitleWidget,
      trailing: Text(currentLabel),
      onTap: () async {
        final choice = await showTfDialog<T>(
          context,
          title: title,
          actions: [
            for (final option in options)
              TfDialogAction(label: option.label, value: option.value, isPrimary: option.value == current),
          ],
        );
        if (choice != null) await preferences.set(key, choice);
      },
    );
  }
}

/// 滑块设置项：对应一个 `double` 偏好，右侧显示当前值。
///
/// [format] 用来格式化显示的值；拖到偏好校验不允许的值时不会保存。
///
/// ```dart
/// TfSliderSetting(
///   key: AppKeys.volume,
///   title: '音量',
///   min: 0,
///   max: 1,
///   divisions: 10,
///   format: (v) => '${(v * 100).round()}%',
/// )
/// ```
class TfSliderSetting extends TfSetting {
  const TfSliderSetting({
    required this.key,
    required super.title,
    required this.min,
    required this.max,
    super.subtitle,
    super.icon,
    this.divisions,
    this.format,
  });

  /// 保存数值的偏好。
  final TfPreferenceKey<double> key;

  /// 最小值。
  final double min;

  /// 最大值。
  final double max;

  /// 等分数；为 null 时可连续取值。
  final int? divisions;

  /// 格式化右侧显示的值；为 null 时保留两位小数。
  final String Function(double value)? format;

  @override
  Widget build(BuildContext context, TfPreferencesController preferences) {
    final value = preferences.get(key);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TfListTile(
          leading: leading,
          title: Text(title),
          subtitle: subtitleWidget,
          trailing: Text(format?.call(value) ?? value.toStringAsFixed(2)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          child: TfSlider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: (next) {
              if (key.accepts(next)) preferences.set(key, next);
            },
          ),
        ),
      ],
    );
  }
}

/// 颜色设置项：从 [palette] 里选一种颜色，以 ARGB 整数保存。
///
/// ```dart
/// const TfColorSetting(
///   key: AppKeys.tagColor,
///   title: '标签颜色',
///   palette: [Colors.red, Colors.green, Colors.blue],
/// )
/// ```
class TfColorSetting extends TfSetting {
  const TfColorSetting({required this.key, required this.palette, required super.title, super.subtitle, super.icon});

  /// 保存颜色（ARGB 整数）的偏好。
  final TfPreferenceKey<int> key;

  /// 可选的颜色。
  final List<Color> palette;

  @override
  Widget build(BuildContext context, TfPreferencesController preferences) {
    final current = preferences.get(key);
    final outline = Theme.of(context).colorScheme.onSurface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TfListTile(leading: leading, title: Text(title), subtitle: subtitleWidget),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final color in palette)
                Semantics(
                  button: true,
                  selected: color.toARGB32() == current,
                  child: GestureDetector(
                    onTap: () => preferences.set(key, color.toARGB32()),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(color: color.toARGB32() == current ? outline : Colors.transparent, width: 3),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 操作设置项：点击后执行 [onTap]，不对应任何偏好，例如“退出登录”“清除缓存”。
///
/// ```dart
/// TfActionSetting(
///   title: '清除缓存',
///   icon: Icons.cleaning_services_outlined,
///   onTap: (context) async {
///     if (await showTfConfirm(context, title: '清除缓存？')) await cache.clear();
///   },
/// )
/// ```
class TfActionSetting extends TfSetting {
  const TfActionSetting({required this.onTap, required super.title, super.subtitle, super.icon, this.trailing});

  /// 点击时执行。
  final void Function(BuildContext context) onTap;

  /// 右侧控件（可选）。
  final Widget? trailing;

  @override
  Widget build(BuildContext context, TfPreferencesController preferences) => TfListTile(
    leading: leading,
    title: Text(title),
    subtitle: subtitleWidget,
    trailing: trailing,
    onTap: () => onTap(context),
  );
}

/// 组件库切换设置项：在注册的所有组件库之间切换（例如 Material 3 / 液态玻璃）。
///
/// 内置设置已包含它，通常无需手动添加。
class TfDesignSystemSetting extends TfSetting {
  const TfDesignSystemSetting({required super.title, super.subtitle, super.icon = Icons.widgets_outlined});

  @override
  Widget build(BuildContext context, TfPreferencesController preferences) {
    final framework = TfFramework.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TfListTile(leading: leading, title: Text(title), subtitle: subtitleWidget),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: TfSegmentedControl<String>(
            selected: framework.activeDesignSystem.id,
            onChanged: framework.switchDesignSystem,
            segments: [
              for (final system in framework.designSystems)
                TfSegment(value: system.id, label: system.displayName, icon: system.icon),
            ],
          ),
        ),
      ],
    );
  }
}

/// 文本设置项：显示当前文字，点击后弹出输入框修改，例如昵称、服务器地址。
///
/// 值为空时显示“未设置”。[obscureText] 为 true 时以圆点显示当前值。
///
/// ```dart
/// TfTextSetting(
///   key: AppKeys.serverUrl,
///   title: '服务器地址',
///   keyboardType: TextInputType.url,
///   validator: (v) => v != null && v.startsWith('http') ? null : '请以 http(s):// 开头',
/// )
/// ```
class TfTextSetting extends TfSetting {
  const TfTextSetting({
    required this.key,
    required super.title,
    super.subtitle,
    super.icon,
    this.placeholder,
    this.validator,
    this.obscureText = false,
    this.keyboardType,
  });

  /// 保存文字的偏好。
  final TfPreferenceKey<String> key;

  /// 输入框的占位提示。
  final String? placeholder;

  /// 校验规则；不通过时对话框不会关闭。
  final FormFieldValidator<String>? validator;

  /// 是否隐藏内容（例如密码、令牌）。
  final bool obscureText;

  /// 键盘类型。
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context, TfPreferencesController preferences) {
    final value = preferences.get(key);
    final display = value.isEmpty ? TfStrings.of(context).notSet : (obscureText ? '••••••' : value);
    return TfListTile(
      leading: leading,
      title: Text(title),
      subtitle: Text(subtitle ?? display),
      trailing: subtitle == null ? null : Text(display),
      onTap: () async {
        final next = await showTfInputDialog(
          context,
          title: title,
          initialValue: value,
          placeholder: placeholder,
          validator: (text) {
            if (!key.accepts(text)) return TfStrings.of(context).fieldRequired;
            return validator?.call(text);
          },
          obscureText: obscureText,
          keyboardType: keyboardType,
        );
        if (next != null) await preferences.set(key, next);
      },
    );
  }
}

/// 跳转设置项：点击后打开 [builder] 构建的页面，例如二级设置页或“关于”页。
///
/// ```dart
/// TfNavigationSetting(
///   title: '隐私',
///   icon: Icons.privacy_tip_outlined,
///   value: '已开启',
///   builder: (context) => const PrivacySettingsPage(),
/// )
/// ```
class TfNavigationSetting extends TfSetting {
  const TfNavigationSetting({required this.builder, required super.title, super.subtitle, super.icon, this.value});

  /// 构建要打开的页面。
  final WidgetBuilder builder;

  /// 显示在箭头前的当前值（可选）。
  final String? value;

  @override
  Widget build(BuildContext context, TfPreferencesController preferences) => TfListTile(
    leading: leading,
    title: Text(title),
    subtitle: subtitleWidget,
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [if (value != null) Text(value!), const Icon(Icons.chevron_right)],
    ),
    onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: builder)),
  );
}

/// 只读信息项：在右侧显示一个值，例如版本号、设备 ID。
///
/// ```dart
/// const TfInfoSetting(title: '版本', value: '1.2.0')
/// ```
class TfInfoSetting extends TfSetting {
  const TfInfoSetting({required this.value, required super.title, super.subtitle, super.icon});

  /// 显示的值。
  final String value;

  @override
  Widget build(BuildContext context, TfPreferencesController preferences) =>
      TfListTile(leading: leading, title: Text(title), subtitle: subtitleWidget, trailing: Text(value));
}

/// 语言设置项：选择界面语言，第一项“跟随系统”。
///
/// [languages] 的键是语言代码，值是该语言自己的名称。
/// 内置设置已包含中英文；增加语言时还需要提供对应的 `TfStrings`
/// 并加入 `TfApp.supportedLocales`。
///
/// ```dart
/// const TfLanguageSetting(
///   title: '语言',
///   languages: {'en': 'English', 'zh': '简体中文', 'ja': '日本語'},
/// )
/// ```
class TfLanguageSetting extends TfSetting {
  const TfLanguageSetting({
    required super.title,
    super.subtitle,
    super.icon = Icons.language,
    this.languages = const {'en': 'English', 'zh': '简体中文'},
  });

  /// 语言代码 → 语言名称。
  final Map<String, String> languages;

  @override
  Widget build(BuildContext context, TfPreferencesController preferences) => TfChoiceSetting<String>(
    key: TfPreferenceKeys.locale,
    title: title,
    subtitle: subtitle,
    icon: icon,
    options: [
      TfChoice('', TfStrings.of(context).followSystem),
      for (final MapEntry(:key, :value) in languages.entries) TfChoice(key, value),
    ],
  ).build(context, preferences);
}
