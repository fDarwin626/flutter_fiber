// Basic smoke test for the flutter_fiber example app.
//
// This confirms the app builds and mounts without throwing — full GL
// rendering behavior is verified visually on-device/emulator, not here,
// since GL contexts aren't available in the widget-test environment.

import 'package:flutter_test/flutter_test.dart';

import 'package:example/main.dart';

void main() {
  testWidgets('FiberRingTest mounts without throwing', (WidgetTester tester) async {
    await tester.pumpWidget(const FiberRingTest());
    await tester.pump();

    expect(find.text('flutter_fiber — Section 2.5 ring test'), findsOneWidget);
  });
}