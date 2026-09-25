# tf_framework 使用示例

本包是纯框架，不包含可运行的界面程序。下面是在你自己的 Flutter 应用中使用它的完整示例。

## 1. 引用框架

在应用的 `pubspec.yaml` 中添加：

```yaml
dependencies:
  tf_framework:
    path: ../TFframework        # 本地路径
  # 或者从 Git 仓库引用：
  # tf_framework:
  #   git:
  #     url: https://github.com/Theresa-owo/TFframework.git
  #     ref: v0.3.0
```

## 2. 启动应用

```dart
import 'package:flutter/material.dart';
import 'package:tf_framework/tf_framework.dart';

abstract final class AppKeys {
  static const nickname = TfPreferenceKey<String>('app.nickname', defaultValue: '');
  static const notifications = TfPreferenceKey<bool>('app.notifications', defaultValue: true);
}

Future<void> main() async {
  final framework = await TfFramework.initialize(
    designSystems: const [Material3DesignSystem(), LiquidGlassDesignSystem()],
    settingsBuilder: (context) => [
      TfSettingsSection(
        title: '账号',
        settings: [
          TfTextSetting(key: AppKeys.nickname, title: '昵称', icon: Icons.person_outline),
          TfToggleSetting(key: AppKeys.notifications, title: '通知', icon: Icons.notifications_outlined),
        ],
      ),
    ],
  );
  runApp(TfApp(framework: framework, title: '我的应用', home: const LoginPage()));
}
```

## 3. 登录页

```dart
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) => TfScaffold(
    body: TfAuthLayout(
      title: '欢迎回来',
      child: TfLoginForm(
        onSubmit: (credentials) async {
          final ok = await myApi.signIn(credentials.identifier, credentials.password);
          if (!ok) throw const TfAuthException('账号或密码错误');
          if (context.mounted) {
            Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomePage()));
          }
        },
        onForgotPassword: () {},
        onSignUp: () {},
      ),
    ),
  );
}
```

## 4. 主页：导航、组件、对话框

```dart
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) => TfScaffold(
    title: _tab == 0 ? '首页' : '设置',
    selectedIndex: _tab,
    onDestinationSelected: (i) => setState(() => _tab = i),
    destinations: const [
      TfNavDestination(icon: Icons.home_outlined, selectedIcon: Icons.home, label: '首页'),
      TfNavDestination(icon: Icons.settings_outlined, selectedIcon: Icons.settings, label: '设置'),
    ],
    body: _tab == 0 ? const _Home() : const TfSettingsList(),
  );
}

class _Home extends StatelessWidget {
  const _Home();

  @override
  Widget build(BuildContext context) => TfListView(
    children: [
      TfCard(child: Text('当前组件库：${TfDesign.of(context).displayName}')),
      TfButton(
        label: '删除全部',
        icon: Icons.delete_outline,
        onPressed: () async {
          if (await showTfConfirm(context, title: '确定删除？', destructive: true)) {
            await runWithTfLoading(context, myApi.deleteAll);
            if (context.mounted) showTfToast(context, '已删除', type: TfToastType.success);
          }
        },
      ),
    ],
  );
}
```

## 5. 读写偏好

```dart
final prefs = TfFramework.of(context).preferences;
final name = prefs.get(AppKeys.nickname);
await prefs.set(AppKeys.nickname, '张三');
await TfFramework.of(context).switchDesignSystem(LiquidGlassDesignSystem.systemId);
```
