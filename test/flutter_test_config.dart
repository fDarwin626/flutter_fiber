import 'dart:async';

import 'package:visibility_detector/visibility_detector.dart';

/// Runs before every test file under test/.
///
/// VisibilityDetector defaults to a 500 ms update timer, which flutter_test
/// reports as a pending timer when a test ends. Zero makes it report
/// visibility at the end of the frame instead.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  VisibilityDetectorController.instance.updateInterval = Duration.zero;
  await testMain();
}