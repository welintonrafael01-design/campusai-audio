import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android production identity is final and not under com.example', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    final activity = File(
      'android/app/src/main/kotlin/com/studybookai/app/MainActivity.kt',
    ).readAsStringSync();

    expect(gradle, contains('namespace = "com.studybookai.app"'));
    expect(gradle, contains('applicationId = "com.studybookai.app"'));
    expect(activity, contains('package com.studybookai.app'));
    expect(gradle, isNot(contains('com.example.')));
  });
}
