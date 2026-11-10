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
///
/// The header includes a [BenchVariantToggle] so the variant can be
/// changed without closing the drawer.
class BenchDetailDrawer extends StatelessComponent {
  const BenchDetailDrawer({
    required this.entry,
    required this.variant,
    required this.isOpen,
    required this.onClose,
    required this.onVariantChanged,
    super.key,
  });

  final BenchComparisonEntry? entry;
  final DisplayVariant variant;
  final bool isOpen;
  final VoidCallback onClose;
  final ValueChanged<DisplayVariant> onVariantChanged;

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
    final taskRows = _resolveTaskRows(currentEntry, showBoth: showBoth);

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
            div(classes: 'drawer-variant-toggle', [
              BenchVariantToggle(
                selectedVariant: variant,
                onVariantChanged: onVariantChanged,
              ),
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
                for (final row in taskRows)
                  tr([
                    td([
                      strong([.text(row.name)]),
                    ]),
                    td([
                      span(classes: 'category-tag ${row.category.value}', [
                        .text(row.category.label),
                      ]),
                    ]),
                    td(classes: 'num', [
                      _buildTaskCell(row, (t) => t.avgScore, bold: true),
                    ]),
                    td(classes: 'num', [
                      _buildTaskCell(row, (t) => t.avgOutcome),
                    ]),
                    td(classes: 'num', [
                      _buildTaskCell(row, (t) => t.avgQuality),
                    ]),
                    td(classes: 'num', [
                      _buildTaskCell(row, (t) => t.avgDx),
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
        return currentEntry.aiToolingMetrics;
      case DisplayVariant.both:
        // Only used when one of the runs is missing,
        // so fall back to whichever run exists.
        return currentEntry.aiToolingRun != null
            ? currentEntry.aiToolingMetrics
            : currentEntry.baselineMetrics;
    }
  }

  /// Builds the per-task rows for the active variant.
  ///
  /// When [showBoth] is true, tasks from the two runs are paired by
  /// [BenchTask.id] so each row shows baseline and AI tooling together.
  List<_TaskRow> _resolveTaskRows(
    BenchComparisonEntry currentEntry, {
    required bool showBoth,
  }) {
    final baselineTasks = currentEntry.baselineRun?.tasks ?? const [];
    final aiTasks = currentEntry.aiToolingRun?.tasks ?? const [];

    if (showBoth) {
      final baselineById = {for (final t in baselineTasks) t.id: t};
      final aiIds = {for (final t in aiTasks) t.id};
      return [
        for (final ai in aiTasks)
          _TaskRow(baseline: baselineById[ai.id], aiTooling: ai, paired: true),
        for (final base in baselineTasks)
          if (!aiIds.contains(base.id)) _TaskRow(baseline: base, paired: true),
      ];
    }

    final useBaseline = switch (variant) {
      DisplayVariant.baseline => true,
      DisplayVariant.aiTooling => false,
      DisplayVariant.both => currentEntry.aiToolingRun == null,
    };
    return useBaseline
        ? [for (final t in baselineTasks) _TaskRow(baseline: t)]
        : [for (final t in aiTasks) _TaskRow(aiTooling: t)];
  }

  /// Renders a numeric per-task cell.
  ///
  /// Paired rows use the same stacked "AI Tooling" / "Base" layout
  /// as the leaderboard table's Both mode.
  Component _buildTaskCell(
    _TaskRow row,
    double Function(BenchTask) metric, {
    bool bold = false,
  }) {
    String format(BenchTask? task) =>
        task == null ? '—' : BenchCalculator.formatPercent(metric(task) * 100);

    Component value(String text) => bold ? strong([.text(text)]) : .text(text);

    if (!row.paired) {
      return value(format(row.aiTooling ?? row.baseline));
    }

    return div(classes: 'both-cell-container', [
      div(classes: 'variant-item', [
        const span(classes: 'variant-badge badge-ai', [.text('Tooling')]),
        span([value(format(row.aiTooling))]),
      ]),
      div(classes: 'variant-item', [
        const span(classes: 'variant-badge badge-baseline', [.text('Base')]),
        span([value(format(row.baseline))]),
      ]),
    ]);
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

/// A row in the per-task table, holding a task from one or both variants.
class _TaskRow {
  const _TaskRow({this.baseline, this.aiTooling, this.paired = false})
    : assert(baseline != null || aiTooling != null);

  final BenchTask? baseline;
  final BenchTask? aiTooling;

  /// Whether to render baseline and AI tooling values side by side.
  final bool paired;

  BenchTask get _primary => (aiTooling ?? baseline)!;

  String get name => _primary.name;
  TaskCategory get category => _primary.category;
}
