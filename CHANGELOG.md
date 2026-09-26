## 0.3.2

* 许可证由 MPL-2.0 改为 GPL-3.0-or-later（版权人变更许可，API 没有任何变化）。
  分发包含本框架的应用时，应用需要以 GPL 兼容许可证开源；
  闭源应用请继续使用 0.3.1（MPL-2.0）。

## 0.3.1

* 许可证由 LGPL-3.0 改为 MPL-2.0，闭源应用也可以放心使用。
* README 补充在其他项目中引用本包的方法。

## 0.3.0

* 移除 example 中的界面程序，项目改为纯框架；使用示例见 `example/example.md`。
* 所有公开 API 补充中文使用说明与示例代码。
* 源文件统一使用 LF 换行。
* 以 LGPL-3.0 许可证发布。

## 0.2.0

* Kits: `TfLoginForm`, `TfSignUpForm`, `TfAuthLayout`, form fields and
  validators, alert/confirm/input dialogs, action and bottom sheets, loading
  overlay, banner, empty/error/loading states, `TfAsyncBuilder`, `TfAvatar`.
* Localization: English and Simplified Chinese `TfStrings`, language setting.
* New settings: text, navigation, info, language.
* Material 3 uses a navigation rail on wide windows.
* Breaking: `TfDesignSystem` gained `checkbox`, `showActionSheet`,
  `showSheet`, richer `textField`/`button`/`showDialog` parameters, and
  `settings` became `settingsSections(TfStrings)`.

## 0.1.0

* Rewrite: `Tf*` components backed by switchable design systems
  (Material 3, Liquid Glass), typed persistent preferences and a declarative,
  generated settings page.
