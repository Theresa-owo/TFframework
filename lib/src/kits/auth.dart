import 'package:flutter/material.dart';

import '../components/components.dart';
import '../design/design_system.dart';
import '../l10n/tf_strings.dart';
import 'feedback.dart';
import 'forms.dart';

/// 登录 / 注册失败时抛出的异常，[message] 会显示在表单顶部的错误横幅里。
///
/// 在 [TfLoginForm.onSubmit] 或 [TfSignUpForm.onSubmit] 里抛出它，表示“这是
/// 预期内的失败，请把原因告诉用户”。其他异常只会显示通用错误文案，
/// 并通过 `FlutterError.reportError` 上报。
///
/// ```dart
/// onSubmit: (credentials) async {
///   final result = await api.login(credentials.identifier, credentials.password);
///   if (result == LoginResult.wrongPassword) {
///     throw const TfAuthException('账号或密码错误');
///   }
/// }
/// ```
class TfAuthException implements Exception {
  const TfAuthException(this.message);

  /// 显示给用户的错误信息。
  final String message;

  @override
  String toString() => 'TfAuthException: $message';
}

/// [TfLoginForm] 第一个输入框填写的账号类型，决定图标、键盘和校验规则。
enum TfLoginIdentifier {
  /// 邮箱：校验邮箱格式。
  email,

  /// 用户名：只校验非空。
  username,

  /// 手机号：校验电话号码格式。
  phone,
}

/// 用户在 [TfLoginForm] 中提交的登录信息。
@immutable
class TfLoginCredentials {
  const TfLoginCredentials({required this.identifier, required this.password, required this.rememberMe});

  /// 账号（邮箱、用户名或手机号），已去掉首尾空格。
  final String identifier;

  /// 密码，原样保留。
  final String password;

  /// 是否勾选了“记住我”。
  final bool rememberMe;
}

/// 用户在 [TfSignUpForm] 中提交的注册信息。
@immutable
class TfSignUpData {
  const TfSignUpData({required this.email, required this.password, this.name});

  /// 姓名；[TfSignUpForm.askName] 为 false 时为 null。
  final String? name;

  /// 邮箱，已去掉首尾空格。
  final String email;

  /// 密码（两次输入已校验一致）。
  final String password;
}

/// 登录 / 注册页的布局：在页面中央依次显示 Logo、标题、副标题和一张装着表单的卡片。
///
/// 在大窗口上，卡片宽度不超过 [maxWidth]；内容过高时整页可滚动。
///
/// ```dart
/// TfScaffold(
///   body: TfAuthLayout(
///     logo: Image.asset('assets/logo.png', height: 64),
///     title: '欢迎回来',
///     subtitle: '登录以继续',
///     child: TfLoginForm(onSubmit: signIn),
///   ),
/// )
/// ```
class TfAuthLayout extends StatelessWidget {
  const TfAuthLayout({super.key, required this.child, this.logo, this.title, this.subtitle, this.maxWidth = 420});

  /// 卡片里的内容，通常是 [TfLoginForm] 或 [TfSignUpForm]。
  final Widget child;

  /// 顶部 Logo（可选）。
  final Widget? logo;

  /// 标题（可选）。
  final String? title;

  /// 副标题（可选）。
  final String? subtitle;

  /// 卡片最大宽度。
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: MediaQuery.paddingOf(context) + const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (logo != null) ...[Center(child: logo), const SizedBox(height: 16)],
              if (title != null) Text(title!, style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ],
              if (title != null || subtitle != null) const SizedBox(height: 24),
              TfCard(padding: const EdgeInsets.all(20), child: child),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shared submit handling: validation, busy state and error display.
mixin _TfAuthFormState<W extends StatefulWidget> on State<W> {
  final formKey = GlobalKey<FormState>();
  bool submitting = false;
  String? error;

  Future<void> submit(Future<void> Function() action) async {
    if (submitting) return;
    setState(() => error = null);
    if (!(formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() => submitting = true);
    try {
      await action();
    } on TfAuthException catch (e) {
      if (mounted) setState(() => error = e.message);
    } catch (e, stack) {
      FlutterError.reportError(FlutterErrorDetails(exception: e, stack: stack, library: 'tf_framework'));
      if (mounted) setState(() => error = TfStrings.of(context).somethingWentWrong);
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  Widget errorBanner() => error == null
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: TfBanner(message: error!, type: TfToastType.error, onClose: () => setState(() => error = null)),
        );
}

Widget _switchRow(BuildContext context, String prompt, String action, VoidCallback onPressed) => Wrap(
  alignment: WrapAlignment.center,
  crossAxisAlignment: WrapCrossAlignment.center,
  children: [
    Text(prompt, style: Theme.of(context).textTheme.bodyMedium),
    TfButton.text(label: action, onPressed: onPressed),
  ],
);

/// 完整的登录表单。
///
/// 包含：账号输入框（邮箱 / 用户名 / 手机号）、带显示切换的密码框、“记住我”、
/// “忘记密码？”、“还没有账号？注册”，以及可选的第三方登录按钮。
///
/// 点击“登录”后，表单先校验所有字段，通过后调用 [onSubmit]。等待期间按钮
/// 显示加载动画，输入框被禁用。[onSubmit] 抛出 [TfAuthException] 时，其消息
/// 显示在表单顶部；抛出其他异常时显示通用错误文案。
///
/// [onForgotPassword] 或 [onSignUp] 为 null 时，对应入口不显示。
/// 表单已接入系统的账号密码自动填充。
///
/// ```dart
/// TfLoginForm(
///   identifier: TfLoginIdentifier.phone,
///   initialIdentifier: savedPhone,
///   onSubmit: (credentials) async {
///     await auth.signIn(credentials.identifier, credentials.password);
///     if (credentials.rememberMe) await savePhone(credentials.identifier);
///   },
///   onForgotPassword: () => Navigator.pushNamed(context, '/forgot'),
///   onSignUp: () => Navigator.pushNamed(context, '/sign-up'),
///   alternativeActions: [
///     TfButton.secondary(label: '微信登录', icon: Icons.chat, onPressed: wechatLogin),
///   ],
/// )
/// ```
class TfLoginForm extends StatefulWidget {
  const TfLoginForm({
    super.key,
    required this.onSubmit,
    this.identifier = TfLoginIdentifier.email,
    this.initialIdentifier,
    this.initialRememberMe = false,
    this.showRememberMe = true,
    this.minPasswordLength = 6,
    this.onForgotPassword,
    this.onSignUp,
    this.alternativeActions = const [],
  });

  /// 校验通过后调用。成功时正常返回；失败时抛出 [TfAuthException]。
  final Future<void> Function(TfLoginCredentials credentials) onSubmit;

  /// 账号类型。
  final TfLoginIdentifier identifier;

  /// 账号输入框的初始值，例如上次“记住我”保存的账号。
  final String? initialIdentifier;

  /// “记住我”的初始勾选状态。
  final bool initialRememberMe;

  /// 是否显示“记住我”。
  final bool showRememberMe;

  /// 密码最少长度。
  final int minPasswordLength;

  /// 点击“忘记密码？”时回调；为 null 时不显示该入口。
  final VoidCallback? onForgotPassword;

  /// 点击“注册”时回调；为 null 时不显示该入口。
  final VoidCallback? onSignUp;

  /// 显示在“或使用以下方式”分隔线下方的按钮，例如第三方登录。
  final List<Widget> alternativeActions;

  @override
  State<TfLoginForm> createState() => _TfLoginFormState();
}

class _TfLoginFormState extends State<TfLoginForm> with _TfAuthFormState {
  late final _identifier = TextEditingController(text: widget.initialIdentifier);
  final _password = TextEditingController();
  late bool _rememberMe = widget.initialRememberMe;

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() => submit(
    () => widget.onSubmit(
      TfLoginCredentials(identifier: _identifier.text.trim(), password: _password.text, rememberMe: _rememberMe),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final strings = TfStrings.of(context);
    final validators = TfValidators(strings);
    final (label, icon, keyboard, hints, validator) = switch (widget.identifier) {
      TfLoginIdentifier.email => (
        strings.email,
        Icons.mail_outline,
        TextInputType.emailAddress,
        const [AutofillHints.email, AutofillHints.username],
        TfValidators.compose([validators.required(), validators.email()]),
      ),
      TfLoginIdentifier.username => (
        strings.username,
        Icons.person_outline,
        TextInputType.text,
        const [AutofillHints.username],
        validators.required(),
      ),
      TfLoginIdentifier.phone => (
        strings.phone,
        Icons.phone_outlined,
        TextInputType.phone,
        const [AutofillHints.telephoneNumber],
        TfValidators.compose([validators.required(), validators.phone()]),
      ),
    };

    return AutofillGroup(
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            errorBanner(),
            TfTextFormField(
              controller: _identifier,
              placeholder: label,
              prefixIcon: icon,
              keyboardType: keyboard,
              autofillHints: hints,
              textInputAction: TextInputAction.next,
              validator: validator,
              enabled: !submitting,
            ),
            const SizedBox(height: 12),
            TfPasswordField(
              controller: _password,
              textInputAction: TextInputAction.done,
              validator: TfValidators.compose([validators.required(), validators.minLength(widget.minPasswordLength)]),
              onFieldSubmitted: (_) => _submit(),
              enabled: !submitting,
            ),
            if (widget.showRememberMe || widget.onForgotPassword != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  if (widget.showRememberMe)
                    Flexible(
                      child: TfCheckbox(
                        value: _rememberMe,
                        onChanged: submitting ? null : (value) => setState(() => _rememberMe = value),
                        label: Text(strings.rememberMe),
                      ),
                    ),
                  const Spacer(),
                  if (widget.onForgotPassword != null)
                    TfButton.text(label: strings.forgotPassword, onPressed: widget.onForgotPassword),
                ],
              ),
            ],
            const SizedBox(height: 16),
            TfButton(label: strings.signIn, expanded: true, loading: submitting, onPressed: _submit),
            if (widget.alternativeActions.isNotEmpty) ...[
              const SizedBox(height: 20),
              _DividerLabel(strings.orContinueWith),
              const SizedBox(height: 12),
              Wrap(alignment: WrapAlignment.center, spacing: 12, runSpacing: 12, children: widget.alternativeActions),
            ],
            if (widget.onSignUp != null) ...[
              const SizedBox(height: 12),
              _switchRow(context, strings.noAccount, strings.signUp, widget.onSignUp!),
            ],
          ],
        ),
      ),
    );
  }
}

/// 完整的注册表单：姓名（可选）、邮箱、密码、确认密码，以及可选的“同意条款”。
///
/// 提交流程和错误显示与 [TfLoginForm] 相同。设置了 [termsLabel] 时，
/// 用户必须勾选才能提交。密码框使用 `AutofillHints.newPassword`，
/// 系统可以帮用户生成并保存密码。
///
/// ```dart
/// TfSignUpForm(
///   minPasswordLength: 8,
///   termsLabel: const Text('我已阅读并同意《服务条款》'),
///   onSubmit: (data) async {
///     await auth.register(name: data.name, email: data.email, password: data.password);
///   },
///   onSignIn: () => Navigator.pop(context),
/// )
/// ```
class TfSignUpForm extends StatefulWidget {
  const TfSignUpForm({
    super.key,
    required this.onSubmit,
    this.askName = true,
    this.minPasswordLength = 8,
    this.termsLabel,
    this.onSignIn,
  });

  /// 校验通过后调用。失败时抛出 [TfAuthException]。
  final Future<void> Function(TfSignUpData data) onSubmit;

  /// 是否显示“姓名”输入框。
  final bool askName;

  /// 密码最少长度。
  final int minPasswordLength;

  /// 设置后显示“同意条款”复选框，用户必须勾选才能提交。
  final Widget? termsLabel;

  /// 点击“已有账号？登录”时回调；为 null 时不显示该入口。
  final VoidCallback? onSignIn;

  @override
  State<TfSignUpForm> createState() => _TfSignUpFormState();
}

class _TfSignUpFormState extends State<TfSignUpForm> with _TfAuthFormState {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _acceptedTerms = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (widget.termsLabel != null && !_acceptedTerms) {
      setState(() => error = TfStrings.of(context).mustAcceptTerms);
      return;
    }
    submit(
      () => widget.onSubmit(
        TfSignUpData(
          name: widget.askName ? _name.text.trim() : null,
          email: _email.text.trim(),
          password: _password.text,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = TfStrings.of(context);
    final validators = TfValidators(strings);
    return AutofillGroup(
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            errorBanner(),
            if (widget.askName) ...[
              TfTextFormField(
                controller: _name,
                placeholder: strings.name,
                prefixIcon: Icons.badge_outlined,
                autofillHints: const [AutofillHints.name],
                textInputAction: TextInputAction.next,
                validator: validators.required(),
                enabled: !submitting,
              ),
              const SizedBox(height: 12),
            ],
            TfTextFormField(
              controller: _email,
              placeholder: strings.email,
              prefixIcon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.next,
              validator: TfValidators.compose([validators.required(), validators.email()]),
              enabled: !submitting,
            ),
            const SizedBox(height: 12),
            TfPasswordField(
              controller: _password,
              autofillHints: const [AutofillHints.newPassword],
              textInputAction: TextInputAction.next,
              validator: TfValidators.compose([validators.required(), validators.minLength(widget.minPasswordLength)]),
              enabled: !submitting,
            ),
            const SizedBox(height: 12),
            TfPasswordField(
              placeholder: strings.confirmPassword,
              autofillHints: const [AutofillHints.newPassword],
              textInputAction: TextInputAction.done,
              validator: validators.matches(() => _password.text),
              onFieldSubmitted: (_) => _submit(),
              enabled: !submitting,
            ),
            if (widget.termsLabel != null) ...[
              const SizedBox(height: 8),
              TfCheckbox(
                value: _acceptedTerms,
                onChanged: submitting ? null : (value) => setState(() => _acceptedTerms = value),
                label: widget.termsLabel,
              ),
            ],
            const SizedBox(height: 16),
            TfButton(label: strings.signUp, expanded: true, loading: submitting, onPressed: _submit),
            if (widget.onSignIn != null) ...[
              const SizedBox(height: 12),
              _switchRow(context, strings.haveAccount, strings.signIn, widget.onSignIn!),
            ],
          ],
        ),
      ),
    );
  }
}

class _DividerLabel extends StatelessWidget {
  const _DividerLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final line = Expanded(child: Divider(color: theme.colorScheme.outlineVariant));
    return Row(
      children: [
        line,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ),
        line,
      ],
    );
  }
}
