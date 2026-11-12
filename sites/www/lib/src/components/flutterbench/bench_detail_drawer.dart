// Copyright 2026, the Flutter authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that
// can be found in the LICENSE file.

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../models/content/flutter_bench.dart';
import '../../utils/bench_format.dart';
import 'bench_controls.dart';

/// Slide-over detail drawer for in-depth inspection of a selected model/agent run.
///
/// Displays:
/// 1. Top-level metric summary cards.
/// 2. Outcome / Quality breakdown cards, weighted by the snapshot's scoring.
/// 3. Per-task breakdown table respecting the active variant.
///
/// The drawer renders whichever [variant] it's given and doesn't
/// display a [BenchVariantToggle] while only baseline results are shown.
class BenchDetailDrawer extends StatelessComponent {
  const BenchDetailDrawer({
    required this.entry,
    required this.snapshot,
    required this.variant,
    required this.isOpen,
    required this.onClose,
    super.key,
  });

  final BenchComparisonEntry? entry;

  /// Snapshot metadata, used for the Pass@K label and scoring weights.
  final BenchSnapshot snapshot;

  final DisplayVariant variant;
  final bool isOpen;
  final VoidCallback onClose;

  int get _k => snapshot.trialsPerTask;
  BenchScoring get _scoring => snapshot.scoring;

  @override
  Component build(BuildContext context) {
    final currentEntry = entry;
    if (currentEntry == null) {
      return const div(classes: 'bench-drawer-backdrop', []);
    }

    final showBoth =
        variant == DisplayVariant.both &&
        currentEntry.baselineRun != null &&
        currentEntry.enhancedRun != null;
    final activeMetrics = currentEntry.metricsFor(
      _resolveActiveVariant(currentEntry),
    );
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
          if (showBoth)
            _buildBothColumns(
              currentEntry,
              _buildSummaryCards,
            )
          else
            _buildSummaryCards(activeMetrics),

          // Section 2: Outcome / Quality Breakdown
          h3(classes: 'section-heading', [
            .text(
              'Result Score Breakdown '
              '(${_scoring.outcomePercent}% / ${_scoring.qualityPercent}%)',
            ),
          ]),
          if (showBoth)
            _buildBothColumns(
              currentEntry,
              _buildBreakdownCards,
            )
          else
            _buildBreakdownCards(activeMetrics),

          // Section 3: Per-task table
          const h3(classes: 'section-heading', [
            .text('Benchmark Tasks Breakdown'),
          ]),
          div(classes: 'per-task-table-wrapper', [
            table(classes: 'per-task-table', [
              thead([
                tr([
                  const th([.text('Task Name')]),
                  const th(classes: 'num', [.text('Result Score')]),
                  const th(classes: 'num', [.text('Outcome')]),
                  const th(classes: 'num', [.text('Quality')]),
                  th(classes: 'num', [.text('Passed / $_k')]),
                  const th(classes: 'num', [.text('Avg Tokens')]),
                ]),
              ]),
              tbody([
                if (taskRows.isEmpty)
                  const tr([
                    td(
                      attributes: {'colspan': '6'},
                      [.text('No results yet for this agent and model.')],
                    ),
                  ]),
                for (final row in taskRows)
                  tr([
                    td([
                      strong([.text(row.name)]),
                    ]),
                    td(classes: 'num', [
                      _buildTaskCell(
                        row,
                        (m) => formatPercent(m.resultScore),
                        bold: true,
                      ),
                    ]),
                    td(classes: 'num', [
                      _buildTaskCell(row, (m) => formatPercent(m.outcome)),
                    ]),
                    td(classes: 'num', [
                      _buildTaskCell(row, (m) => formatPercent(m.quality)),
                    ]),
                    td(classes: 'num', [
                      _buildTaskCell(
                        row,
                        (m) => formatFraction(m.passedTrialCount, _k),
                      ),
                    ]),
                    td(classes: 'num', [
                      _buildTaskCell(row, (m) => formatTokens(m.meanTokens)),
                    ]),
                  ]),
              ]),
            ]),
          ]),
        ]),
      ]),
    ]);
  }

  /// The variant whose metrics are shown when not displaying both side by
  /// side.
  BenchVariant _resolveActiveVariant(BenchComparisonEntry currentEntry) =>
      switch (variant) {
        DisplayVariant.baseline => BenchVariant.baseline,
        DisplayVariant.enhanced => BenchVariant.enhanced,
        // Only used when one of the runs is missing,
        // so fall back to whichever run exists.
        DisplayVariant.both =>
          currentEntry.enhancedRun != null
              ? BenchVariant.enhanced
              : BenchVariant.baseline,
      };

  /// Builds the per-task rows for the active variant.
  ///
  /// When [showBoth] is true, tasks from the two runs are paired by
  /// [BenchTask.id] so each row shows baseline and enhanced together.
  List<_TaskRow> _resolveTaskRows(
    BenchComparisonEntry currentEntry, {
    required bool showBoth,
  }) {
    final baselineTasks = currentEntry.baselineRun?.tasks ?? const [];
    final enhancedTasks = currentEntry.enhancedRun?.tasks ?? const [];

    if (showBoth) {
      final baselineById = {for (final t in baselineTasks) t.id: t};
      final enhancedIds = {for (final t in enhancedTasks) t.id};
      return [
        for (final enhanced in enhancedTasks)
          _TaskRow(
            baseline: baselineById[enhanced.id],
            enhanced: enhanced,
            paired: true,
          ),
        for (final base in baselineTasks)
          if (!enhancedIds.contains(base.id))
            _TaskRow(baseline: base, paired: true),
      ];
    }

    return switch (_resolveActiveVariant(currentEntry)) {
      BenchVariant.baseline => [
        for (final t in baselineTasks) _TaskRow(baseline: t),
      ],
      BenchVariant.enhanced => [
        for (final t in enhancedTasks) _TaskRow(enhanced: t),
      ],
    };
  }

  /// Renders the baseline and enhanced columns side by side.
  Component _buildBothColumns(
    BenchComparisonEntry currentEntry,
    Component Function(BenchRunMetrics? metrics) buildColumn,
  ) {
    return div(classes: 'both-metrics-section', [
      div(classes: 'both-metrics-column', [
        const div(classes: 'both-metrics-label baseline-label', [
          .text('Baseline'),
        ]),
        buildColumn(currentEntry.baselineMetrics),
      ]),
      div(classes: 'both-metrics-column', [
        const div(classes: 'both-metrics-label ai-label', [
          .text('Enhanced'),
        ]),
        buildColumn(currentEntry.enhancedMetrics),
      ]),
    ]);
  }

  Component _buildSummaryCards(BenchRunMetrics? metrics) {
    return div(classes: 'metric-cards-grid', [
      _buildSummaryCard(
        label: 'Pass Rate',
        value: formatPercent(metrics?.passRate),
      ),
      _buildSummaryCard(
        label: 'Pass@$_k Rate',
        value: formatPercent(metrics?.passAtKRate),
      ),
      _buildSummaryCard(
        label: 'Avg Score',
        value: formatScoreWithSd(metrics?.avgScore, metrics?.scoreSd),
      ),
      _buildSummaryCard(
        label: 'Avg Tokens',
        value: formatTokens(metrics?.avgTokens),
      ),
      _buildSummaryCard(
        label: 'Avg Cost',
        value: formatCost(metrics?.avgCost),
      ),
    ]);
  }

  Component _buildBreakdownCards(BenchRunMetrics? metrics) {
    return div(classes: 'breakdown-cards-grid', [
      _buildBreakdownCard(
        'Outcome (${_scoring.outcomePercent}%)',
        'pill-outcome',
        formatPercent(metrics?.avgOutcome),
      ),
      _buildBreakdownCard(
        'Quality (${_scoring.qualityPercent}%)',
        'pill-quality',
        formatPercent(metrics?.avgQuality),
      ),
    ]);
  }

  /// Renders a per-task cell.
  ///
  /// Paired rows use the same stacked "Enhanced" / "Base" layout
  /// as the leaderboard table's Both mode.
  Component _buildTaskCell(
    _TaskRow row,
    String Function(BenchTaskMetrics) format, {
    bool bold = false,
  }) {
    String formatTask(BenchTask? task) =>
        task == null ? missingValue : format(task.metrics);

    Component value(String text) => bold ? strong([.text(text)]) : .text(text);

    if (!row.paired) {
      return value(formatTask(row.enhanced ?? row.baseline));
    }

    return div(classes: 'both-cell-container', [
      div(classes: 'variant-item', [
        const span(classes: 'variant-badge badge-ai', [.text('Enhanced')]),
        span([value(formatTask(row.enhanced))]),
      ]),
      div(classes: 'variant-item', [
        const span(classes: 'variant-badge badge-baseline', [.text('Base')]),
        span([value(formatTask(row.baseline))]),
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
  const _TaskRow({this.baseline, this.enhanced, this.paired = false})
    : assert(baseline != null || enhanced != null);

  final BenchTask? baseline;
  final BenchTask? enhanced;

  /// Whether to render baseline and enhanced values side by side.
  final bool paired;

  BenchTask get _primary => (enhanced ?? baseline)!;

  String get name => _primary.name;
}
