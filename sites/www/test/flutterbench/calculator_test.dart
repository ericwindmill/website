// Copyright 2026, the Flutter authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that
// can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_website/src/models/content/flutter_bench.dart';
import 'package:flutter_website/src/utils/bench_calculator.dart';

void expect(dynamic actual, dynamic expected, [String message = '']) {
  if (actual != expected) {
    throw Exception(
      'Test failure: Expected <$expected> but got <$actual>. $message',
    );
  }
}

void expectClose(
  double actual,
  double expected,
  double epsilon, [
  String message = '',
]) {
  if ((actual - expected).abs() > epsilon) {
    throw Exception(
      'Test failure: Expected <$expected> (±$epsilon) but got <$actual>. $message',
    );
  }
}

void main() {
  print('Running Flutter Bench Calculator Tests...');

  // Test 1: Trial result score calculation
  {
    const trial = BenchTrial(
      trialIndex: 1,
      outcome: 1.0,
      quality: 0.90,
      dx: 0.80,
    );
    // 1.0 * 0.60 + 0.90 * 0.30 + 0.80 * 0.10 = 0.95
    expectClose(trial.resultScore, 0.95, 0.0001, 'Trial resultScore 60/30/10');
    expect(trial.isPassed, true, 'Trial isPassed');
    print('✓ Trial weighting (60/30/10) passed.');
  }

  // Test 2: Task calculations
  {
    const task = BenchTask(
      id: 'task-1',
      name: 'Test Task',
      category: TaskCategory.shortHorizon,
      tokens: 30000,
      cost: 0.06,
      trials: [
        BenchTrial(trialIndex: 1, outcome: 1.0, quality: 0.90, dx: 0.90),
        BenchTrial(trialIndex: 2, outcome: 1.0, quality: 0.80, dx: 0.80),
        BenchTrial(trialIndex: 3, outcome: 0.5, quality: 0.70, dx: 0.70),
        BenchTrial(trialIndex: 4, outcome: 0.5, quality: 0.80, dx: 0.80),
      ],
    );

    expect(task.avgOutcome, 0.75, 'avgOutcome');
    expect(task.passedAtLeastOnce, true, 'passedAtLeastOnce');
    expect(task.passedFully, false, 'passedFully');
    print('✓ Task metrics and pass criteria passed.');
  }

  // Test 3: Model run aggregate metrics
  {
    const run = BenchModelRun(
      agent: 'Antigravity',
      model: 'Gemini 2.5 Pro',
      variant: BenchVariant.aiTooling,
      tasks: [
        BenchTask(
          id: 't1',
          name: 'Task 1',
          category: TaskCategory.shortHorizon,
          tokens: 20000,
          cost: 0.04,
          trials: [
            BenchTrial(trialIndex: 1, outcome: 1.0, quality: 1.0, dx: 1.0),
            BenchTrial(trialIndex: 2, outcome: 1.0, quality: 1.0, dx: 1.0),
            BenchTrial(trialIndex: 3, outcome: 1.0, quality: 1.0, dx: 1.0),
            BenchTrial(trialIndex: 4, outcome: 1.0, quality: 1.0, dx: 1.0),
          ],
        ),
        BenchTask(
          id: 't2',
          name: 'Task 2',
          category: TaskCategory.longHorizon,
          tokens: 40000,
          cost: 0.08,
          trials: [
            BenchTrial(trialIndex: 1, outcome: 0.0, quality: 0.5, dx: 0.5),
            BenchTrial(trialIndex: 2, outcome: 1.0, quality: 0.9, dx: 0.9),
            BenchTrial(trialIndex: 3, outcome: 0.0, quality: 0.4, dx: 0.4),
            BenchTrial(trialIndex: 4, outcome: 0.0, quality: 0.4, dx: 0.4),
          ],
        ),
      ],
    );

    final metrics = BenchCalculator.computeMetrics(run);
    expect(metrics.passRate, 50.0, 'passRate');
    expect(metrics.passAt4Rate, 100.0, 'passAt4Rate');
    expect(metrics.avgTokens, 30000, 'avgTokens');
    expectClose(metrics.avgCost, 0.06, 0.0001, 'avgCost');
    print('✓ Run aggregate metrics (Pass Rate & Pass@4) passed.');
  }

  // Test 4: Comparison entries and deltas
  {
    const baselineRun = BenchModelRun(
      agent: 'Claude Code',
      model: 'Claude 3.7 Sonnet',
      variant: BenchVariant.baseline,
      tasks: [
        BenchTask(
          id: 't1',
          name: 'Task 1',
          category: TaskCategory.shortHorizon,
          tokens: 50000,
          cost: 0.15,
          trials: [
            BenchTrial(trialIndex: 1, outcome: 0.5, quality: 0.5, dx: 0.5),
            BenchTrial(trialIndex: 2, outcome: 0.5, quality: 0.5, dx: 0.5),
            BenchTrial(trialIndex: 3, outcome: 0.5, quality: 0.5, dx: 0.5),
            BenchTrial(trialIndex: 4, outcome: 0.5, quality: 0.5, dx: 0.5),
          ],
        ),
      ],
    );

    const aiToolingRun = BenchModelRun(
      agent: 'Claude Code',
      model: 'Claude 3.7 Sonnet',
      variant: BenchVariant.aiTooling,
      tasks: [
        BenchTask(
          id: 't1',
          name: 'Task 1',
          category: TaskCategory.shortHorizon,
          tokens: 30000,
          cost: 0.09,
          trials: [
            BenchTrial(trialIndex: 1, outcome: 1.0, quality: 1.0, dx: 1.0),
            BenchTrial(trialIndex: 2, outcome: 1.0, quality: 1.0, dx: 1.0),
            BenchTrial(trialIndex: 3, outcome: 1.0, quality: 1.0, dx: 1.0),
            BenchTrial(trialIndex: 4, outcome: 1.0, quality: 1.0, dx: 1.0),
          ],
        ),
      ],
    );

    final comparisons = BenchCalculator.buildComparisonEntries([
      baselineRun,
      aiToolingRun,
    ]);

    expect(comparisons.length, 1, 'comparisons.length');
    final comp = comparisons.first;
    expect(comp.agent, 'Claude Code', 'agent');
    expect(comp.model, 'Claude 3.7 Sonnet', 'model');
    expect(comp.passRateDelta, 100.0, 'passRateDelta');
    expect(comp.tokensDelta, -20000, 'tokensDelta');
    expectClose(comp.costDelta, -0.06, 0.0001, 'costDelta');
    print('✓ Comparison deltas (Baseline vs AI Tooling) passed.');
  }

  // Test 5: Formatting helpers
  {
    expect(BenchCalculator.formatPercent(85.4), '85.4%');
    expect(BenchCalculator.formatPercent(85.426, decimals: 2), '85.43%');
    expect(BenchCalculator.formatScoreWithSd(85.4, 4.2), '85.4% ± 4.2%');
    expect(BenchCalculator.formatTokens(1234567), '1,234,567');
    expect(BenchCalculator.formatTokens(42000), '42,000');
    expect(BenchCalculator.formatTokens(500), '500');
    expect(BenchCalculator.formatCost(0.125), '\$0.125');
    expect(BenchCalculator.formatDelta(15.2), '+15.2%');
    expect(BenchCalculator.formatDelta(-8.4), '-8.4%');
    print('✓ Formatting helpers passed.');
  }

  // Test 6: Verify actual results.json
  {
    final file = File('content/flutterbench/results.json');
    expect(file.existsSync(), true, 'results.json exists');

    final jsonString = file.readAsStringSync();
    final list = jsonDecode(jsonString) as List<dynamic>;
    expect(list.isNotEmpty, true, 'results.json not empty');

    final runs = list
        .map((item) => BenchModelRun.fromJson(item as Map<String, Object?>))
        .toList();

    expect(runs.length, 12, '12 total model runs (6 models * 2 variants)');

    final comparisons = BenchCalculator.buildComparisonEntries(runs);
    expect(comparisons.length, 6, '6 unique models in launch roster');

    final modelNames = comparisons.map((c) => '${c.agent}: ${c.model}').toSet();
    expect(
      modelNames.contains('Antigravity: Gemini 2.5 Pro'),
      true,
      'Antigravity Gemini 2.5 Pro',
    );
    expect(
      modelNames.contains('Antigravity: Gemini 2.5 Flash'),
      true,
      'Antigravity Gemini 2.5 Flash',
    );
    expect(
      modelNames.contains('Claude Code: Claude 3.7 Sonnet'),
      true,
      'Claude 3.7 Sonnet',
    );
    expect(
      modelNames.contains('Claude Code: Claude 3.5 Haiku'),
      true,
      'Claude 3.5 Haiku',
    );
    expect(modelNames.contains('Codex: GPT-4.5'), true, 'Codex GPT-4.5');
    expect(modelNames.contains('Codex: GPT-4o'), true, 'Codex GPT-4o');
    expect(modelNames.contains('Codex: o3-mini'), false, 'o3-mini removed');

    for (final comp in comparisons) {
      expect(comp.baselineMetrics.totalTasks, 7, '7 tasks in baseline');
      expect(comp.aiToolingMetrics.totalTasks, 7, '7 tasks in aiTooling');
      expect(
        comp.aiToolingMetrics.passRate >= comp.baselineMetrics.passRate,
        true,
        'AI Tooling pass rate >= baseline',
      );
    }

    final firstRunTasks = runs.first.tasks;
    final taskNames = firstRunTasks.map((t) => t.name).toList();
    expect(taskNames.contains('Fix RenderFlex Overflow'), true, 'CUJ 1');
    expect(
      taskNames.contains('Navigation with Adaptive Layout'),
      true,
      'CUJ 2',
    );
    expect(
      taskNames.contains('REST API Client: Fetch JSON with http'),
      true,
      'CUJ 3',
    );
    expect(taskNames.contains('Provider State Management'), true, 'CUJ 4');
    expect(taskNames.contains('Firebase Cloud Storage'), true, 'CUJ 5');
    expect(taskNames.contains('Dart Genkit Cloud Function'), true, 'CUJ 6');
    expect(taskNames.contains('Internationalization (i18n)'), true, 'CUJ 7');
    print('✓ results.json launch roster and 7 CUJ task trials validated.');
  }

  print('\nALL FLUTTER BENCH TESTS PASSED SUCCESSFULLY! 🎉');
}
