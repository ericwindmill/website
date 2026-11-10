// Copyright 2026, the Flutter authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that
// can be found in the LICENSE file.

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../models/content/flutter_bench.dart';
import '../../utils/bench_calculator.dart';
import 'bench_controls.dart';

enum SortColumn {
  agentModel,
  passRate,
  passAt4,
  avgScore,
  tokens,
  cost,
}

/// Primary Leaderboard table component with sortable headers, right-aligned formatted numbers,
/// distinct variant rendering, and row selection handlers.
class BenchTable extends StatelessComponent {
  const BenchTable({
    required this.entries,
    required this.variant,
    required this.sortColumn,
    required this.sortAscending,
    required this.onSort,
    required this.onRowSelected,
    super.key,
  });

  final List<BenchComparisonEntry> entries;
  final DisplayVariant variant;
  final SortColumn sortColumn;
  final bool sortAscending;
  final ValueChanged<SortColumn> onSort;
  final ValueChanged<BenchComparisonEntry> onRowSelected;

  @override
  Component build(BuildContext context) {
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
                label: 'Pass Rate (%)',
                column: SortColumn.passRate,
                isNum: true,
                title: 'count(tasks with Outcome == 1.0) / total tasks × 100',
              ),
              _buildHeader(
                label: 'Pass@4 Rate (%)',
                column: SortColumn.passAt4,
                isNum: true,
                title:
                    'Percentage of tasks where at least 1 of 4 trials passed (K = 4)',
              ),
              _buildHeader(
                label: 'Avg Score (%)',
                column: SortColumn.avgScore,
                isNum: true,
                title:
                    'Mean Result Score: Outcome (60%) + Quality (30%) + DX (10%) (mean ± SD)',
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

                  // Pass Rate
                  td(classes: 'num', [
                    _buildMetricCell(
                      baselineVal: BenchCalculator.formatPercent(
                        entry.baselineMetrics.passRate,
                      ),
                      aiVal: BenchCalculator.formatPercent(
                        entry.aiToolingMetrics.passRate,
                      ),
                    ),
                  ]),

                  // Pass@4 Rate
                  td(classes: 'num', [
                    _buildMetricCell(
                      baselineVal: BenchCalculator.formatPercent(
                        entry.baselineMetrics.passAt4Rate,
                      ),
                      aiVal: BenchCalculator.formatPercent(
                        entry.aiToolingMetrics.passAt4Rate,
                      ),
                    ),
                  ]),

                  // Avg Score
                  td(classes: 'num', [
                    _buildMetricCell(
                      baselineVal: BenchCalculator.formatScoreWithSd(
                        entry.baselineMetrics.avgScore,
                        entry.baselineMetrics.scoreSd,
                      ),
                      aiVal: BenchCalculator.formatScoreWithSd(
                        entry.aiToolingMetrics.avgScore,
                        entry.aiToolingMetrics.scoreSd,
                      ),
                    ),
                  ]),

                  // Avg Tokens
                  td(classes: 'num', [
                    _buildMetricCell(
                      baselineVal: BenchCalculator.formatTokens(
                        entry.baselineMetrics.avgTokens,
                      ),
                      aiVal: BenchCalculator.formatTokens(
                        entry.aiToolingMetrics.avgTokens,
                      ),
                    ),
                  ]),

                  // Avg Cost
                  td(classes: 'num', [
                    _buildMetricCell(
                      baselineVal: BenchCalculator.formatCost(
                        entry.baselineMetrics.avgCost,
                      ),
                      aiVal: BenchCalculator.formatCost(
                        entry.aiToolingMetrics.avgCost,
                      ),
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

  Component _buildMetricCell({
    required String baselineVal,
    required String aiVal,
  }) {
    switch (variant) {
      case DisplayVariant.baseline:
        return .text(baselineVal);
      case DisplayVariant.aiTooling:
        return .text(aiVal);
      case DisplayVariant.both:
        return div(classes: 'both-cell-container', [
          div(classes: 'variant-item', [
            const span(classes: 'variant-badge badge-ai', [
              .text('Tooling'),
            ]),
            span([.text(aiVal)]),
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
