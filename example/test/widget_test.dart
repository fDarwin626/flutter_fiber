import 'package:flutter_test/flutter_test.dart';

import 'package:example/main.dart';

void main() {
  testWidgets('FiberFullSceneTest mounts without throwing', (WidgetTester tester) async {
    await tester.pumpWidget(const FiberFullSceneTest());
    await tester.pump();

    expect(find.text('flutter_fiber — Section 7 full scene test'), findsOneWidget);
  });
}