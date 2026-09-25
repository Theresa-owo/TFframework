import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:tf_framework/tf_framework.dart';

void main() {
  testWidgets('liquid glass renders glass chrome and avoids glass-in-glass', (tester) async {
    final framework = await TfFramework.initialize(
      designSystems: const [Material3DesignSystem(), LiquidGlassDesignSystem(warmUpShaders: false)],
      store: TfMemoryPreferenceStore({'tf.designSystem': LiquidGlassDesignSystem.systemId}),
    );
    await tester.pumpWidget(
      TfApp(
        framework: framework,
        home: TfScaffold(
          title: 'Glass',
          destinations: const [
            TfNavDestination(icon: Icons.home, label: 'Home'),
            TfNavDestination(icon: Icons.settings, label: 'Settings'),
          ],
          body: TfListView(
            children: [
              TfSwitch(value: true, onChanged: (_) {}),
              TfSection(
                title: 'Nested',
                children: [
                  TfListTile(
                    title: const Text('Row'),
                    trailing: TfSwitch(value: false, onChanged: (_) {}),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(GlassScaffold), findsOneWidget);
    expect(find.byType(GlassAppBar), findsOneWidget);
    expect(find.byType(GlassTabBar), findsOneWidget);
    expect(find.byType(GlassSwitch), findsOneWidget);
    expect(find.byType(GlassGroupedSection), findsOneWidget);
    expect(
      find.descendant(of: find.byType(GlassGroupedSection), matching: find.byType(CupertinoSwitch)),
      findsOneWidget,
    );

    await framework.switchDesignSystem(Material3DesignSystem.systemId);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(GlassScaffold), findsNothing);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('glass settings appear only while glass is active', (tester) async {
    final framework = await TfFramework.initialize(
      designSystems: const [Material3DesignSystem(), LiquidGlassDesignSystem(warmUpShaders: false)],
      store: TfMemoryPreferenceStore(),
    );
    await tester.pumpWidget(TfApp(framework: framework, home: const TfSettingsPage()));
    expect(find.text('Rendering quality'), findsNothing);

    await framework.switchDesignSystem(LiquidGlassDesignSystem.systemId);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.scrollUntilVisible(find.text('Rendering quality'), 200);
    expect(find.text('Rendering quality'), findsOneWidget);
  });
}
