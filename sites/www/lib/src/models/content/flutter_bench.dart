// Copyright 2026, the Flutter authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that
// can be found in the LICENSE file.

/// Variants evaluated in Flutter Bench.
// TODO(ewindmill): ContentMapper?
enum BenchVariant {
  baseline('baseline', 'Baseline'),
  aiTooling('ai_tooling', 'With AI tooling');

  final String value;
  final String label;

  const BenchVariant(this.value, this.label);

  static BenchVariant fromString(String val) =>
      val == 'ai_tooling' ? BenchVariant.aiTooling : BenchVariant.baseline;
}

/// Horizon categories for Flutter benchmark CUJs.
enum TaskCategory {
  shortHorizon('short_horizon', 'Short horizon'),
  longHorizon('long_horizon', 'Long horizon');

  final String value;
  final String label;

  const TaskCategory(this.value, this.label);

  static TaskCategory fromString(String val) => val == 'long_horizon'
      ? TaskCategory.longHorizon
      : TaskCategory.shortHorizon;
}

/// Represents an individual trial execution for a benchmark task.
class BenchTrial {
  final int trialIndex;
  final double outcome; // 0.0 - 1.0 scale (1.0 = passed)
  final double quality; // 0.0 - 1.0 scale
  final double dx; // 0.0 - 1.0 scale

  const BenchTrial({
    required this.trialIndex,
    required this.outcome,
    required this.quality,
    required this.dx,
  });

  /// A trial passes if and only if outcome is 1.0.
  bool get isPassed => outcome >= 1.0;

  /// Weighted result score: Outcome (60%) + Quality (30%) + DX (10%).
  double get resultScore => (outcome * 0.60) + (quality * 0.30) + (dx * 0.10);

  factory BenchTrial.fromJson(Map<String, Object?> json) {
    return BenchTrial(
      trialIndex: (json['trialIndex'] as num?)?.toInt() ?? 1,
      outcome: (json['outcome'] as num?)?.toDouble() ?? 0.0,
      quality: (json['quality'] as num?)?.toDouble() ?? 0.0,
      dx: (json['dx'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, Object?> toJson() => {
    'trialIndex': trialIndex,
    'outcome': outcome,
    'quality': quality,
    'dx': dx,
  };
}

/// A benchmark task containing 4 trials and resource metrics.
class BenchTask {
  final String id;
  final String name;
  final TaskCategory category;
  final int tokens;
  final double cost;
  final List<BenchTrial> trials;

  const BenchTask({
    required this.id,
    required this.name,
    required this.category,
    required this.tokens,
    required this.cost,
    required this.trials,
  });

  factory BenchTask.fromJson(Map<String, Object?> json) {
    return BenchTask(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      category: TaskCategory.fromString(json['category'] as String? ?? ''),
      tokens: (json['tokens'] as num?)?.toInt() ?? 0,
      cost: (json['cost'] as num?)?.toDouble() ?? 0.0,
      trials:
          (json['trials'] as List<dynamic>?)
              ?.map((t) => BenchTrial.fromJson(t as Map<String, Object?>))
              .toList() ??
          const [],
    );
  }

  /// Mean outcome score across all trials for this task.
  double get avgOutcome => trials.isEmpty
      ? 0.0
      : trials.map((t) => t.outcome).reduce((a, b) => a + b) / trials.length;

  /// Mean quality score across all trials for this task.
  double get avgQuality => trials.isEmpty
      ? 0.0
      : trials.map((t) => t.quality).reduce((a, b) => a + b) / trials.length;

  /// Mean developer experience score across all trials for this task.
  double get avgDx => trials.isEmpty
      ? 0.0
      : trials.map((t) => t.dx).reduce((a, b) => a + b) / trials.length;

  /// Mean result score for this task (0.0 to 1.0).
  double get avgScore =>
      (avgOutcome * 0.60) + (avgQuality * 0.30) + (avgDx * 0.10);

  /// Pass@4: At least 1 of the 4 trials passed (outcome == 1.0).
  bool get passedAtLeastOnce => trials.any((t) => t.isPassed);

  /// Pass Rate criteria: Task outcome is 1.0 across trials.
  bool get passedFully => avgOutcome >= 1.0;
}

/// An evaluation run for a specific agent and model under a single variant.
class BenchModelRun {
  final String agent;
  final String model;
  final BenchVariant variant;
  final List<BenchTask> tasks;

  const BenchModelRun({
    required this.agent,
    required this.model,
    required this.variant,
    required this.tasks,
  });

  factory BenchModelRun.fromJson(Map<String, Object?> json) {
    return BenchModelRun(
      agent: json['agent'] as String? ?? '',
      model: json['model'] as String? ?? '',
      variant: BenchVariant.fromString(json['variant'] as String? ?? ''),
      tasks:
          (json['tasks'] as List<dynamic>?)
              ?.map((t) => BenchTask.fromJson(t as Map<String, Object?>))
              .toList() ??
          const [],
    );
  }

  String get compositeKey => '$agent / $model';
}

/// Aggregated metrics computed dynamically from a [BenchModelRun].
class AggregateMetrics {
  final double passRate; // % (0 - 100)
  final double passAt4Rate; // % (0 - 100)
  final double avgScore; // % (0 - 100)
  final double scoreSd; // Standard deviation of result scores %
  final double avgOutcome; // % (0 - 100)
  final double avgQuality; // % (0 - 100)
  final double avgDx; // % (0 - 100)
  final int avgTokens;
  final double avgCost;
  final int totalTasks;

  const AggregateMetrics({
    required this.passRate,
    required this.passAt4Rate,
    required this.avgScore,
    required this.scoreSd,
    required this.avgOutcome,
    required this.avgQuality,
    required this.avgDx,
    required this.avgTokens,
    required this.avgCost,
    required this.totalTasks,
  });

  static const AggregateMetrics empty = AggregateMetrics(
    passRate: 0.0,
    passAt4Rate: 0.0,
    avgScore: 0.0,
    scoreSd: 0.0,
    avgOutcome: 0.0,
    avgQuality: 0.0,
    avgDx: 0.0,
    avgTokens: 0,
    avgCost: 0.0,
    totalTasks: 0,
  );
}

/// Combined comparison entry holding both Baseline and AI Tooling metrics for a model.
class BenchComparisonEntry {
  final String agent;
  final String model;
  final BenchModelRun? baselineRun;
  final BenchModelRun? aiToolingRun;
  final AggregateMetrics baselineMetrics;
  final AggregateMetrics aiToolingMetrics;

  const BenchComparisonEntry({
    required this.agent,
    required this.model,
    required this.baselineRun,
    required this.aiToolingRun,
    required this.baselineMetrics,
    required this.aiToolingMetrics,
  });

  String get compositeKey => '$agent / $model';

  /// Delta in Pass Rate: AI Tooling - Baseline
  double get passRateDelta =>
      aiToolingMetrics.passRate - baselineMetrics.passRate;

  /// Delta in Pass@4 Rate: AI Tooling - Baseline
  double get passAt4Delta =>
      aiToolingMetrics.passAt4Rate - baselineMetrics.passAt4Rate;

  /// Delta in Avg Score: AI Tooling - Baseline
  double get avgScoreDelta =>
      aiToolingMetrics.avgScore - baselineMetrics.avgScore;

  /// Delta in Tokens: AI Tooling - Baseline
  int get tokensDelta => aiToolingMetrics.avgTokens - baselineMetrics.avgTokens;

  /// Delta in Cost: AI Tooling - Baseline
  double get costDelta => aiToolingMetrics.avgCost - baselineMetrics.avgCost;
}
