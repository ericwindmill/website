// Copyright 2026, the Flutter authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that
// can be found in the LICENSE file.

/// Models for Flutter Bench results.
///
/// The results file is pre-aggregated: every run and task carries a
/// `metrics` object with the values the leaderboard renders.
/// These models read those values directly rather than recomputing them.
/// The raw `trials` are kept for per-trial detail views.
///
/// Parsing is strict. Frozen, reviewed data that doesn't match this shape
/// should fail the build rather than render placeholder values.
library;

/// Variants evaluated in Flutter Bench.
enum BenchVariant {
  baseline('baseline', 'Baseline'),
  enhanced('enhanced', 'Enhanced');

  const BenchVariant(this.value, this.label);

  final String value;
  final String label;

  static BenchVariant fromString(String value) =>
      _enumByValue(values, value, (v) => v.value, 'variant');
}

/// Horizon categories for Flutter Bench tasks.
enum TaskCategory {
  shortHorizon('short_horizon', 'Short horizon'),
  longHorizon('long_horizon', 'Long horizon');

  const TaskCategory(this.value, this.label);

  final String value;
  final String label;

  static TaskCategory fromString(String value) =>
      _enumByValue(values, value, (v) => v.value, 'category');
}

/// The result status of a single trial.
enum TrialStatus {
  passed('passed', 'Passed'),
  failed('failed', 'Failed'),
  timedOut('timed_out', 'Timed out'),
  errored('errored', 'Errored');

  const TrialStatus(this.value, this.label);

  final String value;
  final String label;

  static TrialStatus fromString(String value) =>
      _enumByValue(values, value, (v) => v.value, 'trial status');
}

/// The top-level contents of a Flutter Bench results file.
class BenchResults {
  const BenchResults({
    required this.schemaVersion,
    required this.snapshot,
    required this.runs,
  });

  factory BenchResults.fromJson(Map<String, Object?> json) => BenchResults(
    schemaVersion: json['schemaVersion'] as String,
    snapshot: BenchSnapshot.fromJson(_map(json['snapshot'])),
    runs: _list(json['runs'], BenchModelRun.fromJson),
  );

  final String schemaVersion;
  final BenchSnapshot snapshot;
  final List<BenchModelRun> runs;
}

/// Metadata describing when and how a set of results was produced.
class BenchSnapshot {
  const BenchSnapshot({
    required this.id,
    required this.label,
    required this.generatedAt,
    required this.status,
    required this.trialsPerTask,
    required this.scoring,
    required this.environment,
  });

  factory BenchSnapshot.fromJson(Map<String, Object?> json) => BenchSnapshot(
    id: json['id'] as String,
    label: json['label'] as String,
    generatedAt: DateTime.parse(json['generatedAt'] as String),
    status: json['status'] as String,
    trialsPerTask: (json['trialsPerTask'] as num).toInt(),
    scoring: BenchScoring.fromJson(_map(json['scoring'])),
    environment: BenchEnvironment.fromJson(_map(json['environment'])),
  );

  /// A stable identifier, such as `2026-q4`.
  final String id;

  /// A human-readable label, such as `Q4 2026`.
  final String label;

  final DateTime generatedAt;

  /// The publication status, such as `current`.
  final String status;

  /// The number of trials run per task, the K in Pass@K.
  final int trialsPerTask;

  final BenchScoring scoring;
  final BenchEnvironment environment;
}

/// The weights and thresholds used to compute result scores.
class BenchScoring {
  const BenchScoring({
    required this.outcomeWeight,
    required this.qualityWeight,
    required this.passThreshold,
  });

  factory BenchScoring.fromJson(Map<String, Object?> json) => BenchScoring(
    outcomeWeight: _double(json['outcomeWeight']),
    qualityWeight: _double(json['qualityWeight']),
    passThreshold: _double(json['passThreshold']),
  );

  /// The weight of the outcome score, from 0.0 to 1.0.
  final double outcomeWeight;

  /// The weight of the quality score, from 0.0 to 1.0.
  final double qualityWeight;

  /// The minimum trial outcome that counts as a pass.
  final double passThreshold;

  /// [outcomeWeight] as a whole-number percentage, such as `65`.
  int get outcomePercent => (outcomeWeight * 100).round();

  /// [qualityWeight] as a whole-number percentage, such as `35`.
  int get qualityPercent => (qualityWeight * 100).round();
}

/// The toolchain versions the results were produced with.
class BenchEnvironment {
  const BenchEnvironment({
    required this.flutterVersion,
    required this.dartVersion,
    required this.suiteVersion,
    required this.harnessVersion,
  });

  factory BenchEnvironment.fromJson(Map<String, Object?> json) =>
      BenchEnvironment(
        flutterVersion: json['flutterVersion'] as String,
        dartVersion: json['dartVersion'] as String,
        suiteVersion: json['suiteVersion'] as String,
        harnessVersion: json['harnessVersion'] as String,
      );

  final String flutterVersion;
  final String dartVersion;
  final String suiteVersion;
  final String harnessVersion;
}

/// An evaluation run for a specific agent and model under a single variant.
class BenchModelRun {
  const BenchModelRun({
    required this.agentId,
    required this.agent,
    required this.modelId,
    required this.model,
    required this.modelProvider,
    required this.variant,
    required this.startedAt,
    required this.completedAt,
    required this.metrics,
    required this.tasks,
  });

  factory BenchModelRun.fromJson(Map<String, Object?> json) => BenchModelRun(
    agentId: json['agentId'] as String,
    agent: json['agent'] as String,
    modelId: json['modelId'] as String,
    model: json['model'] as String,
    modelProvider: json['modelProvider'] as String,
    variant: BenchVariant.fromString(json['variant'] as String),
    startedAt: _dateTimeOrNull(json['startedAt']),
    completedAt: _dateTimeOrNull(json['completedAt']),
    metrics: BenchRunMetrics.fromJson(_map(json['metrics'])),
    tasks: _list(json['tasks'], BenchTask.fromJson),
  );

  final String agentId;
  final String agent;
  final String modelId;
  final String model;
  final String modelProvider;
  final BenchVariant variant;

  /// When the run started, or `null` if it hasn't run yet.
  final DateTime? startedAt;

  /// When the run completed, or `null` if it hasn't run yet.
  final DateTime? completedAt;

  final BenchRunMetrics metrics;
  final List<BenchTask> tasks;

  /// Whether this run has any task results.
  ///
  /// A run without results is a placeholder for an agent and model
  /// that's on the roster but hasn't been evaluated yet.
  bool get hasResults => tasks.isNotEmpty;

  /// A key that identifies the agent and model pairing across variants.
  String get pairingKey => '$agentId/$modelId';
}

/// Pre-aggregated metrics for a [BenchModelRun].
///
/// Scores and rates are percentages from 0 to 100.
/// Every nullable value is `null` when the run has no results.
class BenchRunMetrics {
  const BenchRunMetrics({
    required this.totalTasks,
    required this.passedTaskCount,
    required this.passAtKTaskCount,
    required this.passRate,
    required this.passAtKRate,
    required this.avgScore,
    required this.scoreSd,
    required this.avgOutcome,
    required this.avgQuality,
    required this.avgTokens,
    required this.avgCost,
  });

  factory BenchRunMetrics.fromJson(Map<String, Object?> json) =>
      BenchRunMetrics(
        totalTasks: (json['totalTasks'] as num).toInt(),
        passedTaskCount: (json['passedTaskCount'] as num).toInt(),
        passAtKTaskCount: (json['passAtKTaskCount'] as num).toInt(),
        passRate: _doubleOrNull(json['passRate']),
        passAtKRate: _doubleOrNull(json['passAtKRate']),
        avgScore: _doubleOrNull(json['avgScore']),
        scoreSd: _doubleOrNull(json['scoreSd']),
        avgOutcome: _doubleOrNull(json['avgOutcome']),
        avgQuality: _doubleOrNull(json['avgQuality']),
        avgTokens: (json['avgTokens'] as num?)?.round(),
        avgCost: _doubleOrNull(json['avgCost']),
      );

  final int totalTasks;

  /// The number of tasks where every trial passed.
  final int passedTaskCount;

  /// The number of tasks where at least one trial passed.
  final int passAtKTaskCount;

  final double? passRate;
  final double? passAtKRate;
  final double? avgScore;

  /// The sample standard deviation of task result scores.
  final double? scoreSd;

  final double? avgOutcome;
  final double? avgQuality;

  /// The mean token usage per task run.
  final int? avgTokens;

  /// The mean cost in USD per task run,
  /// or `null` if pricing isn't available for this model.
  final double? avgCost;
}

/// A benchmark task, its pre-aggregated metrics, and its raw trials.
class BenchTask {
  const BenchTask({
    required this.id,
    required this.name,
    required this.category,
    required this.metrics,
    required this.trials,
  });

  factory BenchTask.fromJson(Map<String, Object?> json) => BenchTask(
    id: json['id'] as String,
    name: json['name'] as String,
    category: TaskCategory.fromString(json['category'] as String),
    metrics: BenchTaskMetrics.fromJson(_map(json['metrics'])),
    trials: _list(json['trials'], BenchTrial.fromJson),
  );

  final String id;
  final String name;
  final TaskCategory category;
  final BenchTaskMetrics metrics;
  final List<BenchTrial> trials;
}

/// Pre-aggregated metrics for a [BenchTask].
///
/// Scores are percentages from 0 to 100.
class BenchTaskMetrics {
  const BenchTaskMetrics({
    required this.resultScore,
    required this.outcome,
    required this.quality,
    required this.passedTrialCount,
    required this.passedAnyTrial,
    required this.passedAllTrials,
    required this.meanTokens,
    required this.meanCost,
  });

  factory BenchTaskMetrics.fromJson(Map<String, Object?> json) =>
      BenchTaskMetrics(
        resultScore: _double(json['resultScore']),
        outcome: _double(json['outcome']),
        quality: _double(json['quality']),
        passedTrialCount: (json['passedTrialCount'] as num).toInt(),
        passedAnyTrial: json['passedAnyTrial'] as bool,
        passedAllTrials: json['passedAllTrials'] as bool,
        meanTokens: (json['meanTokens'] as num).round(),
        meanCost: _doubleOrNull(json['meanCost']),
      );

  final double resultScore;
  final double outcome;
  final double quality;
  final int passedTrialCount;
  final bool passedAnyTrial;
  final bool passedAllTrials;
  final int meanTokens;
  final double? meanCost;
}

/// A single trial execution of a benchmark task.
class BenchTrial {
  const BenchTrial({
    required this.trialIndex,
    required this.outcome,
    required this.quality,
    required this.tokens,
    required this.cost,
    required this.status,
    required this.durationSeconds,
  });

  factory BenchTrial.fromJson(Map<String, Object?> json) => BenchTrial(
    trialIndex: (json['trialIndex'] as num).toInt(),
    outcome: _doubleOrNull(json['outcome']),
    quality: _doubleOrNull(json['quality']),
    tokens: (json['tokens'] as num).toInt(),
    cost: _doubleOrNull(json['cost']),
    status: TrialStatus.fromString(json['status'] as String),
    durationSeconds: _double(json['durationSeconds']),
  );

  final int trialIndex;

  /// The outcome score from 0.0 to 1.0, or `null` if the trial errored.
  final double? outcome;

  /// The quality score from 0.0 to 1.0, or `null` if the trial errored.
  final double? quality;

  final int tokens;
  final double? cost;
  final TrialStatus status;
  final double durationSeconds;
}

/// The baseline and enhanced runs for a single agent and model pairing.
class BenchComparisonEntry {
  const BenchComparisonEntry({
    required this.agent,
    required this.model,
    required this.baselineRun,
    required this.enhancedRun,
  });

  final String agent;
  final String model;
  final BenchModelRun? baselineRun;
  final BenchModelRun? enhancedRun;

  /// Groups [runs] into one entry per agent and model pairing,
  /// in the order each pairing first appears.
  static List<BenchComparisonEntry> fromRuns(List<BenchModelRun> runs) {
    final baselineRuns = <String, BenchModelRun>{};
    final enhancedRuns = <String, BenchModelRun>{};
    final keys = <String>{};

    for (final run in runs) {
      final key = run.pairingKey;
      keys.add(key);
      final runsForVariant = switch (run.variant) {
        BenchVariant.baseline => baselineRuns,
        BenchVariant.enhanced => enhancedRuns,
      };
      if (runsForVariant.containsKey(key)) {
        throw FormatException(
          'Duplicate ${run.variant.value} run for "$key".',
        );
      }
      runsForVariant[key] = run;
    }

    return [
      for (final key in keys) _entryFor(baselineRuns[key], enhancedRuns[key]),
    ];
  }

  static BenchComparisonEntry _entryFor(
    BenchModelRun? baselineRun,
    BenchModelRun? enhancedRun,
  ) {
    final primary = (enhancedRun ?? baselineRun)!;
    return BenchComparisonEntry(
      agent: primary.agent,
      model: primary.model,
      baselineRun: baselineRun,
      enhancedRun: enhancedRun,
    );
  }

  String get displayKey => '$agent / $model';

  BenchRunMetrics? get baselineMetrics => baselineRun?.metrics;
  BenchRunMetrics? get enhancedMetrics => enhancedRun?.metrics;

  /// The metrics for [variant], or `null` if that run is missing.
  BenchRunMetrics? metricsFor(BenchVariant variant) => switch (variant) {
    BenchVariant.baseline => baselineMetrics,
    BenchVariant.enhanced => enhancedMetrics,
  };

  /// Enhanced minus baseline pass rate.
  double? get passRateDelta =>
      _delta(baselineMetrics?.passRate, enhancedMetrics?.passRate);

  /// Enhanced minus baseline Pass@K rate.
  double? get passAtKDelta =>
      _delta(baselineMetrics?.passAtKRate, enhancedMetrics?.passAtKRate);

  /// Enhanced minus baseline average score.
  double? get avgScoreDelta =>
      _delta(baselineMetrics?.avgScore, enhancedMetrics?.avgScore);

  /// Enhanced minus baseline average tokens.
  int? get tokensDelta {
    final baseline = baselineMetrics?.avgTokens;
    final enhanced = enhancedMetrics?.avgTokens;
    if (baseline == null || enhanced == null) return null;
    return enhanced - baseline;
  }

  /// Enhanced minus baseline average cost.
  double? get costDelta =>
      _delta(baselineMetrics?.avgCost, enhancedMetrics?.avgCost);

  static double? _delta(double? baseline, double? enhanced) {
    if (baseline == null || enhanced == null) return null;
    return enhanced - baseline;
  }
}

T _enumByValue<T>(
  List<T> values,
  String value,
  String Function(T) valueOf,
  String description,
) {
  for (final candidate in values) {
    if (valueOf(candidate) == value) return candidate;
  }
  throw FormatException('Unknown $description "$value".');
}

Map<String, Object?> _map(Object? value) => value as Map<String, Object?>;

List<T> _list<T>(Object? value, T Function(Map<String, Object?>) fromJson) => [
  for (final item in value as List<Object?>) fromJson(_map(item)),
];

double _double(Object? value) => (value as num).toDouble();

double? _doubleOrNull(Object? value) => (value as num?)?.toDouble();

DateTime? _dateTimeOrNull(Object? value) =>
    value == null ? null : DateTime.parse(value as String);
