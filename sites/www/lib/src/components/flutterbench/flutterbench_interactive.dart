// Copyright 2026, the Flutter authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that
// can be found in the LICENSE file.

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../models/content/flutter_bench.dart';
import '../../utils/bench_calculator.dart';
import 'bench_controls.dart';
import 'bench_detail_drawer.dart';
import 'bench_table.dart';

/// Client-hydrated interactive leaderboard component.
///
/// Receives pre-loaded benchmark data as raw JSON maps (serialized by
/// Jaspr across the server→client boundary) and handles all user
/// interaction: filtering, variant toggling, sorting, and the detail drawer.
///
/// This file is kept separate from [FlutterBenchPage] (the server-side
/// page wrapper) to avoid importing `data_utils.dart` and
/// `jaspr_content`, which are not available on the web platform.
@client
class FlutterBenchInteractive extends StatefulComponent {
  const FlutterBenchInteractive({
    required this.rawRunsJson,
    super.key,
  });

  final List<Map<String, Object?>> rawRunsJson;

  @override
  State<FlutterBenchInteractive> createState() =>
      _FlutterBenchInteractiveState();
}

class _FlutterBenchInteractiveState extends State<FlutterBenchInteractive> {
  String? _selectedAgent;
  String? _selectedModel;
  DisplayVariant _selectedVariant = DisplayVariant.baseline;
  SortColumn _sortColumn = SortColumn.passRate;
  bool _sortAscending = false; // default Pass Rate descending
  BenchComparisonEntry? _selectedRow;
  bool _drawerOpen = false;

  late List<BenchComparisonEntry> _allComparisons;

  @override
  void initState() {
    super.initState();
    _recomputeComparisons();
  }

  void _recomputeComparisons() {
    final runs = component.rawRunsJson
        .map(BenchModelRun.fromJson)
        .toList();
    _allComparisons = BenchCalculator.buildComparisonEntries(runs);
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

    // Sort comparisons.
    filtered.sort((a, b) {
      var cmp = 0;
      switch (_sortColumn) {
        case SortColumn.agentModel:
          cmp = a.compositeKey.compareTo(b.compositeKey);
        case SortColumn.passRate:
          final aVal = _selectedVariant == DisplayVariant.baseline
              ? a.baselineMetrics.passRate
              : a.aiToolingMetrics.passRate;
          final bVal = _selectedVariant == DisplayVariant.baseline
              ? b.baselineMetrics.passRate
              : b.aiToolingMetrics.passRate;
          cmp = aVal.compareTo(bVal);
        case SortColumn.passAt4:
          final aVal = _selectedVariant == DisplayVariant.baseline
              ? a.baselineMetrics.passAt4Rate
              : a.aiToolingMetrics.passAt4Rate;
          final bVal = _selectedVariant == DisplayVariant.baseline
              ? b.baselineMetrics.passAt4Rate
              : b.aiToolingMetrics.passAt4Rate;
          cmp = aVal.compareTo(bVal);
        case SortColumn.avgScore:
          final aVal = _selectedVariant == DisplayVariant.baseline
              ? a.baselineMetrics.avgScore
              : a.aiToolingMetrics.avgScore;
          final bVal = _selectedVariant == DisplayVariant.baseline
              ? b.baselineMetrics.avgScore
              : b.aiToolingMetrics.avgScore;
          cmp = aVal.compareTo(bVal);
        case SortColumn.tokens:
          final aVal = _selectedVariant == DisplayVariant.baseline
              ? a.baselineMetrics.avgTokens
              : a.aiToolingMetrics.avgTokens;
          final bVal = _selectedVariant == DisplayVariant.baseline
              ? b.baselineMetrics.avgTokens
              : b.aiToolingMetrics.avgTokens;
          cmp = aVal.compareTo(bVal);
        case SortColumn.cost:
          final aVal = _selectedVariant == DisplayVariant.baseline
              ? a.baselineMetrics.avgCost
              : a.aiToolingMetrics.avgCost;
          final bVal = _selectedVariant == DisplayVariant.baseline
              ? b.baselineMetrics.avgCost
              : b.aiToolingMetrics.avgCost;
          cmp = aVal.compareTo(bVal);
      }
      return _sortAscending ? cmp : -cmp;
    });

    return div(classes: 'bench-interactive', [
      div(classes: 'container', [
        // Controls bar (Filters top-left, Variant toggle top-right)
        BenchControls(
          selectedAgent: _selectedAgent,
          selectedModel: _selectedModel,
          selectedVariant: _selectedVariant,
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
          onVariantChanged: (variant) => setState(() {
            _selectedVariant = variant;
          }),
        ),

        // Primary Leaderboard Table
        BenchTable(
          entries: filtered,
          variant: _selectedVariant,
          sortColumn: _sortColumn,
          sortAscending: _sortAscending,
          onSort: (col) => setState(() {
            if (_sortColumn == col) {
              _sortAscending = !_sortAscending;
            } else {
              _sortColumn = col;
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
        variant: _selectedVariant,
        isOpen: _drawerOpen,
        onClose: () => setState(() => _drawerOpen = false),
      ),
    ]);
  }
}
