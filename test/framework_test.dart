import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tf_framework/tf_framework.dart';

/// A minimal design system used to prove that switching swaps every
/// component and keeps navigation state.
class _PlainDesignSystem extends Material3DesignSystem {
  const _PlainDesignSystem();

  @override
  String get id => 'plain';

  @override
  String get displayName => 'Plain';

  @override
  Widget wrapApp(BuildContext context, TfAppearance appearance, TfPreferencesController preferences, Widget child) =>
      ColoredBox(color: Colors.transparent, child: child);

  @override
  Widget button(
    BuildContext context, {
    required String label,
    required VoidCallback? onPressed,
    IconData? icon,
    TfButtonVariant variant = TfButtonVariant.primary,
    bool loading = false,
    bool expanded = false,
  }) => GestureDetector(onTap: onPressed, child: Text('[$label]'));
}

Future<TfFramework> _framework({Map<String, Object>? values}) => TfFramework.initialize(
  designSystems: const [Material3DesignSystem(), _PlainDesignSystem()],
  store: TfMemoryPreferenceStore(values),
);

void main() {
  testWidgets('components render through the active design system', (tester) async {
    final framework = await _framework();
    var taps = 0;
    await tester.pumpWidget(
      TfApp(
        framework: framework,
        home: TfScaffold(
          title: 'Home',
          body: TfListView(
            children: [
              TfButton(label: 'Go', onPressed: () => taps++),
              TfSwitch(value: true, onChanged: (_) {}),
            ],
          ),
        ),
      ),
    );

    expect(find.widgetWithText(AppBar, 'Home'), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);
    expect(find.byType(Switch), findsOneWidget);
    await tester.tap(find.text('Go'));
    expect(taps, 1);

    await framework.switchDesignSystem('plain');
    await tester.pumpAndSettle();

    expect(find.byType(FilledButton), findsNothing);
    expect(find.text('[Go]'), findsOneWidget);
  });

  testWidgets('switching design systems keeps the navigation stack', (tester) async {
    final framework = await _framework();
    await tester.pumpWidget(
      TfApp(
        framework: framework,
        home: Builder(
          builder: (context) => TfScaffold(
            body: TfButton(
              label: 'Open',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const TfScaffold(title: 'Details', body: SizedBox()),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Details'), findsOneWidget);

    await framework.switchDesignSystem('plain');
    await tester.pumpAndSettle();

    expect(find.text('Details'), findsOneWidget);
  });

  testWidgets('appearance preferences drive theme and text scale', (tester) async {
    final framework = await _framework(values: {'tf.themeMode': 'dark', 'tf.textScale': 1.2});
    late BuildContext captured;
    await tester.pumpWidget(
      TfApp(
        framework: framework,
        home: Builder(
          builder: (context) {
            captured = context;
            return const SizedBox();
          },
        ),
      ),
    );

    expect(Theme.of(captured).brightness, Brightness.dark);
    expect(MediaQuery.textScalerOf(captured).scale(10), closeTo(12, 0.001));

    await framework.preferences.setEnum(TfPreferenceKeys.themeMode, ThemeMode.light);
    await tester.pumpAndSettle();
    expect(Theme.of(captured).brightness, Brightness.light);
  });

  testWidgets('settings page edits preferences', (tester) async {
    const flag = TfPreferenceKey<bool>('app.flag', defaultValue: false);
    final framework = await TfFramework.initialize(
      designSystems: const [Material3DesignSystem(), _PlainDesignSystem()],
      store: TfMemoryPreferenceStore(),
      settings: const [
        TfSettingsSection(
          title: 'App',
          settings: [TfToggleSetting(key: flag, title: 'App flag')],
        ),
      ],
    );
    await tester.pumpWidget(TfApp(framework: framework, home: const TfSettingsPage()));

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(framework.preferences.getEnum(TfPreferenceKeys.themeMode), ThemeMode.dark);

    await tester.tap(find.text('Plain'));
    await tester.pumpAndSettle();
    expect(framework.activeDesignSystem.id, 'plain');

    await tester.scrollUntilVisible(find.text('App flag'), 200);
    await tester.tap(find.text('App flag'));
    await tester.pumpAndSettle();
    expect(framework.preferences.get(flag), isTrue);
  });

  testWidgets('dialogs return the chosen action value', (tester) async {
    final framework = await _framework();
    Future<String?>? result;
    await tester.pumpWidget(
      TfApp(
        framework: framework,
        home: Builder(
          builder: (context) => TfScaffold(
            body: TfButton(
              label: 'Ask',
              onPressed: () => result = showTfDialog<String>(
                context,
                title: 'Pick',
                actions: const [
                  TfDialogAction(label: 'A', value: 'a'),
                  TfDialogAction(label: 'B', value: 'b', isPrimary: true),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Ask'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('B'));
    await tester.pumpAndSettle();

    expect(await result, 'b');
  });
}
