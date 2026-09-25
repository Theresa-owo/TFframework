import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tf_framework/tf_framework.dart';

Future<TfFramework> _framework({Map<String, Object>? values, bool glass = false}) => TfFramework.initialize(
  designSystems: [const Material3DesignSystem(), if (glass) const LiquidGlassDesignSystem(warmUpShaders: false)],
  store: TfMemoryPreferenceStore({...?values, if (glass) 'tf.designSystem': LiquidGlassDesignSystem.systemId}),
);

Future<void> _pump(WidgetTester tester, TfFramework framework, Widget page) async {
  await tester.pumpWidget(TfApp(framework: framework, home: page));
  await tester.pump(const Duration(milliseconds: 100));
}

Widget _page(Widget child) => TfScaffold(body: TfListView(children: [child]));

void main() {
  group('TfValidators', () {
    const v = TfValidators(TfStringsEn());

    test('required, email, minLength and matches', () {
      expect(v.required()(''), 'This field is required');
      expect(v.required()('  '), isNotNull);
      expect(v.required()('a'), isNull);
      expect(v.email()('nope'), 'Enter a valid email address');
      expect(v.email()('a@b.co'), isNull);
      expect(v.email()(''), isNull);
      expect(v.minLength(3)('ab'), 'Must be at least 3 characters');
      expect(v.matches(() => 'x')('y'), 'Passwords do not match');
      expect(TfValidators.compose([v.required(), v.email()])(''), 'This field is required');
    });

    test('messages follow the language', () {
      expect(const TfValidators(TfStringsZh()).required()(''), '此项为必填项');
    });
  });

  group('TfLoginForm', () {
    testWidgets('validates before submitting', (tester) async {
      var calls = 0;
      await _pump(tester, await _framework(), _page(TfLoginForm(onSubmit: (_) async => calls++)));

      await tester.tap(find.text('Sign in'));
      await tester.pump();

      expect(calls, 0);
      expect(find.text('This field is required'), findsNWidgets(2));
    });

    testWidgets('submits credentials and shows auth errors', (tester) async {
      TfLoginCredentials? received;
      await _pump(
        tester,
        await _framework(),
        _page(
          TfLoginForm(
            onSubmit: (credentials) async {
              received = credentials;
              throw const TfAuthException('Wrong password');
            },
          ),
        ),
      );

      await tester.enterText(find.byType(TextField).at(0), 'me@example.com');
      await tester.enterText(find.byType(TextField).at(1), 'secret123');
      await tester.tap(find.text('Remember me'));
      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();

      expect(received?.identifier, 'me@example.com');
      expect(received?.password, 'secret123');
      expect(received?.rememberMe, isTrue);
      expect(find.text('Wrong password'), findsOneWidget);
    });

    testWidgets('password visibility toggles', (tester) async {
      await _pump(tester, await _framework(), _page(TfLoginForm(onSubmit: (_) async {})));
      TextField password() => tester.widget<TextField>(find.byType(TextField).at(1));

      expect(password().obscureText, isTrue);
      await tester.tap(find.byTooltip('Show password'));
      await tester.pump();
      expect(password().obscureText, isFalse);
    });
  });

  testWidgets('TfSignUpForm requires matching passwords and accepted terms', (tester) async {
    TfSignUpData? received;
    await _pump(
      tester,
      await _framework(),
      _page(TfSignUpForm(termsLabel: const Text('Terms'), onSubmit: (data) async => received = data)),
    );
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Ada');
    await tester.enterText(fields.at(1), 'ada@example.com');
    await tester.enterText(fields.at(2), 'password1');
    await tester.enterText(fields.at(3), 'password2');
    await tester.tap(find.text('Sign up'));
    await tester.pump();
    expect(find.text('Please accept the terms to continue'), findsOneWidget);

    await tester.tap(find.text('Terms'));
    await tester.tap(find.text('Sign up'));
    await tester.pump();
    expect(find.text('Passwords do not match'), findsOneWidget);
    expect(received, isNull);

    await tester.enterText(fields.at(3), 'password1');
    await tester.tap(find.text('Sign up'));
    await tester.pumpAndSettle();
    expect(received?.name, 'Ada');
    expect(received?.email, 'ada@example.com');
  });

  group('overlays', () {
    testWidgets('input dialog stays open until valid', (tester) async {
      Future<String?>? result;
      await _pump(
        tester,
        await _framework(),
        Builder(
          builder: (context) => _page(
            TfButton(
              label: 'Ask',
              onPressed: () =>
                  result = showTfInputDialog(context, title: 'Name', validator: TfValidators.of(context).required()),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Ask'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.text('This field is required'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Ada');
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(await result, 'Ada');
    });

    testWidgets('confirm and action sheet return the choice', (tester) async {
      Future<bool>? confirmed;
      Future<String?>? choice;
      await _pump(
        tester,
        await _framework(),
        Builder(
          builder: (context) => _page(
            Column(
              children: [
                TfButton(
                  label: 'Confirm',
                  onPressed: () => confirmed = showTfConfirm(context, title: 'Sure?'),
                ),
                TfButton(
                  label: 'Sheet',
                  onPressed: () => choice = showTfActionSheet<String>(
                    context,
                    actions: const [
                      TfSheetAction(label: 'Copy', value: 'copy'),
                      TfSheetAction(label: 'Delete', value: 'delete', isDestructive: true),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Confirm').last);
      await tester.pumpAndSettle();
      expect(await confirmed, isTrue);

      await tester.tap(find.text('Sheet'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(await choice, 'delete');
    });

    testWidgets('runWithTfLoading blocks until the task completes', (tester) async {
      Future<int>? result;
      await _pump(
        tester,
        await _framework(),
        Builder(
          builder: (context) => _page(
            TfButton(
              label: 'Run',
              onPressed: () =>
                  result = runWithTfLoading(context, () => Future.delayed(const Duration(seconds: 1), () => 42)),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Run'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Loading…'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.text('Loading…'), findsNothing);
      expect(await result, 42);
    });
  });

  testWidgets('TfAsyncBuilder shows error with retry, then data', (tester) async {
    var attempts = 0;
    await _pump(
      tester,
      await _framework(),
      TfScaffold(
        body: TfAsyncBuilder<String>(
          load: () async {
            attempts++;
            if (attempts == 1) throw Exception('offline');
            return 'loaded';
          },
          builder: (context, data) => Text(data),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Something went wrong'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('loaded'), findsOneWidget);
  });

  testWidgets('language preference switches built-in strings', (tester) async {
    final framework = await _framework(values: {'tf.locale': 'zh'});
    await _pump(tester, framework, const TfSettingsPage());
    expect(find.text('设置'), findsOneWidget);
    expect(find.text('外观'), findsOneWidget);

    await framework.preferences.set(TfPreferenceKeys.locale, 'en');
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('text setting edits a string preference through a dialog', (tester) async {
    const nickname = TfPreferenceKey<String>('app.nickname', defaultValue: '');
    final framework = await TfFramework.initialize(
      designSystems: const [Material3DesignSystem()],
      store: TfMemoryPreferenceStore(),
      settings: const [
        TfSettingsSection(
          title: 'Profile',
          settings: [TfTextSetting(key: nickname, title: 'Nickname')],
        ),
      ],
    );
    await _pump(tester, framework, const TfSettingsPage(includeBuiltIns: false));

    await tester.tap(find.text('Nickname'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Ada');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(framework.preferences.get(nickname), 'Ada');
    expect(find.text('Ada'), findsOneWidget);
  });

  testWidgets('kits render with liquid glass', (tester) async {
    await _pump(
      tester,
      await _framework(glass: true),
      TfScaffold(
        body: TfAuthLayout(
          title: 'Welcome',
          child: TfLoginForm(onSubmit: (_) async {}),
        ),
      ),
    );
    expect(find.text('Welcome'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
