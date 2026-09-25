import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tf_framework/tf_framework.dart';

enum _Size { small, large }

class _CountingStore extends TfMemoryPreferenceStore {
  int saves = 0;

  @override
  Future<void> save(Map<String, Object> values) async {
    saves++;
    await super.save(values);
  }
}

void main() {
  const flag = TfPreferenceKey<bool>('flag', defaultValue: false);
  const tags = TfPreferenceKey<List<String>>('tags', defaultValue: []);

  group('TfPreferencesController', () {
    test('returns defaults and falls back when stored value is invalid', () async {
      final controller = TfPreferencesController(
        store: TfMemoryPreferenceStore({'flag': 'not a bool', 'tf.textScale': 9.0}),
      );
      await controller.load();

      expect(controller.get(flag), isFalse);
      expect(controller.get(TfPreferenceKeys.textScale), 1.0);
      expect(controller.isCustomized(flag), isFalse);
    });

    test('set notifies, persists and rejects invalid values', () async {
      final store = TfMemoryPreferenceStore();
      final controller = TfPreferencesController(store: store);
      await controller.load();
      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.set(flag, true);
      await controller.set(flag, true);

      expect(notifications, 1);
      expect(await store.load(), {'flag': true});
      expect(() => controller.set(TfPreferenceKeys.textScale, 5.0), throwsArgumentError);
    });

    test('coalesces bursts of writes', () async {
      final store = _CountingStore();
      final controller = TfPreferencesController(store: store);
      await controller.load();

      for (var i = 0; i < 10; i++) {
        controller.set(TfPreferenceKeys.textScale, 1.0 + i / 20);
      }
      await controller.flush();

      expect(store.saves, lessThanOrEqualTo(2));
      expect((await store.load())['tf.textScale'], 1.45);
    });

    test('enum preferences round-trip by name', () async {
      final size = TfEnumPreference<_Size>('size', values: _Size.values, defaultValue: _Size.small);
      final controller = TfPreferencesController(store: TfMemoryPreferenceStore());
      await controller.load();

      expect(controller.getEnum(size), _Size.small);
      await controller.setEnum(size, _Size.large);
      expect(controller.get(size.key), 'large');
      expect(controller.getEnum(size), _Size.large);
    });

    test('reset, resetAll, export and import', () async {
      final controller = TfPreferencesController(store: TfMemoryPreferenceStore());
      await controller.load();
      await controller.set(flag, true);
      await controller.set(tags, ['a', 'b']);

      expect(controller.export(), {
        'flag': true,
        'tags': ['a', 'b'],
      });
      await controller.reset(flag);
      expect(controller.get(flag), isFalse);

      await controller.resetAll();
      expect(controller.export(), isEmpty);

      await controller.import({'flag': true, 'unsupported': DateTime(2020)});
      expect(controller.export(), {'flag': true});
    });
  });

  group('TfSharedPreferenceStore', () {
    test('stores one JSON document and restores string lists', () async {
      SharedPreferences.setMockInitialValues({'other': 1});
      final store = TfSharedPreferenceStore();
      await store.save({
        'flag': true,
        'tags': ['x'],
      });

      final raw = (await SharedPreferences.getInstance()).getString('tf_framework.preferences');
      expect(jsonDecode(raw!), {
        'flag': true,
        'tags': ['x'],
      });
      final loaded = await store.load();
      expect(loaded['tags'], isA<List<String>>());
      expect((await SharedPreferences.getInstance()).getInt('other'), 1);
    });

    test('ignores corrupt data', () async {
      SharedPreferences.setMockInitialValues({'tf_framework.preferences': '[1, 2]'});
      expect(await TfSharedPreferenceStore().load(), isEmpty);
    });
  });

  group('TfFramework', () {
    test('requires unique design systems', () async {
      await expectLater(TfFramework.initialize(designSystems: const []), throwsArgumentError);
      await expectLater(
        TfFramework.initialize(
          designSystems: const [Material3DesignSystem(), Material3DesignSystem()],
          store: TfMemoryPreferenceStore(),
        ),
        throwsArgumentError,
      );
    });

    test('falls back to the first design system for unknown ids', () async {
      final framework = await TfFramework.initialize(
        designSystems: const [Material3DesignSystem()],
        store: TfMemoryPreferenceStore({'tf.designSystem': 'removed'}),
      );
      expect(framework.activeDesignSystem.id, Material3DesignSystem.systemId);
      expect(() => framework.switchDesignSystem('missing'), throwsArgumentError);
    });
  });
}
