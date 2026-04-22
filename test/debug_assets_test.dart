import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Debug Assets', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final manifestContent = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifestMap = json.decode(manifestContent);

    print("=== ASSETS ===");
    for (final key in manifestMap.keys) {
      print(key);
    }
  });
}
