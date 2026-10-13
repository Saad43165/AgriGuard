import 'dart:convert';
import 'dart:io';

import 'package:agriguard_fyp/core/services/translation_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Every literal key passed to `<translator>.get('key')` must resolve in both
/// English and Urdu, otherwise users see the raw key (e.g. "clear_filters").
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('all translation keys used in code exist in English and Urdu', () async {
    SharedPreferences.setMockInitialValues({});
    final service = TranslationService();
    await service.loadLanguage();

    final pattern = RegExp(r'''\b(?:t|_t|translation|translationService|tr|widget\.t)\.get\(\s*'([^'$]+)'\s*\)''');
    final keys = <String, String>{};
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart')) continue;
      for (final m in pattern.allMatches(f.readAsStringSync())) {
        keys.putIfAbsent(m.group(1)!, () => f.path);
      }
    }
    expect(keys, isNotEmpty);

    bool inJson(Map<String, dynamic> root, String key) {
      dynamic cur = root;
      for (final part in key.split('.')) {
        if (cur is Map<String, dynamic> && cur.containsKey(part)) {
          cur = cur[part];
        } else {
          return false;
        }
      }
      return cur is String;
    }

    final json = {
      false: jsonDecode(File('assets/translations/en.json').readAsStringSync()) as Map<String, dynamic>,
      true: jsonDecode(File('assets/translations/ur.json').readAsStringSync()) as Map<String, dynamic>,
    };

    final missing = <String>[];
    for (final isUrdu in [false, true]) {
      if (service.isUrdu != isUrdu) await service.toggleLanguage();
      for (final e in keys.entries) {
        // A value equal to its key (e.g. "acres") is fine if it is defined.
        if (service.get(e.key) == e.key && !inJson(json[isUrdu]!, e.key)) {
          missing.add('${isUrdu ? 'ur' : 'en'}: ${e.key} (${e.value})');
        }
      }
    }
    expect(missing, isEmpty, reason: 'Missing translations:\n${missing.join('\n')}');
  });
}
