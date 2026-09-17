import 'package:flutter_test/flutter_test.dart';

import 'package:example/main.dart';

void main() {
  testWidgets('FiberShapeGallery mounts without throwing', (WidgetTester tester) async {
    await tester.pumpWidget(const FiberShapeGallery());
    await tester.pump();

    expect(find.text('flutter_fiber gallery'), findsOneWidget);
  });
}