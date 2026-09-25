import 'package:flutter/material.dart';

import '../app/framework.dart';
import '../components/components.dart';
import '../design/design_system.dart';
import '../kits/overlays.dart';
import '../l10n/tf_strings.dart';
import '../preferences/preference_keys.dart';
import 'setting.dart';

/// 内置“强调色”设置提供的默认色板。
const tfDefaultPalette = [
  Color(0xFF4F6BED),
  Color(0xFF0A84FF),
  Color(0xFF00A6A6),
  Color(0xFF34C759),
  Color(0xFFFF9500),
  Color(0xFFFF375F),
  Color(0xFFAF52DE),
  Color(0xFF8E8E93),
];

/// 框架内置的设置分组，文字使用 [strings] 的语言。
///
/// 包括“外观”（组件库、主题、强调色、语言）和“显示与无障碍”（字体大小、
/// 紧凑布局、减少动态效果）。[TfSettingsPage] 会自动包含它们；
/// 只在自己组装设置页时才需要直接调用。[palette] 可替换强调色的可选颜色。
List<TfSettingsSection> tfBuiltInSettings(TfStrings strings, {List<Color> palette = tfDefaultPalette}) => [
  TfSettingsSection(
    title: strings.appearance,
    settings: [
      TfDesignSystemSetting(title: strings.componentLibrary),
      TfChoiceSetting.enumeration(
        TfPreferenceKeys.themeMode,
        title: strings.theme,
        icon: Icons.brightness_6_outlined,
        labels: {
          ThemeMode.system: strings.themeSystem,
          ThemeMode.light: strings.themeLight,
          ThemeMode.dark: strings.themeDark,
        },
      ),
      TfColorSetting(
        key: TfPreferenceKeys.seedColor,
        palette: palette,
        title: strings.accentColor,
        icon: Icons.palette_outlined,
      ),
      TfLanguageSetting(title: strings.language),
    ],
  ),
  TfSettingsSection(
    title: strings.displayAndAccessibility,
    settings: [
      TfSliderSetting(
        key: TfPreferenceKeys.textScale,
        title: strings.textSize,
        icon: Icons.format_size,
        min: 0.8,
        max: 1.6,
        divisions: 8,
        format: (value) => '${(value * 100).round()}%',
      ),
      TfToggleSetting(key: TfPreferenceKeys.compact, title: strings.compactLayout, icon: Icons.density_medium),
      TfToggleSetting(
        key: TfPreferenceKeys.reduceMotion,
        title: strings.reduceMotion,
        icon: Icons.motion_photos_off_outlined,
      ),
    ],
  ),
];

/// 自动生成的完整设置页（带顶栏），直接 push 即可使用。
///
/// 页面内容依次为：
/// 1. 内置设置（[includeBuiltIns] 为 false 时不显示）；
/// 2. 当前组件库自带的设置（例如液态玻璃的模糊度）；
/// 3. 应用通过 `TfFramework.initialize` 的 `settings` / `settingsBuilder` 注册的设置；
/// 4. “恢复所有默认设置”按钮（[showResetAll] 为 false 时不显示）。
///
/// 所有修改立即生效并自动保存。
///
/// ```dart
/// Navigator.of(context).push(
///   MaterialPageRoute(builder: (_) => const TfSettingsPage()),
/// );
/// ```
class TfSettingsPage extends StatelessWidget {
  const TfSettingsPage({super.key, this.title, this.includeBuiltIns = true, this.showResetAll = true});

  /// 页面标题，默认为当前语言的“设置”。
  final String? title;

  /// 是否显示框架内置的设置分组。
  final bool includeBuiltIns;

  /// 是否在底部显示“恢复所有默认设置”。
  final bool showResetAll;

  @override
  Widget build(BuildContext context) => TfScaffold(
    title: title ?? TfStrings.of(context).settings,
    body: TfSettingsList(includeBuiltIns: includeBuiltIns, showResetAll: showResetAll),
  );
}

/// [TfSettingsPage] 的内容部分（不带顶栏），适合放在标签页里。
///
/// ```dart
/// TfScaffold(
///   destinations: [...],
///   body: _tab == 2 ? const TfSettingsList() : ...,
/// )
/// ```
class TfSettingsList extends StatelessWidget {
  const TfSettingsList({super.key, this.includeBuiltIns = true, this.showResetAll = true});

  /// 是否显示框架内置的设置分组。
  final bool includeBuiltIns;

  /// 是否在底部显示“恢复所有默认设置”。
  final bool showResetAll;

  @override
  Widget build(BuildContext context) {
    final framework = TfFramework.of(context);
    final preferences = framework.preferences;
    final strings = TfStrings.of(context);
    return ListenableBuilder(
      listenable: preferences,
      builder: (context, _) {
        final sections = [
          if (includeBuiltIns) ...tfBuiltInSettings(strings),
          ...TfDesign.of(context).settingsSections(strings),
          ...framework.settingsFor(context),
        ];
        return TfListView(
          children: [
            for (final section in sections)
              TfSection(
                title: section.title,
                footer: section.footer,
                children: [for (final setting in section.settings) setting.build(context, preferences)],
              ),
            if (showResetAll)
              Center(
                child: TfButton.text(
                  label: strings.resetAllSettings,
                  icon: Icons.restart_alt,
                  onPressed: () async {
                    final confirmed = await showTfConfirm(
                      context,
                      title: strings.resetAllSettings,
                      message: strings.resetAllSettingsMessage,
                      confirmLabel: strings.reset,
                      destructive: true,
                    );
                    if (confirmed) await preferences.resetAll();
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}
