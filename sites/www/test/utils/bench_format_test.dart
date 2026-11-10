// Copyright 2026, the Flutter authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that
// can be found in the LICENSE file.

import 'package:flutter_website/src/utils/bench_format.dart';
import 'package:test/test.dart';

void main() {
  test('formatPercent', () {
    expect(formatPercent(85.4), '85.4%');
    expect(formatPercent(85.426, decimals: 2), '85.43%');
    expect(formatPercent(null), missingValue);
  });

  test('formatScoreWithSd', () {
    expect(formatScoreWithSd(85.4, 4.2), '85.4% ± 4.2%');
    expect(formatScoreWithSd(null, 4.2), missingValue);
  });

  test('formatTokens', () {
    expect(formatTokens(10456845), '10,456,845');
    expect(formatTokens(42000), '42,000');
    expect(formatTokens(500), '500');
    expect(formatTokens(-20000), '-20,000');
    expect(formatTokens(null), missingValue);
  });

  test('formatCost', () {
    expect(formatCost(1.4488), r'$1.449');
    expect(formatCost(null), missingValue);
  });

  test('formatFraction', () {
    expect(formatFraction(3, 4), '3/4');
  });

  test('formatDelta', () {
    expect(formatDelta(15.2), '+15.2%');
    expect(formatDelta(-8.4), '-8.4%');
    expect(formatDelta(null), missingValue);
  });
}
