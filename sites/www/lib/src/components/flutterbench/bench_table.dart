// Copyright 2026, the Flutter authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that
// can be found in the LICENSE file.

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../models/content/flutter_bench.dart';
import '../../utils/bench_format.dart';
import 'bench_controls.dart';

enum SortColumn {
  agentModel,
  avgScore,
  passAt1,
  passRate,
  passAtK,
  tokens,
  cost,
}

/// Primary Leaderboard table component with sortable headers, right-aligned formatted numbers,
/// distinct variant rendering, and row selection handlers.
class BenchTable extends StatelessComponent {
  const BenchTable({
    required this.entries,
    required this.snapshot,
    required this.variant,
    required this.sortColumn,
    required this.sortAscending,
    required this.onSort,
    required this.onRowSelected,
    super.key,
  });

  final List<BenchComparisonEntry> entries;

  /// Snapshot metadata, used for the scoring weights.
  final BenchSnapshot snapshot;

  final DisplayVariant variant;
  final SortColumn sortColumn;
  final bool sortAscending;
  final ValueChanged<SortColumn> onSort;
  final ValueChanged<BenchComparisonEntry> onRowSelected;

  @override
  Component build(BuildContext context) {
    // Labels don't include `snapshot.trialsPerTask`, because some tasks
    // run fewer trials than planned.
    final scoring = snapshot.scoring;

    return div(classes: 'bench-table-card', [
      div(classes: 'bench-table-scroll', [
        table(classes: 'bench-table', [
          thead([
            tr([
              _buildHeader(
                label: 'Agent / Model',
                column: SortColumn.agentModel,
                isNum: false,
              ),
              _buildHeader(
                label: 'Avg Score (%)',
                column: SortColumn.avgScore,
                isNum: true,
                title:
                    'Mean Result Score: Outcome (${scoring.outcomePercent}%) + '
                    'Quality (${scoring.qualityPercent}%) (mean ± SD)',
              ),
              _buildHeader(
                label: 'Pass@1 (%)',
                column: SortColumn.passAt1,
                isNum: true,
                title:
                    'Expected percentage of tasks passed on a single attempt '
                    '(average share of passing trials per task)',
              ),
              _buildHeader(
                label: 'Pass Rate (%)',
                column: SortColumn.passRate,
                isNum: true,
                title: 'Percentage of tasks where every trial passed',
              ),
              _buildHeader(
                label: 'Pass@K Rate (%)',
                column: SortColumn.passAtK,
                isNum: true,
                title: 'Percentage of tasks where at least one trial passed',
              ),
              _buildHeader(
                label: 'Avg Tokens',
                column: SortColumn.tokens,
                isNum: true,
                title: 'Mean token usage per task run',
              ),
              _buildHeader(
                label: 'Avg Cost',
                column: SortColumn.cost,
                isNum: true,
                title: 'Mean cost in USD per task run',
              ),
            ]),
          ]),
          tbody([
            for (final entry in entries)
              tr(
                classes: 'bench-row',
                events: events(onClick: () => onRowSelected(entry)),
                [
                  // Agent / Model
                  td(classes: 'agent-model-cell', [
                    span(classes: 'agent-name', [.text(entry.agent)]),
                    span(classes: 'model-name', [.text(entry.model)]),
                  ]),

                  // Avg Score
                  td(classes: 'num', [
                    _buildMetricCell(
                      entry,
                      (m) => formatScoreWithSd(m?.avgScore, m?.scoreSd),
                    ),
                  ]),

                  // Pass@1
                  td(classes: 'num', [
                    _buildMetricCell(
                      entry,
                      (m) => formatPercent(m?.passAt1Rate),
                    ),
                  ]),

                  // Pass Rate
                  td(classes: 'num', [
                    _buildMetricCell(
                      entry,
                      (m) => formatPercent(m?.passRate),
                    ),
                  ]),

                  // Pass@K Rate
                  td(classes: 'num', [
                    _buildMetricCell(
                      entry,
                      (m) => formatPercent(m?.passAtKRate),
                    ),
                  ]),

                  // Avg Tokens
                  td(classes: 'num', [
                    _buildMetricCell(
                      entry,
                      (m) => formatTokens(m?.avgTokens),
                    ),
                  ]),

                  // Avg Cost
                  td(classes: 'num', [
                    _buildMetricCell(
                      entry,
                      (m) => formatCost(m?.avgCost),
                    ),
                  ]),
                ],
              ),
          ]),
        ]),
      ]),
    ]);
  }

  Component _buildHeader({
    required String label,
    required SortColumn column,
    required bool isNum,
    String? title,
  }) {
    final isSelected = sortColumn == column;
    final arrow = isSelected
        ? (sortAscending ? ' ▲' : ' ▼')
        : ''; // TODO(ewindmill): Is this okay?

    return th(
      classes: isNum ? 'num' : '',
      attributes: title != null ? {'title': title} : null,
      events: events(onClick: () => onSort(column)),
      [
        .text(label),
        if (isSelected) span(classes: 'sort-indicator', [.text(arrow)]),
      ],
    );
  }

  /// Renders a metric for the active variant,
  /// or both variants stacked in Both mode.
  Component _buildMetricCell(
    BenchComparisonEntry entry,
    String Function(BenchRunMetrics?) format,
  ) {
    final baselineVal = format(entry.baselineMetrics);
    final enhancedVal = format(entry.enhancedMetrics);

    switch (variant) {
      case DisplayVariant.baseline:
        return .text(baselineVal);
      case DisplayVariant.enhanced:
        return .text(enhancedVal);
      case DisplayVariant.both:
        return div(classes: 'both-cell-container', [
          div(classes: 'variant-item', [
            const span(classes: 'variant-badge badge-ai', [
              .text('Enhanced'),
            ]),
            span([.text(enhancedVal)]),
          ]),
          div(classes: 'variant-item', [
            const span(classes: 'variant-badge badge-baseline', [
              .text('Base'),
            ]),
            span([.text(baselineVal)]),
          ]),
        ]);
    }
  }
}
