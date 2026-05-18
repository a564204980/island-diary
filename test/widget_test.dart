import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:island_diary/main.dart';

void main() {
  test('app scroll behavior supports desktop and touch input', () {
    final behavior = AppScrollBehavior();

    expect(behavior.dragDevices, contains(PointerDeviceKind.touch));
    expect(behavior.dragDevices, contains(PointerDeviceKind.mouse));
    expect(behavior.dragDevices, contains(PointerDeviceKind.trackpad));
  });
}
