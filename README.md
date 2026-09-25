# tf_framework

一个纯 Flutter 组件框架（类库），不包含可运行的界面程序。

应用代码只使用 `Tf*` 组件，底层组件库可以在运行时于 **Material 3** 和
**液态玻璃**（[liquid_glass_widgets](https://pub.dev/packages/liquid_glass_widgets)）
之间切换。框架还提供登录注册、对话框、状态页等常用套件，中英文本地化，以及
统一管理的偏好设置和自动生成的设置页。

每个公开的类、方法和参数都有中文使用说明和示例代码，在 IDE 中把鼠标悬停在
名称上即可查看。

## 在应用中引用

```yaml
# 你的应用的 pubspec.yaml
dependencies:
  tf_framework:
    path: ../TFframework          # 本地路径
  # 或直接从 GitHub 引用：
  # tf_framework:
  #   git: { url: https://github.com/Theresa-owo/TFframework.git, ref: v0.3.0 }
```

```dart
import 'package:tf_framework/tf_framework.dart';

Future<void> main() async {
  final framework = await TfFramework.initialize(
    designSystems: const [Material3DesignSystem(), LiquidGlassDesignSystem()],
  );
  runApp(TfApp(framework: framework, home: const HomePage()));
}
```

完整示例见 [example/example.md](example/example.md)。

## 功能一览

| 分类 | API |
|---|---|
| 布局 | `TfScaffold`（窄屏底部导航，Material 宽屏自动侧边导航）、`TfListView`、`TfCard`、`TfSection`、`TfListTile` |
| 控件 | `TfButton`（加载中 / 撑满宽度）、`TfIconButton`、`TfSwitch`、`TfCheckbox`、`TfSlider`、`TfSegmentedControl`、`TfChip`、`TfProgress`、`TfTextField` |
| 表单 | `TfTextFormField`、`TfPasswordField`、`TfValidators`（必填、邮箱、手机、长度、正则、一致、组合） |
| 登录注册 | `TfLoginForm`、`TfSignUpForm`、`TfAuthLayout`、`TfAuthException` |
| 对话框 | `showTfAlert`、`showTfConfirm`、`showTfInputDialog`、`showTfDialog`、`showTfActionSheet`、`showTfSheet`、`showTfToast`、`runWithTfLoading` |
| 状态 | `TfBanner`、`TfEmptyState`、`TfErrorState`、`TfLoadingState`、`TfStatusView`、`TfAsyncBuilder`、`TfAvatar` |
| 设置页 | `TfSettingsPage` / `TfSettingsList`；设置项：开关、单选、滑块、颜色、文本、跳转、信息、操作、语言、组件库 |
| 偏好 | `TfPreferenceKey`、`TfEnumPreference`、`TfPreferencesController`、`TfSharedPreferenceStore`、`TfMemoryPreferenceStore` |
| 本地化 | `TfStrings`（`TfStringsEn`、`TfStringsZh`），可通过 `TfApp.strings` 覆盖或新增语言 |
| 扩展 | `TfDesignSystem`（接入新组件库）、`TfSetting`（新设置项类型）、`TfPreferenceStore`（新存储后端） |

## 目录结构

```
lib/
  tf_framework.dart     唯一的对外入口，导出全部公开 API
  src/                  内部实现，应用不应直接 import
    app/                TfFramework（总入口）、TfApp（根控件）
    components/         基础组件，每个都委托给当前组件库
    design/             组件库接口、外观参数
      systems/          Material 3 与液态玻璃两个实现
    kits/               表单、登录注册、对话框、状态页（只用基础组件搭建）
    settings/           声明式设置项与自动设置页
    preferences/        偏好定义、读写控制器、存储后端
    l10n/               中英文文案
test/                   单元测试与组件测试
```

## 设计要点

- **不依赖具体组件库**：`Tf*` 组件通过 `TfDesign.of(context)` 调用当前组件库。
  切换组件库时所有页面自动更新，页面栈保持不变。
- **避免玻璃叠玻璃**：卡片、分组、对话框、面板内的控件会被标记为“表面内”，
  液态玻璃在这些地方改用扁平的 Cupertino 控件。
- **偏好集中存储**：所有偏好以一个 JSON 保存在 shared_preferences 的
  `tf_framework.preferences` 键下，不影响应用自己的数据；无效值自动回退默认值，
  连续写入会合并保存。

## 测试

```
flutter test
```

在自己的组件测试中请使用 `TfMemoryPreferenceStore` 和
`LiquidGlassDesignSystem(warmUpShaders: false)`，因为测试环境加载不到依赖包的着色器。

## 已知问题

`dart doc`（dartdoc 9.0.6）在生成 HTML 文档时会崩溃（`RangeError`，读取了超出源文件长度的偏移）。
这是工具本身的问题，与注释内容无关，不影响 IDE 中显示文档，也不影响编译和测试。
