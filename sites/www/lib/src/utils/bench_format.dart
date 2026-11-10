// Copyright 2026, the Flutter authors. All rights reserved. Use of this source
// code is governed by a BSD-style license that can be found in the LICENSE
// file.

/// Display formatting for Flutter Bench metrics.
///
/// Metrics arrive pre-aggregated in the results file,
/// so this file only handles presentation.
/// Every formatter returns [missingValue] for `null` input,
/// such as a missing variant run or unavailable pricing.
library;

/// The placeholder shown when a value isn't available.
const String missingValue = '—';

/// Formats a percentage value, such as `85.4%`.
String formatPercent(double? value, {int decimals = 1}) =>
    value == null ? missingValue : '${value.toStringAsFixed(decimals)}%';

/// Formats a score with its standard deviation, such as `85.4% ± 4.2%`.
String formatScoreWithSd(double? mean, double? sd) {
  if (mean == null || sd == null) return missingValue;
  return '${mean.toStringAsFixed(1)}% ± ${sd.toStringAsFixed(1)}%';
}

/// Formats a token count with thousands separators, such as `1,234,567`.
String formatTokens(int? tokens) {
  if (tokens == null) return missingValue;
  final digits = tokens.abs().toString();
  final buffer = StringBuffer(tokens < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

/// Formats a cost in USD, such as `$1.483`.
String formatCost(double? cost) =>
    cost == null ? missingValue : '\$${cost.toStringAsFixed(3)}';

/// Formats a pass count out of a total, such as `3/4`.
String formatFraction(int count, int total) => '$count/$total';

/// Formats a delta with an explicit sign, such as `+15.2%`.
String formatDelta(double? delta, {String suffix = '%', int decimals = 1}) {
  if (delta == null) return missingValue;
  final prefix = delta >= 0.0 ? '+' : '';
  return '$prefix${delta.toStringAsFixed(decimals)}$suffix';
}
