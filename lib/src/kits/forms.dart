import 'package:flutter/material.dart';

import '../components/components.dart';
import '../l10n/tf_strings.dart';

/// 常用的表单校验规则，错误提示会跟随当前语言。
///
/// 每个方法返回一个 `FormFieldValidator<String>`，可以直接传给
/// [TfTextFormField.validator]、[TfPasswordField.validator] 或 Flutter 自带的
/// `TextFormField`。多个规则用 [compose] 组合，按顺序返回第一个错误。
///
/// 除 [required] 和 [matches] 外，其他规则遇到空值都直接通过；
/// 如果字段必填，请和 [required] 组合使用。
///
/// ```dart
/// final v = TfValidators.of(context);
///
/// TfTextFormField(
///   placeholder: '邮箱',
///   validator: TfValidators.compose([v.required(), v.email()]),
/// )
/// TfPasswordField(validator: v.minLength(8, '密码至少 8 位'))
/// ```
class TfValidators {
  /// 使用指定的文案创建，通常直接用 [TfValidators.of]。
  const TfValidators(this.strings);

  /// 使用当前语言的文案创建。
  factory TfValidators.of(BuildContext context) => TfValidators(TfStrings.of(context));

  /// 默认错误提示的来源。
  final TfStrings strings;

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _phonePattern = RegExp(r'^\+?[0-9 ()-]{6,20}$');

  /// 按顺序执行 [validators]，返回第一个错误；全部通过时返回 null。
  static FormFieldValidator<String> compose(List<FormFieldValidator<String>> validators) => (value) {
    for (final validator in validators) {
      final error = validator(value);
      if (error != null) return error;
    }
    return null;
  };

  /// 必填：只含空白字符也视为空。[message] 可替换默认提示。
  FormFieldValidator<String> required([String? message]) =>
      (value) => value == null || value.trim().isEmpty ? message ?? strings.fieldRequired : null;

  /// 邮箱格式。
  FormFieldValidator<String> email([String? message]) =>
      (value) => value == null || value.isEmpty || _emailPattern.hasMatch(value.trim())
      ? null
      : message ?? strings.invalidEmail;

  /// 电话号码：6～20 位数字，允许 `+`、空格、括号和连字符。
  FormFieldValidator<String> phone([String? message]) =>
      (value) => value == null || value.isEmpty || _phonePattern.hasMatch(value.trim())
      ? null
      : message ?? strings.invalidPhone;

  /// 最少 [length] 个字符。
  FormFieldValidator<String> minLength(int length, [String? message]) =>
      (value) => value == null || value.isEmpty || value.length >= length ? null : message ?? strings.minLength(length);

  /// 自定义正则：不匹配 [pattern] 时返回 [message]。
  FormFieldValidator<String> pattern(RegExp pattern, String message) =>
      (value) => value == null || value.isEmpty || pattern.hasMatch(value) ? null : message;

  /// 必须与 [other] 返回的值相同，常用于“确认密码”。
  ///
  /// ```dart
  /// TfPasswordField(
  ///   placeholder: '确认密码',
  ///   validator: v.matches(() => _password.text),
  /// )
  /// ```
  FormFieldValidator<String> matches(ValueGetter<String> other, [String? message]) =>
      (value) => value == other() ? null : message ?? strings.passwordsDoNotMatch;
}

/// 带校验的输入框，用在 Flutter 的 `Form` 里。
///
/// 外观与 [TfTextField] 相同，另外支持 [validator]、`onSaved` 和表单重置。
/// 默认在输入框失去焦点时校验一次。调用 `formKey.currentState!.validate()`
/// 会校验表单中的所有字段，并在出错的字段下显示错误。
///
/// [controller] 和 `initialValue` 只能二选一。
///
/// ```dart
/// final _formKey = GlobalKey<FormState>();
/// final _email = TextEditingController();
///
/// Form(
///   key: _formKey,
///   child: Column(children: [
///     TfTextFormField(
///       controller: _email,
///       placeholder: '邮箱',
///       prefixIcon: Icons.mail_outline,
///       keyboardType: TextInputType.emailAddress,
///       validator: TfValidators.of(context).email(),
///     ),
///     TfButton(
///       label: '提交',
///       onPressed: () {
///         if (_formKey.currentState!.validate()) submit(_email.text);
///       },
///     ),
///   ]),
/// )
/// ```
class TfTextFormField extends FormField<String> {
  /// 参数含义与 [TfTextField] 相同；[onFieldSubmitted] 对应按下回车。
  TfTextFormField({
    super.key,
    this.controller,
    String? initialValue,
    FocusNode? focusNode,
    String? placeholder,
    IconData? prefixIcon,
    IconData? suffixIcon,
    String? suffixTooltip,
    VoidCallback? onSuffixTap,
    bool obscureText = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    Iterable<String>? autofillHints,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onFieldSubmitted,
    super.validator,
    super.onSaved,
    super.enabled,
    AutovalidateMode? autovalidateMode,
  }) : assert(controller == null || initialValue == null),
       super(
         initialValue: controller?.text ?? initialValue ?? '',
         autovalidateMode: autovalidateMode ?? AutovalidateMode.onUnfocus,
         builder: (field) {
           final state = field as _TfTextFormFieldState;
           return TfTextField(
             controller: state._effectiveController,
             focusNode: focusNode,
             placeholder: placeholder,
             prefixIcon: prefixIcon,
             suffixIcon: suffixIcon,
             suffixTooltip: suffixTooltip,
             onSuffixTap: onSuffixTap,
             errorText: field.errorText,
             obscureText: obscureText,
             enabled: field.widget.enabled,
             maxLines: maxLines,
             keyboardType: keyboardType,
             textInputAction: textInputAction,
             autofillHints: autofillHints,
             onSubmitted: onFieldSubmitted,
             onChanged: (value) {
               field.didChange(value);
               onChanged?.call(value);
             },
           );
         },
       );

  /// 用于读写输入内容（可选）；不传时组件内部自行管理。
  final TextEditingController? controller;

  @override
  FormFieldState<String> createState() => _TfTextFormFieldState();
}

class _TfTextFormFieldState extends FormFieldState<String> {
  TextEditingController? _ownController;

  TfTextFormField get _field => widget as TfTextFormField;

  TextEditingController get _effectiveController =>
      _field.controller ?? (_ownController ??= TextEditingController(text: widget.initialValue));

  @override
  void initState() {
    super.initState();
    _effectiveController.addListener(_syncFromController);
  }

  @override
  void didUpdateWidget(TfTextFormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != _field.controller) {
      (oldWidget.controller ?? _ownController)?.removeListener(_syncFromController);
      _effectiveController.addListener(_syncFromController);
    }
  }

  @override
  void dispose() {
    _effectiveController.removeListener(_syncFromController);
    _ownController?.dispose();
    super.dispose();
  }

  @override
  void reset() {
    _effectiveController.text = widget.initialValue ?? '';
    super.reset();
  }

  void _syncFromController() {
    if (_effectiveController.text != value) didChange(_effectiveController.text);
  }
}

/// 密码输入框，右侧自带“显示 / 隐藏密码”按钮。
///
/// 它是一个 [TfTextFormField]，同样要放在 `Form` 里才能校验。
/// [placeholder] 默认为当前语言的“密码”。注册时请把 [autofillHints]
/// 设为 `[AutofillHints.newPassword]`，方便系统生成并保存新密码。
///
/// ```dart
/// TfPasswordField(
///   controller: _password,
///   validator: TfValidators.compose([v.required(), v.minLength(8)]),
///   onFieldSubmitted: (_) => submit(),
/// )
/// ```
class TfPasswordField extends StatefulWidget {
  const TfPasswordField({
    super.key,
    this.controller,
    this.placeholder,
    this.validator,
    this.textInputAction,
    this.autofillHints = const [AutofillHints.password],
    this.onChanged,
    this.onFieldSubmitted,
    this.enabled = true,
  });

  /// 用于读取密码（可选）。
  final TextEditingController? controller;

  /// 占位提示，默认为“密码”。
  final String? placeholder;

  /// 校验规则，参见 [TfValidators]。
  final FormFieldValidator<String>? validator;

  /// 键盘回车键的动作。
  final TextInputAction? textInputAction;

  /// 自动填充提示。
  final Iterable<String>? autofillHints;

  /// 每次输入变化时回调。
  final ValueChanged<String>? onChanged;

  /// 按下回车时回调，常用来直接提交表单。
  final ValueChanged<String>? onFieldSubmitted;

  /// 为 false 时禁止输入。
  final bool enabled;

  @override
  State<TfPasswordField> createState() => _TfPasswordFieldState();
}

class _TfPasswordFieldState extends State<TfPasswordField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    final strings = TfStrings.of(context);
    return TfTextFormField(
      controller: widget.controller,
      placeholder: widget.placeholder ?? strings.password,
      prefixIcon: Icons.lock_outline,
      suffixIcon: _obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
      suffixTooltip: _obscured ? strings.showPassword : strings.hidePassword,
      onSuffixTap: () => setState(() => _obscured = !_obscured),
      obscureText: _obscured,
      validator: widget.validator,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: widget.textInputAction,
      autofillHints: widget.autofillHints,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onFieldSubmitted,
      enabled: widget.enabled,
    );
  }
}
