import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../design/design_system.dart';

/// 页面骨架：顶栏 + 页面内容 + 可选的导航栏。
///
/// 所有页面都应使用它代替 `Scaffold` / `GlassScaffold`，这样切换组件库时
/// 页面结构会自动跟着变。设置了 [destinations] 时显示导航：窄屏为底部导航栏，
/// Material 3 在宽窗口（桌面）下自动改为侧边导航栏。
/// 液态玻璃模式下，从其他页面推入时会自动显示返回按钮。
///
/// ```dart
/// TfScaffold(
///   title: '首页',
///   actions: [TfIconButton(icon: Icons.search, onPressed: search)],
///   destinations: const [
///     TfNavDestination(icon: Icons.home_outlined, selectedIcon: Icons.home, label: '首页'),
///     TfNavDestination(icon: Icons.settings_outlined, label: '设置'),
///   ],
///   selectedIndex: _tab,
///   onDestinationSelected: (i) => setState(() => _tab = i),
///   body: const TfListView(children: [...]),
/// )
/// ```
class TfScaffold extends StatelessWidget {
  const TfScaffold({
    super.key,
    required this.body,
    this.title,
    this.leading,
    this.actions = const [],
    this.destinations,
    this.selectedIndex = 0,
    this.onDestinationSelected,
  });

  /// 页面内容。推荐使用 [TfListView]，它会自动避开顶栏和导航栏。
  final Widget body;

  /// 顶栏标题。[title]、[leading]、[actions] 都为空时不显示顶栏。
  final String? title;

  /// 顶栏左侧控件；为空时由组件库决定（例如返回按钮）。
  final Widget? leading;

  /// 顶栏右侧的操作按钮，通常是 [TfIconButton]。
  final List<Widget> actions;

  /// 导航项；为 null 时不显示导航栏。
  final List<TfNavDestination>? destinations;

  /// 当前选中的导航项下标。
  final int selectedIndex;

  /// 用户点击导航项时回调，参数为下标。
  final ValueChanged<int>? onDestinationSelected;

  @override
  Widget build(BuildContext context) => TfDesign.of(context).scaffold(
    context,
    body: body,
    title: title,
    leading: leading,
    actions: actions,
    destinations: destinations,
    selectedIndex: selectedIndex,
    onDestinationSelected: onDestinationSelected,
  );
}

/// 可滚动的页面内容列表，[TfScaffold.body] 的首选。
///
/// - 自动留出顶栏、导航栏和系统安全区的空间（液态玻璃的栏是悬浮的，
///   也不会被遮住）。
/// - 子项之间自动插入 [spacing] 间距。
/// - 窗口宽于 [maxWidth] 时内容居中并限制宽度，桌面上更易读。
///
/// ```dart
/// TfListView(
///   children: [
///     TfCard(child: Text('欢迎')),
///     TfSection(title: '账号', children: [...]),
///   ],
/// )
/// ```
class TfListView extends StatelessWidget {
  const TfListView({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.all(16),
    this.spacing = 16,
    this.maxWidth = 720,
    this.controller,
  });

  /// 从上到下排列的内容。
  final List<Widget> children;

  /// 额外内边距，叠加在栏和安全区的空间之上。
  final EdgeInsets padding;

  /// 相邻子项之间的垂直间距。
  final double spacing;

  /// 内容最大宽度；为 null 时不限制。
  final double? maxWidth;

  /// 可选的滚动控制器。
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final extra = maxWidth == null || constraints.maxWidth <= maxWidth!
          ? 0.0
          : (constraints.maxWidth - maxWidth!) / 2;
      return ListView.separated(
        controller: controller,
        padding: MediaQuery.paddingOf(context) + padding + EdgeInsets.symmetric(horizontal: extra),
        itemCount: children.length,
        itemBuilder: (context, index) => children[index],
        separatorBuilder: (context, index) => SizedBox(height: spacing),
      );
    },
  );
}

/// 按钮，有主要、次要、文字三种样式。
///
/// - `TfButton(...)`：主要操作，最醒目。
/// - `TfButton.secondary(...)`：次要操作，带边框或浅色玻璃。
/// - `TfButton.text(...)`：最轻量，适合“忘记密码？”这类链接式操作。
///
/// [onPressed] 为 null 时按钮禁用。[loading] 为 true 时显示转圈并忽略点击，
/// 适合提交表单；[expanded] 为 true 时撑满可用宽度。
///
/// ```dart
/// TfButton(label: '保存', icon: Icons.check, onPressed: save)
/// TfButton(label: '登录', expanded: true, loading: _submitting, onPressed: submit)
/// TfButton.text(label: '忘记密码？', onPressed: forgot)
/// ```
class TfButton extends StatelessWidget {
  /// 主要按钮。
  const TfButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = TfButtonVariant.primary,
    this.loading = false,
    this.expanded = false,
  });

  /// 次要按钮。
  const TfButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expanded = false,
  }) : variant = TfButtonVariant.secondary;

  /// 文字按钮。
  const TfButton.text({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expanded = false,
  }) : variant = TfButtonVariant.text;

  /// 按钮文字。
  final String label;

  /// 点击回调；为 null 时按钮禁用。
  final VoidCallback? onPressed;

  /// 文字前的图标（可选）。
  final IconData? icon;

  /// 样式，一般通过命名构造函数指定。
  final TfButtonVariant variant;

  /// 为 true 时显示加载动画并忽略点击。
  final bool loading;

  /// 为 true 时撑满可用宽度。
  final bool expanded;

  @override
  Widget build(BuildContext context) => TfDesign.of(context).button(
    context,
    label: label,
    onPressed: onPressed,
    icon: icon,
    variant: variant,
    loading: loading,
    expanded: expanded,
  );
}

/// 只有图标的按钮，常用于顶栏操作。
///
/// 请务必填写 [tooltip]：它既是鼠标悬停提示，也是读屏软件朗读的文字。
///
/// ```dart
/// TfIconButton(icon: Icons.search, tooltip: '搜索', onPressed: openSearch)
/// ```
class TfIconButton extends StatelessWidget {
  const TfIconButton({super.key, required this.icon, required this.onPressed, this.tooltip});

  /// 图标。
  final IconData icon;

  /// 点击回调；为 null 时禁用。
  final VoidCallback? onPressed;

  /// 提示文字和无障碍标签。
  final String? tooltip;

  @override
  Widget build(BuildContext context) =>
      TfDesign.of(context).iconButton(context, icon: icon, onPressed: onPressed, tooltip: tooltip);
}

/// 卡片：把一组相关内容放在同一块背景上。
///
/// 设置 [onTap] 后整张卡片可点击。
/// 卡片内的控件会自动改用“表面内”样式：液态玻璃模式下，卡片里的开关、
/// 按钮、输入框会使用扁平的 Cupertino 控件，避免玻璃叠玻璃造成失真。
///
/// ```dart
/// TfCard(
///   onTap: openProfile,
///   child: Row(children: [TfAvatar(name: '张三'), SizedBox(width: 12), Text('张三')]),
/// )
/// ```
class TfCard extends StatelessWidget {
  const TfCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.onTap});

  /// 卡片内容。
  final Widget child;

  /// 内容与卡片边缘的间距。
  final EdgeInsetsGeometry padding;

  /// 点击卡片时回调（可选）。
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) =>
      TfDesign.of(context).card(context, padding: padding, onTap: onTap, child: child);
}

/// 分组列表：带标题的一组行，行与行之间自动加分隔线。
///
/// 子项通常是 [TfListTile]，风格类似系统设置页的分组。
/// 和 [TfCard] 一样，分组内的控件使用“表面内”样式。
///
/// ```dart
/// TfSection(
///   title: '通用',
///   footer: '修改后立即生效。',
///   children: [
///     TfListTile(title: Text('通知'), trailing: TfSwitch(value: on, onChanged: setOn)),
///     TfListTile(title: Text('关于'), onTap: openAbout),
///   ],
/// )
/// ```
class TfSection extends StatelessWidget {
  const TfSection({super.key, required this.children, this.title, this.footer});

  /// 分组里的行。
  final List<Widget> children;

  /// 分组上方的标题（可选）。
  final String? title;

  /// 分组下方的说明文字（可选）。
  final String? footer;

  @override
  Widget build(BuildContext context) =>
      TfDesign.of(context).section(context, title: title, footer: footer, children: children);
}

/// 列表行：左侧图标、标题、副标题、右侧附加控件。
///
/// 放在 [TfSection] 里效果最好，也可以单独使用。设置 [onTap] 后整行可点击。
///
/// ```dart
/// TfListTile(
///   leading: const Icon(Icons.person_outline),
///   title: const Text('个人资料'),
///   subtitle: const Text('头像、昵称'),
///   trailing: const Icon(Icons.chevron_right),
///   onTap: openProfile,
/// )
/// ```
class TfListTile extends StatelessWidget {
  const TfListTile({super.key, required this.title, this.subtitle, this.leading, this.trailing, this.onTap});

  /// 标题，通常是 `Text`。
  final Widget title;

  /// 标题下方的副标题（可选）。
  final Widget? subtitle;

  /// 左侧控件，通常是 `Icon` 或 `TfAvatar`。
  final Widget? leading;

  /// 右侧控件，例如 [TfSwitch]、箭头图标或当前值文字。
  final Widget? trailing;

  /// 点击整行时回调（可选）。
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) =>
      TfDesign.of(context)
          .listTile(context, title: title, subtitle: subtitle, leading: leading, trailing: trailing, onTap: onTap);
}

/// 开关，用于立即生效的“开 / 关”选项。
///
/// 组件本身不保存状态：你需要保存 [value]，并在 [onChanged] 里更新它。
/// 如果要把值保存为偏好设置，请直接使用 `TfToggleSetting`。
///
/// ```dart
/// TfSwitch(value: _wifi, onChanged: (v) => setState(() => _wifi = v))
/// ```
class TfSwitch extends StatelessWidget {
  const TfSwitch({super.key, required this.value, required this.onChanged});

  /// 当前是否打开。
  final bool value;

  /// 用户切换时回调；为 null 时禁用。
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) => TfDesign.of(context).toggle(context, value: value, onChanged: onChanged);
}

/// 复选框，可在右侧附带一个可点击的标签。
///
/// 适合需要用户确认的选项，例如“记住我”“同意条款”。
/// 点击 [label] 与点击方框效果相同。
///
/// ```dart
/// TfCheckbox(
///   value: _agree,
///   onChanged: (v) => setState(() => _agree = v),
///   label: const Text('我已阅读并同意服务条款'),
/// )
/// ```
class TfCheckbox extends StatelessWidget {
  const TfCheckbox({super.key, required this.value, required this.onChanged, this.label});

  /// 是否勾选。
  final bool value;

  /// 用户切换时回调；为 null 时禁用。
  final ValueChanged<bool>? onChanged;

  /// 方框右侧的标签（可选）。
  final Widget? label;

  @override
  Widget build(BuildContext context) {
    final box = TfDesign.of(context).checkbox(context, value: value, onChanged: onChanged);
    if (label == null) return box;
    return MergeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          box,
          const SizedBox(width: 4),
          Flexible(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onChanged == null ? null : () => onChanged!(!value),
              child: label,
            ),
          ),
        ],
      ),
    );
  }
}

/// 滑块，用于在一个连续范围内取值，例如音量、亮度。
///
/// 超出 [min]～[max] 的 [value] 会被自动截断到范围内。设置 [divisions] 后
/// 只能停在等分点上，例如 `divisions: 4` 表示只能取 5 个值。
///
/// ```dart
/// TfSlider(value: _volume, onChanged: (v) => setState(() => _volume = v))
/// TfSlider(value: _size, min: 12, max: 24, divisions: 6, onChanged: setSize)
/// ```
class TfSlider extends StatelessWidget {
  const TfSlider({super.key, required this.value, required this.onChanged, this.min = 0, this.max = 1, this.divisions});

  /// 当前值。
  final double value;

  /// 拖动时持续回调；为 null 时禁用。
  final ValueChanged<double>? onChanged;

  /// 最小值。
  final double min;

  /// 最大值。
  final double max;

  /// 等分数；为 null 时可连续取值。
  final int? divisions;

  @override
  Widget build(BuildContext context) => TfDesign.of(context)
      .slider(context, value: value.clamp(min, max), onChanged: onChanged, min: min, max: max, divisions: divisions);
}

/// 单个输入框。
///
/// 这个组件不做校验，需要自己传入 [errorText]。在表单里需要校验时，
/// 请改用 `TfTextFormField`；输入密码请用 `TfPasswordField`。
///
/// 设置 [suffixIcon] 和 [onSuffixTap] 可以在右侧放一个可点击的图标，
/// 例如“清空”；[suffixTooltip] 是它的提示文字。
///
/// ```dart
/// final _search = TextEditingController();
///
/// TfTextField(
///   controller: _search,
///   placeholder: '搜索',
///   prefixIcon: Icons.search,
///   suffixIcon: Icons.clear,
///   suffixTooltip: '清空',
///   onSuffixTap: _search.clear,
///   textInputAction: TextInputAction.search,
///   onSubmitted: runSearch,
/// )
/// ```
class TfTextField extends StatelessWidget {
  const TfTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.placeholder,
    this.prefixIcon,
    this.suffixIcon,
    this.suffixTooltip,
    this.onSuffixTap,
    this.errorText,
    this.obscureText = false,
    this.enabled = true,
    this.maxLines = 1,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.onChanged,
    this.onSubmitted,
  });

  /// 用于读写输入内容；由调用方创建并负责 `dispose`。
  final TextEditingController? controller;

  /// 用于控制焦点（可选）。
  final FocusNode? focusNode;

  /// 占位提示。Material 3 下会显示为浮动标签。
  final String? placeholder;

  /// 左侧图标（可选）。
  final IconData? prefixIcon;

  /// 右侧可点击图标（可选）。
  final IconData? suffixIcon;

  /// 右侧图标的提示和无障碍标签。
  final String? suffixTooltip;

  /// 点击右侧图标时回调。
  final VoidCallback? onSuffixTap;

  /// 不为 null 时输入框显示为错误状态，并在下方显示这段文字。
  final String? errorText;

  /// 为 true 时以圆点隐藏输入内容。
  final bool obscureText;

  /// 为 false 时禁止输入。
  final bool enabled;

  /// 最多显示的行数；大于 1 时可输入多行。
  final int maxLines;

  /// 键盘类型，例如 `TextInputType.emailAddress`。
  final TextInputType? keyboardType;

  /// 键盘回车键的动作，例如“下一项”“完成”。
  final TextInputAction? textInputAction;

  /// 自动填充提示，例如 `[AutofillHints.email]`，让系统填入已保存的账号密码。
  final Iterable<String>? autofillHints;

  /// 每次输入变化时回调。
  final ValueChanged<String>? onChanged;

  /// 按下键盘回车时回调。
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) => TfDesign.of(context).textField(
    context,
    controller: controller,
    focusNode: focusNode,
    placeholder: placeholder,
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    suffixTooltip: suffixTooltip,
    onSuffixTap: onSuffixTap,
    errorText: errorText,
    obscureText: obscureText,
    enabled: enabled,
    maxLines: maxLines,
    keyboardType: keyboardType,
    textInputAction: textInputAction,
    autofillHints: autofillHints,
    onChanged: onChanged,
    onSubmitted: onSubmitted,
  );
}

/// 分段选择器：在 2～5 个互斥选项中选一个，例如“日 / 周 / 月”。
///
/// 泛型 `T` 是选项值的类型，可以是字符串、枚举等。
///
/// ```dart
/// TfSegmentedControl<String>(
///   selected: _period,
///   onChanged: (v) => setState(() => _period = v),
///   segments: const [
///     TfSegment(value: 'day', label: '日'),
///     TfSegment(value: 'week', label: '周'),
///     TfSegment(value: 'month', label: '月'),
///   ],
/// )
/// ```
class TfSegmentedControl<T> extends StatelessWidget {
  const TfSegmentedControl({super.key, required this.segments, required this.selected, required this.onChanged});

  /// 所有选项，每项至少要有文字或图标之一。
  final List<TfSegment<T>> segments;

  /// 当前选中的值。
  final T selected;

  /// 用户选择时回调；为 null 时禁用。
  final ValueChanged<T>? onChanged;

  @override
  Widget build(BuildContext context) =>
      TfDesign.of(context).segmented<T>(context, segments: segments, selected: selected, onChanged: onChanged);
}

/// 标签（Chip），适合做筛选条件或多选标签。
///
/// ```dart
/// Wrap(
///   spacing: 8,
///   children: [
///     for (final tag in tags)
///       TfChip(label: tag, selected: _selected.contains(tag), onTap: () => toggle(tag)),
///   ],
/// )
/// ```
class TfChip extends StatelessWidget {
  const TfChip({super.key, required this.label, this.icon, this.selected = false, this.onTap});

  /// 标签文字。
  final String label;

  /// 文字前的图标（可选）。
  final IconData? icon;

  /// 是否处于选中状态。
  final bool selected;

  /// 点击时回调（可选）。
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) =>
      TfDesign.of(context).chip(context, label: label, icon: icon, selected: selected, onTap: onTap);
}

/// 进度条，有横条和圆形两种。
///
/// [value] 为 0～1 时显示具体进度；为 null 时显示不确定进度的循环动画。
///
/// ```dart
/// TfProgress(value: downloaded / total)   // 横条，显示具体进度
/// const TfProgress.circular()             // 圆形转圈
/// ```
class TfProgress extends StatelessWidget {
  /// 横条进度。
  const TfProgress({super.key, this.value}) : circular = false;

  /// 圆形进度。
  const TfProgress.circular({super.key, this.value}) : circular = true;

  /// 0～1 之间的进度；为 null 时为不确定进度。
  final double? value;

  /// 是否为圆形。
  final bool circular;

  @override
  Widget build(BuildContext context) => TfDesign.of(context).progress(context, value: value, circular: circular);
}
