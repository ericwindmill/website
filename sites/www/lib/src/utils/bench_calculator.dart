// Copyright 2026, the Flutter authors. All rights reserved. Use of this source
// code is governed by a BSD-style license that can be found in the LICENSE
// file.

import 'dart:math' as math;
import '../models/content/flutter_bench.dart';

/// Calculation engine for Flutter Bench leaderboard metrics.
class BenchCalculator {
  const BenchCalculator();

  /// Computes all aggregate metrics from a [BenchModelRun].
  static AggregateMetrics computeMetrics(BenchModelRun run) {
    if (run.tasks.isEmpty) return AggregateMetrics.empty;

    final totalTasks = run.tasks.length;

    // Pass Rate: percentage of tasks where Outcome score is 1.0 (mean outcome
    // == 1.0)
    final passedTasksCount = run.tasks.where((t) => t.passedFully).length;
    final passRate = (passedTasksCount / totalTasks) * 100.0;

    // Pass@4: percentage of tasks where at least 1 of 4 trials passed (outcome
    // == 1.0)
    final passAt4Count = run.tasks.where((t) => t.passedAtLeastOnce).length;
    final passAt4Rate = (passAt4Count / totalTasks) * 100.0;

    // Task-level Result Scores on a 0-100 scale: (Outcome * 0.60 + Quality *
    // 0.30 + DX * 0.10) * 100
    final taskScores = run.tasks.map((t) => t.avgScore * 100.0).toList();
    final avgScore = taskScores.reduce((a, b) => a + b) / totalTasks;

    // Standard deviation of Result Scores (Sample SD)
    var scoreSd = 0.0;
    if (totalTasks > 1) {
      final variance =
          taskScores
              .map((score) => math.pow(score - avgScore, 2))
              .reduce((a, b) => a + b) /
          (totalTasks - 1);
      scoreSd = math.sqrt(variance);
    }

    // Component breakdowns
    final avgOutcome =
        (run.tasks.map((t) => t.avgOutcome).reduce((a, b) => a + b) /
            totalTasks) *
        100.0;
    final avgQuality =
        (run.tasks.map((t) => t.avgQuality).reduce((a, b) => a + b) /
            totalTasks) *
        100.0;
    final avgDx =
        (run.tasks.map((t) => t.avgDx).reduce((a, b) => a + b) / totalTasks) *
        100.0;

    // Resource metrics
    final totalTokens = run.tasks.map((t) => t.tokens).reduce((a, b) => a + b);
    final avgTokens = (totalTokens / totalTasks).round();

    final totalCost = run.tasks.map((t) => t.cost).reduce((a, b) => a + b);
    final avgCost = totalCost / totalTasks;

    return AggregateMetrics(
      passRate: passRate,
      passAt4Rate: passAt4Rate,
      avgScore: avgScore,
      scoreSd: scoreSd,
      avgOutcome: avgOutcome,
      avgQuality: avgQuality,
      avgDx: avgDx,
      avgTokens: avgTokens,
      avgCost: avgCost,
      totalTasks: totalTasks,
    );
  }

  /// Groups runs into comparisons containing both Baseline and AI Tooling
  /// metrics.
  static List<BenchComparisonEntry> buildComparisonEntries(
    List<BenchModelRun> runs,
  ) {
    final baselineMap = <String, BenchModelRun>{};
    final aiToolingMap = <String, BenchModelRun>{};
    final models = <String>{};

    for (final run in runs) {
      final key = run.compositeKey;
      models.add(key);
      if (run.variant == BenchVariant.baseline) {
        baselineMap[key] = run;
      } else {
        aiToolingMap[key] = run;
      }
    }

    final entries = <BenchComparisonEntry>[];
    for (final key in models) {
      final baseline = baselineMap[key];
      final aiTooling = aiToolingMap[key];

      final agent = aiTooling?.agent ?? baseline?.agent ?? '';
      final model = aiTooling?.model ?? baseline?.model ?? '';

      final baselineMetrics = baseline != null
          ? computeMetrics(baseline)
          : AggregateMetrics.empty;
      final aiToolingMetrics = aiTooling != null
          ? computeMetrics(aiTooling)
          : AggregateMetrics.empty;

      entries.add(
        BenchComparisonEntry(
          agent: agent,
          model: model,
          baselineRun: baseline,
          aiToolingRun: aiTooling,
          baselineMetrics: baselineMetrics,
          aiToolingMetrics: aiToolingMetrics,
        ),
      );
    }

    return entries;
  }

  /// Formats a percentage value with fixed decimals.
  static String formatPercent(double val, {int decimals = 1}) {
    return '${val.toStringAsFixed(decimals)}%';
  }

  /// Formats Avg Score as `X.X% ± Y.Y%`.
  static String formatScoreWithSd(double mean, double sd) {
    return '${mean.toStringAsFixed(1)}% ± ${sd.toStringAsFixed(1)}%';
  }

  /// Formats integer token count with thousands separators.
  static String formatTokens(int tokens) {
    final str = tokens.toString();
    final buffer = StringBuffer();
    var count = 0;
    for (var i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i != 0) {
        buffer.write(',');
      }
    }
    return buffer.toString().split('').reversed.join('');
  }

  /// Formats cost in USD.
  static String formatCost(double cost) {
    return '\$${cost.toStringAsFixed(3)}';
  }

  /// Formats delta with +/- sign.
  static String formatDelta(
    double delta, {
    String suffix = '%',
    int decimals = 1,
  }) {
    final prefix = delta >= 0.0 ? '+' : '';
    return '$prefix${delta.toStringAsFixed(decimals)}$suffix';
  }
}
