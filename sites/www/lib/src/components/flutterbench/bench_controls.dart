// Copyright 2026, the Flutter authors. All rights reserved. Use of this source
// code is governed by a BSD-style license that can be found in the LICENSE
// file.

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// Available toggle view states for Flutter Bench.
enum DisplayVariant {
  baseline('baseline', 'Baseline'),
  enhanced('enhanced', 'Enhanced'),
  both('both', 'Both');

  final String id;
  final String label;

  const DisplayVariant(this.id, this.label);
}

/// Controls bar hosting the agent and model filters.
///
/// The [BenchVariantToggle] isn't shown here while the leaderboard
/// displays baseline results only.
class BenchControls extends StatelessComponent {
  const BenchControls({
    required this.selectedAgent,
    required this.selectedModel,
    required this.availableAgents,
    required this.availableModels,
    required this.onAgentChanged,
    required this.onModelChanged,
    required this.onClearFilters,
    super.key,
  });

  final String? selectedAgent;
  final String? selectedModel;
  final List<String> availableAgents;
  final List<String> availableModels;
  final ValueChanged<String?> onAgentChanged;
  final ValueChanged<String?> onModelChanged;
  final VoidCallback onClearFilters;

  @override
  Component build(BuildContext context) {
    final hasActiveFilter =
        (selectedAgent != null && selectedAgent!.isNotEmpty) ||
        (selectedModel != null && selectedModel!.isNotEmpty);

    return div(classes: 'bench-controls-bar', [
      // Top-left filter controls
      div(classes: 'bench-filters-left', [
        div(classes: 'bench-filter-group', [
          const span(classes: 'filter-label', [.text('Agent:')]),
          select(
            onChange: (values) {
              final val = values.isNotEmpty ? values.first : '';
              onAgentChanged(val.isEmpty ? null : val);
            },
            [
              option(
                value: '',
                selected: selectedAgent == null || selectedAgent!.isEmpty,
                const [.text('All Agents')],
              ),
              for (final agent in availableAgents)
                option(
                  value: agent,
                  selected: selectedAgent == agent,
                  [.text(agent)],
                ),
            ],
          ),
        ]),
        div(classes: 'bench-filter-group', [
          const span(classes: 'filter-label', [.text('Model:')]),
          select(
            onChange: (values) {
              final val = values.isNotEmpty ? values.first : '';
              onModelChanged(val.isEmpty ? null : val);
            },
            [
              option(
                value: '',
                selected: selectedModel == null || selectedModel!.isEmpty,
                const [.text('All Models')],
              ),
              for (final model in availableModels)
                option(
                  value: model,
                  selected: selectedModel == model,
                  [.text(model)],
                ),
            ],
          ),
        ]),
        if (hasActiveFilter)
          button(
            classes: 'bench-clear-btn',
            events: events(onClick: onClearFilters),
            const [.text('✕ Clear filters')],
          ),
      ]),
    ]);
  }
}

/// A 3-segment toggle for switching between [DisplayVariant] values.
///
/// Not currently rendered: the leaderboard shows baseline results only.
/// Previously used in both the leaderboard controls bar and the detail drawer.
class BenchVariantToggle extends StatelessComponent {
  const BenchVariantToggle({
    required this.selectedVariant,
    required this.onVariantChanged,
    super.key,
  });

  final DisplayVariant selectedVariant;
  final ValueChanged<DisplayVariant> onVariantChanged;

  @override
  Component build(BuildContext context) {
    return div(classes: 'bench-variant-toggle', [
      for (final variant in DisplayVariant.values)
        button(
          classes:
              'toggle-segment ${selectedVariant == variant ? 'active' : ''}',
          attributes: {'aria-pressed': '${selectedVariant == variant}'},
          events: events(onClick: () => onVariantChanged(variant)),
          [.text(variant.label)],
        ),
    ]);
  }
}
