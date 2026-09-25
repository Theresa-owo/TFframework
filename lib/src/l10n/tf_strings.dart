import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// 框架显示给用户的全部文字（按钮、校验提示、设置项名称等）。
///
/// 内置英文 [TfStringsEn] 和简体中文 [TfStringsZh]，会跟随应用语言自动切换。
/// 修改措辞或新增语言时，继承其中一个并覆盖需要的字段，再传给 `TfApp.strings`：
///
/// ```dart
/// class MyZhStrings extends TfStringsZh {
///   const MyZhStrings();
///
///   @override
///   String get signIn => '立即登录';
/// }
///
/// TfApp(framework: framework, strings: {'zh': const MyZhStrings()}, home: ...)
/// ```
///
/// 在自己的控件里也可以复用这些文字：`TfStrings.of(context).cancel`。
abstract class TfStrings {
  const TfStrings();

  /// 当前语言的文案；找不到时返回英文。
  static TfStrings of(BuildContext context) => Localizations.of<TfStrings>(context, TfStrings) ?? const TfStringsEn();

  // Common actions
  String get ok;
  String get cancel;
  String get confirm;
  String get close;
  String get retry;
  String get save;
  String get delete;
  String get loading;

  // Settings
  String get settings;
  String get appearance;
  String get componentLibrary;
  String get theme;
  String get themeSystem;
  String get themeLight;
  String get themeDark;
  String get accentColor;
  String get language;
  String get followSystem;
  String get displayAndAccessibility;
  String get textSize;
  String get compactLayout;
  String get reduceMotion;
  String get resetAllSettings;
  String get resetAllSettingsMessage;
  String get reset;
  String get glassBlur;
  String get glassQuality;
  String get glassQualityMinimal;
  String get glassQualityStandard;
  String get glassQualityPremium;
  String get glassAdaptiveQuality;
  String get glassAdaptiveQualitySubtitle;
  String get glassFooter;
  String get notSet;

  // Authentication
  String get signIn;
  String get signUp;
  String get signOut;
  String get email;
  String get username;
  String get phone;
  String get password;
  String get confirmPassword;
  String get name;
  String get rememberMe;
  String get forgotPassword;
  String get noAccount;
  String get haveAccount;
  String get showPassword;
  String get hidePassword;
  String get orContinueWith;
  String get acceptTerms;

  // Validation
  String get fieldRequired;
  String get invalidEmail;
  String get invalidPhone;
  String minLength(int length);
  String get passwordsDoNotMatch;
  String get mustAcceptTerms;

  // States
  String get emptyTitle;
  String get errorTitle;
  String get somethingWentWrong;
}

/// 英文文案。
class TfStringsEn extends TfStrings {
  const TfStringsEn();

  @override
  String get ok => 'OK';
  @override
  String get cancel => 'Cancel';
  @override
  String get confirm => 'Confirm';
  @override
  String get close => 'Close';
  @override
  String get retry => 'Retry';
  @override
  String get save => 'Save';
  @override
  String get delete => 'Delete';
  @override
  String get loading => 'Loading…';

  @override
  String get settings => 'Settings';
  @override
  String get appearance => 'Appearance';
  @override
  String get componentLibrary => 'Component library';
  @override
  String get theme => 'Theme';
  @override
  String get themeSystem => 'System';
  @override
  String get themeLight => 'Light';
  @override
  String get themeDark => 'Dark';
  @override
  String get accentColor => 'Accent color';
  @override
  String get language => 'Language';
  @override
  String get followSystem => 'Follow system';
  @override
  String get displayAndAccessibility => 'Display & accessibility';
  @override
  String get textSize => 'Text size';
  @override
  String get compactLayout => 'Compact layout';
  @override
  String get reduceMotion => 'Reduce motion';
  @override
  String get resetAllSettings => 'Reset all settings';
  @override
  String get resetAllSettingsMessage => 'Every preference returns to its default value.';
  @override
  String get reset => 'Reset';
  @override
  String get glassBlur => 'Blur';
  @override
  String get glassQuality => 'Rendering quality';
  @override
  String get glassQualityMinimal => 'Minimal';
  @override
  String get glassQualityStandard => 'Standard';
  @override
  String get glassQualityPremium => 'Premium';
  @override
  String get glassAdaptiveQuality => 'Adaptive quality';
  @override
  String get glassAdaptiveQualitySubtitle => 'Lower quality automatically on slow frames';
  @override
  String get glassFooter => 'Premium quality enables refraction and chromatic dispersion on Impeller.';
  @override
  String get notSet => 'Not set';

  @override
  String get signIn => 'Sign in';
  @override
  String get signUp => 'Sign up';
  @override
  String get signOut => 'Sign out';
  @override
  String get email => 'Email';
  @override
  String get username => 'Username';
  @override
  String get phone => 'Phone number';
  @override
  String get password => 'Password';
  @override
  String get confirmPassword => 'Confirm password';
  @override
  String get name => 'Name';
  @override
  String get rememberMe => 'Remember me';
  @override
  String get forgotPassword => 'Forgot password?';
  @override
  String get noAccount => "Don't have an account?";
  @override
  String get haveAccount => 'Already have an account?';
  @override
  String get showPassword => 'Show password';
  @override
  String get hidePassword => 'Hide password';
  @override
  String get orContinueWith => 'or continue with';
  @override
  String get acceptTerms => 'I agree to the terms of service';

  @override
  String get fieldRequired => 'This field is required';
  @override
  String get invalidEmail => 'Enter a valid email address';
  @override
  String get invalidPhone => 'Enter a valid phone number';
  @override
  String minLength(int length) => 'Must be at least $length characters';
  @override
  String get passwordsDoNotMatch => 'Passwords do not match';
  @override
  String get mustAcceptTerms => 'Please accept the terms to continue';

  @override
  String get emptyTitle => 'Nothing here yet';
  @override
  String get errorTitle => 'Something went wrong';
  @override
  String get somethingWentWrong => 'Something went wrong. Please try again.';
}

/// 简体中文文案。
class TfStringsZh extends TfStrings {
  const TfStringsZh();

  @override
  String get ok => '好';
  @override
  String get cancel => '取消';
  @override
  String get confirm => '确定';
  @override
  String get close => '关闭';
  @override
  String get retry => '重试';
  @override
  String get save => '保存';
  @override
  String get delete => '删除';
  @override
  String get loading => '加载中…';

  @override
  String get settings => '设置';
  @override
  String get appearance => '外观';
  @override
  String get componentLibrary => '组件库';
  @override
  String get theme => '主题';
  @override
  String get themeSystem => '跟随系统';
  @override
  String get themeLight => '浅色';
  @override
  String get themeDark => '深色';
  @override
  String get accentColor => '强调色';
  @override
  String get language => '语言';
  @override
  String get followSystem => '跟随系统';
  @override
  String get displayAndAccessibility => '显示与无障碍';
  @override
  String get textSize => '字体大小';
  @override
  String get compactLayout => '紧凑布局';
  @override
  String get reduceMotion => '减少动态效果';
  @override
  String get resetAllSettings => '恢复所有默认设置';
  @override
  String get resetAllSettingsMessage => '所有偏好设置都将恢复为默认值。';
  @override
  String get reset => '恢复';
  @override
  String get glassBlur => '模糊程度';
  @override
  String get glassQuality => '渲染质量';
  @override
  String get glassQualityMinimal => '最低';
  @override
  String get glassQualityStandard => '标准';
  @override
  String get glassQualityPremium => '高级';
  @override
  String get glassAdaptiveQuality => '自适应质量';
  @override
  String get glassAdaptiveQualitySubtitle => '掉帧时自动降低渲染质量';
  @override
  String get glassFooter => '高级质量会在 Impeller 上启用折射和色散效果。';
  @override
  String get notSet => '未设置';

  @override
  String get signIn => '登录';
  @override
  String get signUp => '注册';
  @override
  String get signOut => '退出登录';
  @override
  String get email => '邮箱';
  @override
  String get username => '用户名';
  @override
  String get phone => '手机号';
  @override
  String get password => '密码';
  @override
  String get confirmPassword => '确认密码';
  @override
  String get name => '姓名';
  @override
  String get rememberMe => '记住我';
  @override
  String get forgotPassword => '忘记密码？';
  @override
  String get noAccount => '还没有账号？';
  @override
  String get haveAccount => '已有账号？';
  @override
  String get showPassword => '显示密码';
  @override
  String get hidePassword => '隐藏密码';
  @override
  String get orContinueWith => '或使用以下方式';
  @override
  String get acceptTerms => '我已阅读并同意服务条款';

  @override
  String get fieldRequired => '此项为必填项';
  @override
  String get invalidEmail => '请输入有效的邮箱地址';
  @override
  String get invalidPhone => '请输入有效的手机号';
  @override
  String minLength(int length) => '至少需要 $length 个字符';
  @override
  String get passwordsDoNotMatch => '两次输入的密码不一致';
  @override
  String get mustAcceptTerms => '请先同意服务条款';

  @override
  String get emptyTitle => '暂无内容';
  @override
  String get errorTitle => '出错了';
  @override
  String get somethingWentWrong => '出了点问题，请重试。';
}

/// 按当前语言加载 [TfStrings]，优先使用 [overrides]。[TfApp] 会自动注册，一般无需直接使用。
class TfStringsDelegate extends LocalizationsDelegate<TfStrings> {
  const TfStringsDelegate({this.overrides = const {}});

  /// 内置的语言文案。
  static const builtIn = <String, TfStrings>{'en': TfStringsEn(), 'zh': TfStringsZh()};

  /// 自定义文案，键为语言代码，例如 `{'ja': MyJapaneseStrings()}`。
  final Map<String, TfStrings> overrides;

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<TfStrings> load(Locale locale) =>
      SynchronousFuture(overrides[locale.languageCode] ?? builtIn[locale.languageCode] ?? const TfStringsEn());

  @override
  bool shouldReload(TfStringsDelegate old) => !mapEquals(old.overrides, overrides);
}
