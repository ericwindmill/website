// Copyright 2026, the Flutter authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that
// can be found in the LICENSE file.

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../models/content/flutter_bench.dart';
import 'bench_controls.dart';
import 'bench_detail_drawer.dart';
import 'bench_table.dart';

/// Client-hydrated interactive leaderboard component.
///
/// Receives the benchmark results file as raw JSON (serialized by
/// Jaspr across the server→client boundary) and handles all user
/// interaction: filtering, sorting, and the detail drawer.
///
/// Only baseline results are shown. Enhanced runs in the results file
/// are parsed but not rendered, and no variant toggle is displayed.
///
/// This file is kept separate from [FlutterBenchPage] (the server-side
/// page wrapper) to avoid importing `data_utils.dart` and
/// `jaspr_content`, which are not available on the web platform.
@client
class FlutterBenchInteractive extends StatefulComponent {
  const FlutterBenchInteractive({
    required this.rawResultsJson,
    super.key,
  });

  /// The contents of the results file, decoded with [BenchResults.fromJson].
  final Map<String, Object?> rawResultsJson;

  @override
  State<FlutterBenchInteractive> createState() =>
      _FlutterBenchInteractiveState();
}

class _FlutterBenchInteractiveState extends State<FlutterBenchInteractive> {
  /// The variant shown in the leaderboard and detail drawer.
  ///
  /// Enhanced results are out of scope for the MVP,
  /// so this is fixed to baseline.
  /// To bring the variant toggle back, make this mutable and
  /// render a [BenchVariantToggle] that updates it.
  final DisplayVariant _variant = DisplayVariant.baseline;

  String? _selectedAgent;
  String? _selectedModel;
  SortColumn _sortColumn = SortColumn.passRate;
  bool _sortAscending = false; // default Pass Rate descending
  BenchComparisonEntry? _selectedRow;
  bool _drawerOpen = false;

  late BenchSnapshot _snapshot;
  late List<BenchComparisonEntry> _allComparisons;

  @override
  void initState() {
    super.initState();
    final results = BenchResults.fromJson(component.rawResultsJson);
    _snapshot = results.snapshot;
    _allComparisons = BenchComparisonEntry.fromRuns(results.runs);
  }

  @override
  Component build(BuildContext context) {
    // Collect available filter options.
    final availableAgents = _allComparisons.map((c) => c.agent).toSet().toList()
      ..sort();
    final availableModels =
        _allComparisons
            .where(
              (c) =>
                  _selectedAgent == null ||
                  _selectedAgent!.isEmpty ||
                  c.agent == _selectedAgent,
            )
            .map((c) => c.model)
            .toSet()
            .toList()
          ..sort();

    // Filter comparisons.
    final filtered = _allComparisons.where((entry) {
      if (_selectedAgent != null &&
          _selectedAgent!.isNotEmpty &&
          entry.agent != _selectedAgent) {
        return false;
      }
      if (_selectedModel != null &&
          _selectedModel!.isNotEmpty &&
          entry.model != _selectedModel) {
        return false;
      }
      return true;
    }).toList();

    _sortCols(filtered);

    return div(classes: 'bench-interactive', [
      div(classes: 'container', [
        // Controls bar (filters)
        BenchControls(
          selectedAgent: _selectedAgent,
          selectedModel: _selectedModel,
          availableAgents: availableAgents,
          availableModels: availableModels,
          onAgentChanged: (val) => setState(() {
            _selectedAgent = val;
            _selectedModel = null; // reset model if agent changes
          }),
          onModelChanged: (val) => setState(() => _selectedModel = val),
          onClearFilters: () => setState(() {
            _selectedAgent = null;
            _selectedModel = null;
          }),
        ),

        // Primary Leaderboard Table
        BenchTable(
          entries: filtered,
          snapshot: _snapshot,
          variant: _variant,
          sortColumn: _sortColumn,
          sortAscending: _sortAscending,
          onSort: (column) => setState(() {
            if (_sortColumn == column) {
              _sortAscending = !_sortAscending;
            } else {
              _sortColumn = column;
              _sortAscending = false;
            }
          }),
          onRowSelected: (entry) => setState(() {
            _selectedRow = entry;
            _drawerOpen = true;
          }),
        ),
      ]),

      // Slide-over detail drawer component
      BenchDetailDrawer(
        entry: _selectedRow,
        snapshot: _snapshot,
        variant: _variant,
        isOpen: _drawerOpen,
        onClose: () => setState(() => _drawerOpen = false),
      ),
    ]);
  }

  /// Sorts [elements] in place by the selected column.
  ///
  /// In Both mode, numeric columns sort by the enhanced values.
  /// Missing values, such as unavailable cost, always sort last.
  void _sortCols(List<BenchComparisonEntry> elements) {
    final sortVariant = _variant == DisplayVariant.baseline
        ? BenchVariant.baseline
        : BenchVariant.enhanced;

    num? valueOf(BenchComparisonEntry entry) {
      final metrics = entry.metricsFor(sortVariant);
      return switch (_sortColumn) {
        SortColumn.agentModel => null,
        SortColumn.passRate => metrics?.passRate,
        SortColumn.passAtK => metrics?.passAtKRate,
        SortColumn.avgScore => metrics?.avgScore,
        SortColumn.tokens => metrics?.avgTokens,
        SortColumn.cost => metrics?.avgCost,
      };
    }

    elements.sort((first, second) {
      if (_sortColumn == SortColumn.agentModel) {
        final cmp = first.displayKey.compareTo(second.displayKey);
        return _sortAscending ? cmp : -cmp;
      }

      final aVal = valueOf(first);
      final bVal = valueOf(second);
      if (aVal == null || bVal == null) {
        if (aVal == bVal) return 0;
        return aVal == null ? 1 : -1;
      }
      final cmp = aVal.compareTo(bVal);
      return _sortAscending ? cmp : -cmp;
    });
  }
}
