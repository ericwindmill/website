// Copyright 2026, the Flutter authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that
// can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_website/src/models/content/flutter_bench.dart';
import 'package:test/test.dart';

void main() {
  group('BenchResults.fromJson', () {
    test('parses the envelope, snapshot, runs, tasks, and trials', () {
      final results = BenchResults.fromJson(_resultsJson());

      expect(results.schemaVersion, '2.0');
      expect(results.snapshot.label, 'Q4 2026');
      expect(results.snapshot.trialsPerTask, 4);
      expect(results.snapshot.scoring.outcomePercent, 65);
      expect(results.snapshot.scoring.qualityPercent, 35);
      expect(results.snapshot.environment.flutterVersion, '3.50.0');

      final [baseline, enhanced] = results.runs;
      expect(baseline.variant, BenchVariant.baseline);
      expect(enhanced.variant, BenchVariant.enhanced);
      expect(enhanced.metrics.passAtKRate, 100.0);
      expect(enhanced.metrics.avgTokens, 1500);
      expect(enhanced.metrics.avgCost, isNull);

      final task = enhanced.tasks.single;
      expect(task.category, TaskCategory.longHorizon);
      expect(task.metrics.resultScore, 90.0);
      expect(task.metrics.meanCost, isNull);

      final errored = task.trials.last;
      expect(errored.status, TrialStatus.errored);
      expect(errored.outcome, isNull);
      expect(errored.quality, isNull);
    });

    test('throws on an unknown variant', () {
      final json = _resultsJson();
      _runs(json).first['variant'] = 'ai_tooling';
      expect(() => BenchResults.fromJson(json), throwsFormatException);
    });

    test('throws on an unknown trial status', () {
      final json = _resultsJson();
      final task = (_runs(json).first['tasks'] as List).first as Map;
      ((task['trials'] as List).first as Map)['status'] = 'skipped';
      expect(() => BenchResults.fromJson(json), throwsFormatException);
    });

    test('throws when metrics are missing', () {
      final json = _resultsJson();
      _runs(json).first.remove('metrics');
      expect(() => BenchResults.fromJson(json), throwsA(isA<TypeError>()));
    });
  });

  group('BenchComparisonEntry', () {
    test('pairs baseline and enhanced runs and computes deltas', () {
      final results = BenchResults.fromJson(_resultsJson());
      final [entry] = BenchComparisonEntry.fromRuns(results.runs);

      expect(entry.agent, 'Antigravity');
      expect(entry.model, 'Gemini 4 Argon');
      expect(entry.passRateDelta, 0.0);
      expect(entry.passAtKDelta, 100.0);
      expect(entry.tokensDelta, 500);
      expect(entry.costDelta, isNull, reason: 'enhanced cost is unavailable');
    });

    test('leaves a missing variant null', () {
      final results = BenchResults.fromJson(_resultsJson());
      final [entry] = BenchComparisonEntry.fromRuns([results.runs.first]);

      expect(entry.enhancedRun, isNull);
      expect(entry.enhancedMetrics, isNull);
      expect(entry.passRateDelta, isNull);
    });

    test('throws on duplicate runs for the same variant', () {
      final results = BenchResults.fromJson(_resultsJson());
      final run = results.runs.first;
      expect(
        () => BenchComparisonEntry.fromRuns([run, run]),
        throwsFormatException,
      );
    });
  });

  group('content/flutterbench/results.json', () {
    final results = BenchResults.fromJson(
      jsonDecode(File('content/flutterbench/results.json').readAsStringSync())
          as Map<String, Object?>,
    );
    final scoring = results.snapshot.scoring;

    test('parses and pairs every run', () {
      expect(results.runs, isNotEmpty);
      final entries = BenchComparisonEntry.fromRuns(results.runs);
      for (final entry in entries) {
        expect(entry.baselineRun, isNotNull, reason: entry.displayKey);
        expect(entry.enhancedRun, isNotNull, reason: entry.displayKey);
      }
    });

    test('includes the full agent and model roster', () {
      expect(
        {for (final run in results.runs) run.pairingKey},
        unorderedEquals([
          'antigravity/gemini-3-8-flash',
          'antigravity/gemini-4-argon',
          'antigravity/gemini-4-carbon',
          'claude-code/claude-opus-5-5',
          'claude-code/claude-sonnet-5-5',
          'codex/gpt-6-1-sol',
          'codex/gpt-6-astra',
        ]),
      );
    });

    test('scoring weights sum to 1.0', () {
      expect(scoring.outcomeWeight + scoring.qualityWeight, closeTo(1.0, 1e-9));
    });

    // The UI renders the pre-aggregated metrics as-is.
    // These checks re-derive them from the raw trials
    // to catch mistakes in the published data.
    for (final run in results.runs) {
      final label = '${run.agent} / ${run.model} (${run.variant.value})';

      test('$label: every task has trialsPerTask trials', () {
        for (final task in run.tasks) {
          expect(
            task.trials,
            hasLength(results.snapshot.trialsPerTask),
            reason: task.id,
          );
        }
      });

      test('$label: task metrics match their trials', () {
        for (final task in run.tasks) {
          // Timed-out and errored trials are excluded from score means.
          final scored = task.trials
              .where(
                (t) =>
                    t.status == TrialStatus.passed ||
                    t.status == TrialStatus.failed,
              )
              .toList();
          final outcome = _mean(scored.map((t) => t.outcome!)) * 100;
          final quality = _mean(scored.map((t) => t.quality!)) * 100;
          final passed = task.trials
              .where((t) => t.status == TrialStatus.passed)
              .length;

          expect(task.metrics.outcome, closeTo(outcome, _tolerance));
          expect(task.metrics.quality, closeTo(quality, _tolerance));
          expect(
            task.metrics.resultScore,
            closeTo(
              outcome * scoring.outcomeWeight + quality * scoring.qualityWeight,
              _tolerance,
            ),
            reason: task.id,
          );
          expect(task.metrics.passedTrialCount, passed, reason: task.id);
          expect(task.metrics.passedAnyTrial, passed > 0, reason: task.id);
          expect(
            task.metrics.passedAllTrials,
            passed == task.trials.length,
            reason: task.id,
          );
        }
      });

      test('$label: run metrics match their tasks', () {
        final metrics = run.metrics;
        final tasks = run.tasks;

        if (!run.hasResults) {
          // Placeholder runs must not claim any results.
          expect(run.startedAt, isNull);
          expect(run.completedAt, isNull);
          expect(metrics.totalTasks, 0);
          expect(metrics.passedTaskCount, 0);
          expect(metrics.passAtKTaskCount, 0);
          expect(
            [
              metrics.passRate,
              metrics.passAtKRate,
              metrics.avgScore,
              metrics.scoreSd,
              metrics.avgOutcome,
              metrics.avgQuality,
              metrics.avgTokens,
              metrics.avgCost,
            ],
            everyElement(isNull),
          );
          return;
        }

        final scores = [for (final t in tasks) t.metrics.resultScore];
        final passedAll = tasks.where((t) => t.metrics.passedAllTrials).length;
        final passedAny = tasks.where((t) => t.metrics.passedAnyTrial).length;

        expect(run.startedAt, isNotNull);
        expect(run.completedAt, isNotNull);
        expect(metrics.totalTasks, tasks.length);
        expect(metrics.passedTaskCount, passedAll);
        expect(metrics.passAtKTaskCount, passedAny);
        expect(
          metrics.passRate,
          closeTo(passedAll / tasks.length * 100, _tolerance),
        );
        expect(
          metrics.passAtKRate,
          closeTo(passedAny / tasks.length * 100, _tolerance),
        );
        expect(metrics.avgScore, closeTo(_mean(scores), _tolerance));
        expect(metrics.scoreSd, closeTo(_sampleSd(scores), _tolerance));
        expect(
          metrics.avgOutcome,
          closeTo(_mean(tasks.map((t) => t.metrics.outcome)), _tolerance),
        );
        expect(
          metrics.avgQuality,
          closeTo(_mean(tasks.map((t) => t.metrics.quality)), _tolerance),
        );
      });
    }
  });
}

/// Allows for rounding in the published metrics.
const _tolerance = 0.01;

double _mean(Iterable<double> values) =>
    values.reduce((a, b) => a + b) / values.length;

double _sampleSd(List<double> values) {
  if (values.length < 2) return 0;
  final mean = _mean(values);
  final variance =
      values.map((v) => math.pow(v - mean, 2)).reduce((a, b) => a + b) /
      (values.length - 1);
  return math.sqrt(variance);
}

List<Map<String, Object?>> _runs(Map<String, Object?> json) =>
    (json['runs'] as List).cast<Map<String, Object?>>();

/// A minimal results file with one baseline and one enhanced run.
Map<String, Object?> _resultsJson() =>
    jsonDecode(jsonEncode(_fixture)) as Map<String, Object?>;

const Map<String, Object?> _fixture = {
  'schemaVersion': '2.0',
  'snapshot': {
    'id': '2026-q4',
    'label': 'Q4 2026',
    'generatedAt': '2026-11-10T18:33:12Z',
    'status': 'current',
    'trialsPerTask': 4,
    'scoring': {
      'outcomeWeight': 0.65,
      'qualityWeight': 0.35,
      'passThreshold': 1.0,
    },
    'environment': {
      'flutterVersion': '3.50.0',
      'dartVersion': '3.14.0',
      'suiteVersion': 'dash-evals@abc',
      'harnessVersion': 'harbor@def',
    },
  },
  'runs': [
    {
      'agentId': 'antigravity',
      'agent': 'Antigravity',
      'modelId': 'gemini-4-argon',
      'model': 'Gemini 4 Argon',
      'modelProvider': 'Google',
      'variant': 'baseline',
      'startedAt': '2026-11-10T00:00:00Z',
      'completedAt': '2026-11-10T01:00:00Z',
      'metrics': {
        'totalTasks': 1,
        'passedTaskCount': 0,
        'passAtKTaskCount': 0,
        'passRate': 0.0,
        'passAtKRate': 0.0,
        'avgScore': 50.0,
        'scoreSd': 0.0,
        'avgOutcome': 50.0,
        'avgQuality': 50.0,
        'avgTokens': 1000.0,
        'avgCost': 1.25,
      },
      'tasks': [
        {
          'id': 'add-web-support',
          'name': 'Add Web Support',
          'category': 'long_horizon',
          'metrics': {
            'resultScore': 50.0,
            'outcome': 50.0,
            'quality': 50.0,
            'passedTrialCount': 0,
            'passedAnyTrial': false,
            'passedAllTrials': false,
            'meanTokens': 1000.0,
            'meanCost': 1.25,
          },
          'trials': [
            {
              'trialIndex': 1,
              'outcome': 0.5,
              'quality': 0.5,
              'tokens': 1000,
              'cost': 1.25,
              'status': 'failed',
              'durationSeconds': 60.0,
            },
          ],
        },
      ],
    },
    {
      'agentId': 'antigravity',
      'agent': 'Antigravity',
      'modelId': 'gemini-4-argon',
      'model': 'Gemini 4 Argon',
      'modelProvider': 'Google',
      'variant': 'enhanced',
      'startedAt': '2026-11-10T00:00:00Z',
      'completedAt': '2026-11-10T01:00:00Z',
      'metrics': {
        'totalTasks': 1,
        'passedTaskCount': 0,
        'passAtKTaskCount': 1,
        'passRate': 0.0,
        'passAtKRate': 100.0,
        'avgScore': 90.0,
        'scoreSd': 0.0,
        'avgOutcome': 90.0,
        'avgQuality': 90.0,
        'avgTokens': 1500.0,
        'avgCost': null,
      },
      'tasks': [
        {
          'id': 'add-web-support',
          'name': 'Add Web Support',
          'category': 'long_horizon',
          'metrics': {
            'resultScore': 90.0,
            'outcome': 90.0,
            'quality': 90.0,
            'passedTrialCount': 1,
            'passedAnyTrial': true,
            'passedAllTrials': false,
            'meanTokens': 1500.0,
            'meanCost': null,
          },
          'trials': [
            {
              'trialIndex': 1,
              'outcome': 1.0,
              'quality': 0.9,
              'tokens': 1500,
              'cost': null,
              'status': 'passed',
              'durationSeconds': 60.0,
            },
            {
              'trialIndex': 2,
              'outcome': null,
              'quality': null,
              'tokens': 0,
              'cost': null,
              'status': 'errored',
              'durationSeconds': 5.0,
            },
          ],
        },
      ],
    },
  ],
};
