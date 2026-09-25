import 'package:flutter/material.dart';

import '../components/components.dart';
import '../design/design_system.dart';
import '../l10n/tf_strings.dart';

/// 页面内的横幅提示，例如表单顶部的错误信息或页面顶部的通知。
///
/// 与 `showTfToast` 不同，横幅会一直显示，直到你把它从界面上移除。
/// 设置 [onClose] 后右侧会出现关闭按钮。
///
/// ```dart
/// if (_error != null)
///   TfBanner(
///     message: _error!,
///     type: TfToastType.error,
///     onClose: () => setState(() => _error = null),
///   ),
/// ```
class TfBanner extends StatelessWidget {
  const TfBanner({super.key, required this.message, this.type = TfToastType.info, this.icon, this.onClose});

  /// 提示文字。
  final String message;

  /// 类型，决定颜色和默认图标。
  final TfToastType type;

  /// 自定义图标（可选）。
  final IconData? icon;

  /// 点击关闭按钮时回调；为 null 时不显示关闭按钮。
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (background, foreground, defaultIcon) = switch (type) {
      TfToastType.error => (colors.errorContainer, colors.onErrorContainer, Icons.error_outline),
      TfToastType.warning => (colors.tertiaryContainer, colors.onTertiaryContainer, Icons.warning_amber_rounded),
      TfToastType.success => (colors.primaryContainer, colors.onPrimaryContainer, Icons.check_circle_outline),
      TfToastType.info => (colors.secondaryContainer, colors.onSecondaryContainer, Icons.info_outline),
    };
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Icon(icon ?? defaultIcon, color: foreground, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message, style: TextStyle(color: foreground)),
            ),
            if (onClose != null)
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                color: foreground,
                visualDensity: VisualDensity.compact,
                tooltip: TfStrings.of(context).close,
                onPressed: onClose,
              )
            else
              const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}

/// 通用的居中状态页：大图标 + 标题 + 说明 + 可选按钮。
///
/// [TfEmptyState]、[TfErrorState] 都基于它。需要其他状态时可以直接使用，
/// 例如“无网络”“无权限”。
///
/// ```dart
/// TfStatusView(
///   icon: Icons.lock_outline,
///   title: '没有访问权限',
///   message: '请联系管理员开通。',
///   action: TfButton(label: '申请权限', onPressed: request),
/// )
/// ```
class TfStatusView extends StatelessWidget {
  const TfStatusView({super.key, required this.icon, required this.title, this.message, this.action});

  /// 大图标。
  final IconData icon;

  /// 标题。
  final String title;

  /// 说明文字（可选）。
  final String? message;

  /// 下方的按钮等操作（可选）。
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: MediaQuery.paddingOf(context) + const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 56, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(height: 16),
              Text(title, style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
              if (message != null) ...[
                const SizedBox(height: 8),
                Text(
                  message!,
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ],
              if (action != null) ...[const SizedBox(height: 24), action!],
            ],
          ),
        ),
      ),
    );
  }
}

/// 空状态页：列表或搜索结果为空时显示。
///
/// [title] 默认为当前语言的“暂无内容”。可以放一个 [action] 引导用户操作。
///
/// ```dart
/// items.isEmpty
///     ? TfEmptyState(
///         message: '还没有收藏任何内容',
///         action: TfButton(label: '去逛逛', onPressed: browse),
///       )
///     : buildList(items)
/// ```
class TfEmptyState extends StatelessWidget {
  const TfEmptyState({super.key, this.icon = Icons.inbox_outlined, this.title, this.message, this.action});

  /// 大图标，默认为收件箱图标。
  final IconData icon;

  /// 标题，默认为“暂无内容”。
  final String? title;

  /// 说明文字（可选）。
  final String? message;

  /// 引导用户的操作（可选）。
  final Widget? action;

  @override
  Widget build(BuildContext context) =>
      TfStatusView(icon: icon, title: title ?? TfStrings.of(context).emptyTitle, message: message, action: action);
}

/// 错误状态页：加载失败时显示，可带“重试”按钮。
///
/// [title]、[message] 默认为当前语言的通用错误文案；设置 [onRetry] 后显示重试按钮。
///
/// ```dart
/// TfErrorState(message: '网络连接失败', onRetry: reload)
/// ```
class TfErrorState extends StatelessWidget {
  const TfErrorState({super.key, this.title, this.message, this.onRetry});

  /// 标题，默认为“出错了”。
  final String? title;

  /// 说明文字，默认为通用错误提示。
  final String? message;

  /// 点击“重试”时回调；为 null 时不显示按钮。
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final strings = TfStrings.of(context);
    return TfStatusView(
      icon: Icons.cloud_off_outlined,
      title: title ?? strings.errorTitle,
      message: message ?? strings.somethingWentWrong,
      action: onRetry == null
          ? null
          : TfButton.secondary(label: strings.retry, icon: Icons.refresh, onPressed: onRetry),
    );
  }
}

/// 加载状态页：居中的转圈动画，可带一行说明文字。
///
/// ```dart
/// const TfLoadingState(message: '正在同步…')
/// ```
class TfLoadingState extends StatelessWidget {
  const TfLoadingState({super.key, this.message});

  /// 转圈下方的说明文字（可选）。
  final String? message;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const TfProgress.circular(),
        if (message != null) ...[const SizedBox(height: 16), Text(message!)],
      ],
    ),
  );
}

/// 异步加载数据，并自动在“加载中 / 出错 / 空数据 / 有数据”四种状态间切换。
///
/// - 加载中：显示 [loading]，默认为 [TfLoadingState]。
/// - 出错：显示 [TfErrorState]，带“重试”按钮；[errorMessage] 可把异常转成提示文字。
/// - 空数据：[isEmpty] 返回 true 时显示 [empty]，默认为 [TfEmptyState]。
/// - 有数据：调用 [builder]。
///
/// 需要手动刷新时（例如下拉刷新、提交后刷新），用 `GlobalKey` 调用
/// [TfAsyncBuilderState.reload]。
///
/// ```dart
/// final _orders = GlobalKey<TfAsyncBuilderState<List<Order>>>();
///
/// TfAsyncBuilder<List<Order>>(
///   key: _orders,
///   load: api.fetchOrders,
///   isEmpty: (orders) => orders.isEmpty,
///   errorMessage: (e) => e is ApiException ? e.message : null,
///   builder: (context, orders) => TfListView(
///     children: [for (final o in orders) TfListTile(title: Text(o.title))],
///   ),
/// )
///
/// // 刷新：
/// _orders.currentState?.reload();
/// ```
class TfAsyncBuilder<T> extends StatefulWidget {
  const TfAsyncBuilder({
    super.key,
    required this.load,
    required this.builder,
    this.isEmpty,
    this.empty,
    this.loading,
    this.errorMessage,
  });

  /// 加载数据的函数，每次加载或重试都会调用。
  final Future<T> Function() load;

  /// 数据加载成功后构建界面。
  final Widget Function(BuildContext context, T data) builder;

  /// 返回 true 时显示 [empty]（默认为 [TfEmptyState]）。
  final bool Function(T data)? isEmpty;

  /// 空数据时显示的控件。
  final Widget? empty;

  /// 加载中显示的控件。
  final Widget? loading;

  /// 把加载异常转换成给用户看的文字；返回 null 时使用通用错误文案。
  final String? Function(Object error)? errorMessage;

  @override
  State<TfAsyncBuilder<T>> createState() => TfAsyncBuilderState<T>();
}

/// [TfAsyncBuilder] 的状态，通过 `GlobalKey` 获取后可调用 [reload]。
class TfAsyncBuilderState<T> extends State<TfAsyncBuilder<T>> {
  late Future<T> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.load();
  }

  /// 重新调用 [TfAsyncBuilder.load] 加载数据。
  void reload() => setState(() {
    _future = widget.load();
  });

  @override
  Widget build(BuildContext context) => FutureBuilder<T>(
    future: _future,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return widget.loading ?? const TfLoadingState();
      }
      if (snapshot.hasError) {
        return TfErrorState(message: widget.errorMessage?.call(snapshot.error!), onRetry: reload);
      }
      final data = snapshot.data as T;
      if (widget.isEmpty?.call(data) ?? false) return widget.empty ?? const TfEmptyState();
      return widget.builder(context, data);
    },
  );
}

/// 圆形头像：有图片时显示图片，否则显示 [name] 的首字母。
///
/// 英文名取首尾两个单词的首字母（`Ada Lovelace` → `AL`），
/// 单个词取前两个字（`张三` → `张三`）。[name] 同时作为无障碍标签。
///
/// ```dart
/// TfAvatar(name: user.name, image: NetworkImage(user.avatarUrl), size: 48)
/// ```
class TfAvatar extends StatelessWidget {
  const TfAvatar({super.key, required this.name, this.image, this.size = 40});

  /// 用户名，用于生成首字母和无障碍标签。
  final String name;

  /// 头像图片（可选）；加载失败时回退为首字母。
  final ImageProvider? image;

  /// 直径。
  final double size;

  /// 头像上显示的首字母。
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.take(2).toString().toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label: name,
      image: true,
      child: CircleAvatar(
        radius: size / 2,
        backgroundColor: colors.primaryContainer,
        foregroundColor: colors.onPrimaryContainer,
        foregroundImage: image,
        child: Text(
          initials,
          style: TextStyle(fontSize: size * 0.38, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
