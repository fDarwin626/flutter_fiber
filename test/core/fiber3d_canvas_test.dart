import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_fiber/src/core/fiber3d_canvas.dart';

class _CounterProbe extends StatefulWidget {
  final ValueChanged<int> onCount;
  const _CounterProbe({required this.onCount});

  @override
  State<_CounterProbe> createState() => _CounterProbeState();
}

class _CounterProbeState extends State<_CounterProbe>
    with Fiber3DFrameCallbackMixin {
  int _count = 0;

  @override
  void onFrame(Duration elapsed, Duration delta) {
    _count++;
    widget.onCount(_count);
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

void main() {
  testWidgets('onFrame fires while mounted inside Fiber3DCanvas',
      (tester) async {
    int lastCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Fiber3DCanvas(
          children: [_CounterProbe(onCount: (c) => lastCount = c)],
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 16));

    expect(lastCount, greaterThanOrEqualTo(3));
  });

  testWidgets('onFrame stops firing after widget is removed from tree',
      (tester) async {
    int lastCount = 0;
    bool showProbe = true;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            return Fiber3DCanvas(
              children: [
                if (showProbe) _CounterProbe(onCount: (c) => lastCount = c),
                TextButton(
                  onPressed: () => setState(() => showProbe = false),
                  child: const Text('remove'),
                ),
              ],
            );
          },
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 16));
    expect(lastCount, greaterThan(0));

    await tester.tap(find.text('remove'));
    await tester.pump();

    final countAtRemoval = lastCount;

    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 16));

    expect(lastCount, countAtRemoval);
  });

  testWidgets('Fiber3DCanvas disposes its ticker cleanly', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: Fiber3DCanvas(children: [])),
    );

    await tester.pump(const Duration(milliseconds: 16));

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));

    expect(tester.takeException(), isNull);
  });
}