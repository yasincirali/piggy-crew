import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Android release hattı (2026-10-29): Play'e giden derleme debug anahtarıyla
/// imzalanmaz, internetsiz kalmaz, reklam kimliği istemez (Aileler politikası).
/// Gradle bu ortamda koşmadığı için dosyalar metin olarak denetlenir; asıl
/// derleme `android-release.yml`'in PR koşusunda.
void main() {
  final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
  final gradle = File('android/app/build.gradle.kts').readAsStringSync();

  test('release manifesti internet izni taşır (fiyatlar)', () {
    expect(manifest, contains('android.permission.INTERNET'));
  });

  test('reklam kimliği birleştirmede silinir', () {
    expect(manifest, contains('com.google.android.gms.permission.AD_ID" tools:node="remove"'));
  });

  test('release debug anahtarıyla imzalanmaz; anahtar yoksa durur', () {
    final release = RegExp(r'release \{[^}]*\}').firstMatch(gradle.substring(gradle.indexOf('buildTypes')))!.group(0)!;
    expect(release, isNot(contains('"debug"')));
    expect(release, contains('signingConfigs.getByName("release")'));
    expect(gradle, contains('key.properties bulunamadı'));
  });

  test('anahtar dosyaları repoya girmez', () {
    final yok = File('.gitignore').readAsStringSync();
    expect(yok, contains('android/key.properties'));
    expect(yok, contains('*.jks'));
    final akis = File('.github/workflows/android-release.yml').readAsStringSync();
    expect(akis, contains('rm -f android/app/upload-keystore.jks android/key.properties'));
  });

  test('Play notları 500 karakteri aşmaz', () {
    for (final f in Directory('store_listing/play_whatsnew').listSync().whereType<File>()) {
      expect(f.readAsStringSync().trim().length, lessThanOrEqualTo(500), reason: f.path);
    }
  });
}
