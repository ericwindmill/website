// Copyright 2026, the Flutter authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that
// can be found in the LICENSE file.

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../models/content/flutter_bench.dart';
import '../../utils/bench_calculator.dart';
import 'bench_controls.dart';

/// Slide-over detail drawer for in-depth inspection of a selected model/agent run.
///
/// Displays:
/// 1. Top-level metric summary cards.
/// 2. Outcome (60%) / Quality (30%) / DX (10%) breakdown cards (Android Bench pattern).
/// 3. Per-task breakdown table respecting the active variant.
class BenchDetailDrawer extends StatelessComponent {
  const BenchDetailDrawer({
    required this.entry,
    required this.variant,
    required this.isOpen,
    required this.onClose,
    super.key,
  });

  final BenchComparisonEntry? entry;
  final DisplayVariant variant;
  final bool isOpen;
  final VoidCallback onClose;

  @override
  Component build(BuildContext context) {
    if (entry == null) {
      return const div(classes: 'bench-drawer-backdrop', []);
    }

    final currentEntry = entry!;
    final showBoth =
        variant == DisplayVariant.both &&
        currentEntry.baselineRun != null &&
        currentEntry.aiToolingRun != null;
    final baselineMetrics = currentEntry.baselineMetrics;
    final aiToolingMetrics = currentEntry.aiToolingMetrics;
    final activeMetrics = _resolveActiveMetrics(currentEntry);
    final activeTasks = _resolveActiveTasks(currentEntry);

    return div(classes: 'bench-drawer-root', [
      // Backdrop overlay
      div(
        classes: 'bench-drawer-backdrop ${isOpen ? 'open' : ''}',
        events: events(onClick: onClose),
        const [],
      ),

      // Slide-over drawer panel
      div(classes: 'bench-drawer-panel ${isOpen ? 'open' : ''}', [
        // Drawer Header
        div(classes: 'drawer-header', [
          div(classes: 'drawer-title-group', [
            span(classes: 'drawer-agent-badge', [.text(currentEntry.agent)]),
            h2(classes: 'drawer-model-title', [.text(currentEntry.model)]),
            span(classes: 'drawer-variant-subtitle', [
              .text('Viewing mode: ${variant.label}'),
            ]),
          ]),
          button(
            classes: 'drawer-close-btn',
            events: events(onClick: onClose),
            const [.text('✕')],
          ),
        ]),

        // Drawer Body
        div(classes: 'drawer-body', [
          // Section 1: Summary Top-level Metrics
          const h3(classes: 'section-heading', [.text('Performance Overview')]),
          if (showBoth) ...[
            // Both mode: show baseline and AI tooling side by side
            div(classes: 'both-metrics-section', [
              div(classes: 'both-metrics-column', [
                const div(classes: 'both-metrics-label baseline-label', [
                  .text('Baseline'),
                ]),
                div(classes: 'metric-cards-grid', [
                  _buildSummaryCard(
                    label: 'Pass Rate',
                    value: BenchCalculator.formatPercent(
                      baselineMetrics.passRate,
                    ),
                  ),
                  _buildSummaryCard(
                    label: 'Pass@4',
                    value: BenchCalculator.formatPercent(
                      baselineMetrics.passAt4Rate,
                    ),
                  ),
                  _buildSummaryCard(
                    label: 'Avg Score',
                    value: BenchCalculator.formatScoreWithSd(
                      baselineMetrics.avgScore,
                      baselineMetrics.scoreSd,
                    ),
                  ),
                  _buildSummaryCard(
                    label: 'Avg Tokens',
                    value: BenchCalculator.formatTokens(
                      baselineMetrics.avgTokens,
                    ),
                  ),
                  _buildSummaryCard(
                    label: 'Avg Cost',
                    value: BenchCalculator.formatCost(baselineMetrics.avgCost),
                  ),
                ]),
              ]),
              div(classes: 'both-metrics-column', [
                const div(classes: 'both-metrics-label ai-label', [
                  .text('With AI Tooling'),
                ]),
                div(classes: 'metric-cards-grid', [
                  _buildSummaryCard(
                    label: 'Pass Rate',
                    value: BenchCalculator.formatPercent(
                      aiToolingMetrics.passRate,
                    ),
                  ),
                  _buildSummaryCard(
                    label: 'Pass@4',
                    value: BenchCalculator.formatPercent(
                      aiToolingMetrics.passAt4Rate,
                    ),
                  ),
                  _buildSummaryCard(
                    label: 'Avg Score',
                    value: BenchCalculator.formatScoreWithSd(
                      aiToolingMetrics.avgScore,
                      aiToolingMetrics.scoreSd,
                    ),
                  ),
                  _buildSummaryCard(
                    label: 'Avg Tokens',
                    value: BenchCalculator.formatTokens(
                      aiToolingMetrics.avgTokens,
                    ),
                  ),
                  _buildSummaryCard(
                    label: 'Avg Cost',
                    value: BenchCalculator.formatCost(aiToolingMetrics.avgCost),
                  ),
                ]),
              ]),
            ]),
          ] else ...[
            div(classes: 'metric-cards-grid', [
              _buildSummaryCard(
                label: 'Pass Rate',
                value: BenchCalculator.formatPercent(activeMetrics.passRate),
              ),
              _buildSummaryCard(
                label: 'Pass@4 Rate',
                value: BenchCalculator.formatPercent(activeMetrics.passAt4Rate),
              ),
              _buildSummaryCard(
                label: 'Avg Score',
                value: BenchCalculator.formatScoreWithSd(
                  activeMetrics.avgScore,
                  activeMetrics.scoreSd,
                ),
              ),
              _buildSummaryCard(
                label: 'Avg Tokens',
                value: BenchCalculator.formatTokens(activeMetrics.avgTokens),
              ),
              _buildSummaryCard(
                label: 'Avg Cost',
                value: BenchCalculator.formatCost(activeMetrics.avgCost),
              ),
            ]),
          ],

          // Section 2: Outcome / Quality / DX Breakdown
          const h3(classes: 'section-heading', [
            .text('Result Score Breakdown (60% / 30% / 10%)'),
          ]),
          if (showBoth) ...[
            div(classes: 'both-metrics-section', [
              div(classes: 'both-metrics-column', [
                const div(classes: 'both-metrics-label baseline-label', [
                  .text('Baseline'),
                ]),
                div(classes: 'breakdown-cards-grid', [
                  _buildBreakdownCard(
                    'Outcome (60%)',
                    'pill-outcome',
                    BenchCalculator.formatPercent(baselineMetrics.avgOutcome),
                  ),
                  _buildBreakdownCard(
                    'Quality (30%)',
                    'pill-quality',
                    BenchCalculator.formatPercent(baselineMetrics.avgQuality),
                  ),
                  _buildBreakdownCard(
                    'Dev Experience (10%)',
                    'pill-dx',
                    BenchCalculator.formatPercent(baselineMetrics.avgDx),
                  ),
                ]),
              ]),
              div(classes: 'both-metrics-column', [
                const div(classes: 'both-metrics-label ai-label', [
                  .text('With AI Tooling'),
                ]),
                div(classes: 'breakdown-cards-grid', [
                  _buildBreakdownCard(
                    'Outcome (60%)',
                    'pill-outcome',
                    BenchCalculator.formatPercent(aiToolingMetrics.avgOutcome),
                  ),
                  _buildBreakdownCard(
                    'Quality (30%)',
                    'pill-quality',
                    BenchCalculator.formatPercent(aiToolingMetrics.avgQuality),
                  ),
                  _buildBreakdownCard(
                    'Dev Experience (10%)',
                    'pill-dx',
                    BenchCalculator.formatPercent(aiToolingMetrics.avgDx),
                  ),
                ]),
              ]),
            ]),
          ] else ...[
            div(classes: 'breakdown-cards-grid', [
              _buildBreakdownCard(
                'Outcome (60%)',
                'pill-outcome',
                BenchCalculator.formatPercent(activeMetrics.avgOutcome),
              ),
              _buildBreakdownCard(
                'Quality (30%)',
                'pill-quality',
                BenchCalculator.formatPercent(activeMetrics.avgQuality),
              ),
              _buildBreakdownCard(
                'Dev Experience (10%)',
                'pill-dx',
                BenchCalculator.formatPercent(activeMetrics.avgDx),
              ),
            ]),
          ],

          // Section 3: Per-task table
          const h3(classes: 'section-heading', [
            .text('Benchmark Tasks Breakdown'),
          ]),
          div(classes: 'per-task-table-wrapper', [
            table(classes: 'per-task-table', [
              const thead([
                tr([
                  th([.text('Task Name')]),
                  th([.text('Category')]),
                  th(classes: 'num', [.text('Result Score')]),
                  th(classes: 'num', [.text('Outcome')]),
                  th(classes: 'num', [.text('Quality')]),
                  th(classes: 'num', [.text('DX')]),
                ]),
              ]),
              tbody([
                for (final task in activeTasks)
                  tr([
                    td([
                      strong([.text(task.name)]),
                    ]),
                    td([
                      span(classes: 'category-tag ${task.category.value}', [
                        .text(task.category.label),
                      ]),
                    ]),
                    td(classes: 'num', [
                      strong([
                        .text(
                          BenchCalculator.formatPercent(task.avgScore * 100),
                        ),
                      ]),
                    ]),
                    td(classes: 'num', [
                      .text(
                        BenchCalculator.formatPercent(task.avgOutcome * 100),
                      ),
                    ]),
                    td(classes: 'num', [
                      .text(
                        BenchCalculator.formatPercent(task.avgQuality * 100),
                      ),
                    ]),
                    td(classes: 'num', [
                      .text(BenchCalculator.formatPercent(task.avgDx * 100)),
                    ]),
                  ]),
              ]),
            ]),
          ]),
        ]),
      ]),
    ]);
  }

  AggregateMetrics _resolveActiveMetrics(BenchComparisonEntry currentEntry) {
    switch (variant) {
      case DisplayVariant.baseline:
        return currentEntry.baselineMetrics;
      case DisplayVariant.aiTooling:
      case DisplayVariant.both:
        return currentEntry.aiToolingMetrics;
    }
  }

  List<BenchTask> _resolveActiveTasks(BenchComparisonEntry currentEntry) {
    switch (variant) {
      case DisplayVariant.baseline:
        return currentEntry.baselineRun?.tasks ?? const [];
      case DisplayVariant.aiTooling:
      case DisplayVariant.both:
        return currentEntry.aiToolingRun?.tasks ?? const [];
    }
  }

  Component _buildSummaryCard({required String label, required String value}) {
    return div(classes: 'summary-metric-card', [
      span(classes: 'card-label', [.text(label)]),
      span(classes: 'card-value', [.text(value)]),
    ]);
  }

  Component _buildBreakdownCard(
    String label,
    String pillClass,
    String value,
  ) {
    return div(classes: 'breakdown-card', [
      span(classes: 'pill-label $pillClass', [.text(label)]),
      span(classes: 'large-value', [.text(value)]),
    ]);
  }
}
