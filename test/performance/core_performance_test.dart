import 'package:flutter_test/flutter_test.dart';

void main() {
  test('core performance baseline', () {
    final stopwatch = Stopwatch()..start();

    for (var i = 0; i < 100000; i++) {
      Object.hash(i, i + 1);
    }

    stopwatch.stop();

    // A deliberately broad regression guard, not a microbenchmark.
    expect(stopwatch.elapsedMilliseconds, lessThan(2000));
  });
}
