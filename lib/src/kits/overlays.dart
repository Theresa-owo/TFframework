import 'package:flutter/material.dart';

import '../components/components.dart';
import '../design/design_system.dart';
import '../l10n/tf_strings.dart';

/// 显示自定义按钮的对话框，返回用户所选按钮的 [TfDialogAction.value]；
/// 点击遮罩关闭时返回 null。
///
/// 常见场景请优先使用 [showTfAlert]、[showTfConfirm]、[showTfInputDialog]。
/// [content] 可以放任意控件（例如表单），显示在 [message] 下方。
/// 某个按钮的 [TfDialogAction.beforeClose] 返回 false 时，对话框不会关闭。
/// [barrierDismissible] 为 false 时，点击遮罩不会关闭。
///
/// ```dart
/// final choice = await showTfDialog<String>(
///   context,
///   title: '保存修改？',
///   message: '你有未保存的修改。',
///   actions: const [
///     TfDialogAction(label: '不保存', value: 'discard', isDestructive: true),
///     TfDialogAction(label: '取消', value: 'cancel'),
///     TfDialogAction(label: '保存', value: 'save', isPrimary: true),
///   ],
/// );
/// ```
Future<T?> showTfDialog<T>(
  BuildContext context, {
  required String title,
  required List<TfDialogAction<T>> actions,
  String? message,
  Widget? content,
  bool barrierDismissible = true,
}) => TfDesign.of(context).showDialog<T>(
  context,
  title: title,
  message: message,
  content: content,
  actions: actions,
  barrierDismissible: barrierDismissible,
);

/// 提示框：只有一个“好”按钮，用户点击后关闭。
///
/// ```dart
/// await showTfAlert(context, title: '已保存', message: '修改已同步到云端。');
/// ```
Future<void> showTfAlert(BuildContext context, {required String title, String? message, String? buttonLabel}) =>
    showTfDialog<void>(
      context,
      title: title,
      message: message,
      actions: [TfDialogAction(label: buttonLabel ?? TfStrings.of(context).ok, isPrimary: true)],
    );

/// 确认框：用户点“确定”返回 true；点“取消”或关闭对话框返回 false。
///
/// 删除等不可撤销的操作请设 [destructive] 为 true，确认按钮会显示为警示色。
///
/// ```dart
/// if (await showTfConfirm(context, title: '删除这条记录？', confirmLabel: '删除', destructive: true)) {
///   await repository.delete(id);
/// }
/// ```
Future<bool> showTfConfirm(
  BuildContext context, {
  required String title,
  String? message,
  String? confirmLabel,
  String? cancelLabel,
  bool destructive = false,
}) async {
  final strings = TfStrings.of(context);
  final result = await showTfDialog<bool>(
    context,
    title: title,
    message: message,
    actions: [
      TfDialogAction(label: cancelLabel ?? strings.cancel, value: false),
      TfDialogAction(label: confirmLabel ?? strings.confirm, value: true, isPrimary: true, isDestructive: destructive),
    ],
  );
  return result ?? false;
}

/// 输入框对话框：让用户输入一行文字，返回输入内容；取消时返回 null。
///
/// 设置了 [validator] 时，校验不通过会在输入框下显示错误，对话框不会关闭。
///
/// ```dart
/// final name = await showTfInputDialog(
///   context,
///   title: '重命名',
///   initialValue: file.name,
///   validator: TfValidators.of(context).required(),
/// );
/// if (name != null) rename(file, name);
/// ```
Future<String?> showTfInputDialog(
  BuildContext context, {
  required String title,
  String? message,
  String? initialValue,
  String? placeholder,
  IconData? prefixIcon,
  FormFieldValidator<String>? validator,
  bool obscureText = false,
  TextInputType? keyboardType,
  String? confirmLabel,
}) async {
  final strings = TfStrings.of(context);
  final controller = TextEditingController(text: initialValue);
  final error = ValueNotifier<String?>(null);
  bool validate() {
    error.value = validator?.call(controller.text);
    return error.value == null;
  }

  try {
    final confirmed = await showTfDialog<bool>(
      context,
      title: title,
      message: message,
      content: ValueListenableBuilder<String?>(
        valueListenable: error,
        builder: (context, errorText, _) => TfTextField(
          controller: controller,
          placeholder: placeholder,
          prefixIcon: prefixIcon,
          errorText: errorText,
          obscureText: obscureText,
          keyboardType: keyboardType,
          onChanged: (_) {
            if (error.value != null) validate();
          },
        ),
      ),
      actions: [
        TfDialogAction(label: strings.cancel, value: false),
        TfDialogAction(label: confirmLabel ?? strings.ok, value: true, isPrimary: true, beforeClose: validate),
      ],
    );
    return confirmed ?? false ? controller.text : null;
  } finally {
    // The dialog's exit animation may still reference these for a frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.dispose();
      error.dispose();
    });
  }
}

/// 操作表：从屏幕底部弹出一组选项，返回所选项的 [TfSheetAction.value]；
/// 取消时返回 null。
///
/// ```dart
/// final action = await showTfActionSheet<String>(
///   context,
///   title: '分享照片',
///   actions: const [
///     TfSheetAction(label: '复制链接', value: 'copy', icon: Icons.link),
///     TfSheetAction(label: '删除', value: 'delete', icon: Icons.delete_outline, isDestructive: true),
///   ],
/// );
/// ```
Future<T?> showTfActionSheet<T>(
  BuildContext context, {
  required List<TfSheetAction<T>> actions,
  String? title,
  String? message,
}) => TfDesign.of(context).showActionSheet<T>(context, actions: actions, title: title, message: message);

/// 底部面板：从底部弹出，内容由 [builder] 自由构建，适合筛选、详情等。
///
/// 在面板内调用 `Navigator.pop(context, 值)` 可以关闭面板并返回这个值；
/// 用户下滑关闭时返回 null。内容较多时请用可滚动控件（如 `ListView`）。
///
/// ```dart
/// final sort = await showTfSheet<String>(
///   context,
///   title: '排序方式',
///   builder: (context) => ListView(children: [
///     TfListTile(title: const Text('最新'), onTap: () => Navigator.pop(context, 'newest')),
///     TfListTile(title: const Text('最热'), onTap: () => Navigator.pop(context, 'popular')),
///   ]),
/// );
/// ```
Future<T?> showTfSheet<T>(BuildContext context, {required WidgetBuilder builder, String? title}) =>
    TfDesign.of(context).showSheet<T>(context, builder: builder, title: title);

/// 轻提示：在屏幕上短暂显示一条消息，几秒后自动消失。
///
/// [type] 决定颜色和图标：信息、成功、警告、错误。
///
/// ```dart
/// showTfToast(context, '已复制到剪贴板', type: TfToastType.success);
/// ```
void showTfToast(BuildContext context, String message, {TfToastType type = TfToastType.info}) =>
    TfDesign.of(context).showToast(context, message: message, type: type);

/// 执行 [task] 期间显示全屏加载遮罩，任务结束后自动关闭，并返回任务结果。
///
/// 遮罩显示期间用户无法操作界面，也不能用返回键关闭。
/// [task] 抛出的异常会在遮罩关闭后原样抛给调用方。[message] 默认为“加载中…”。
///
/// ```dart
/// try {
///   final order = await runWithTfLoading(context, () => api.submitOrder(cart), message: '正在提交…');
///   showTfToast(context, '下单成功', type: TfToastType.success);
/// } on ApiException catch (e) {
///   showTfToast(context, e.message, type: TfToastType.error);
/// }
/// ```
Future<T> runWithTfLoading<T>(BuildContext context, Future<T> Function() task, {String? message}) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  final label = message ?? TfStrings.of(context).loading;
  final route = DialogRoute<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => PopScope(
      canPop: false,
      child: Center(child: _LoadingPanel(message: label)),
    ),
  );
  navigator.push(route);
  try {
    return await task();
  } finally {
    if (route.isActive) navigator.removeRoute(route);
  }
}

class _LoadingPanel extends StatelessWidget {
  const _LoadingPanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      label: message,
      child: Container(
        constraints: const BoxConstraints(minWidth: 160),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHigh.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(blurRadius: 24, color: Color(0x33000000))],
        ),
        child: TfSurfaceScope(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const TfProgress.circular(),
              const SizedBox(height: 16),
              Text(message, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}
