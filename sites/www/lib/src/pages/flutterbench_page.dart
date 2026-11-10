// Copyright 2026, the Flutter authors. All rights reserved. Use of this source
// code is governed by a BSD-style license that can be found in the LICENSE
// file.

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../components/flutterbench/bench_tabbar.dart';
import '../components/flutterbench/flutterbench_interactive.dart';
import '../models/content/flutter_bench.dart';
import '../utils/data_utils.dart';

/// Server-side page component for `/flutterbench`.
///
/// Renders the shared heading and sub-navigation, then loads benchmark results
/// and passes the raw JSON list to the client-hydrated
/// [FlutterBenchInteractive] component.
///
/// Any Markdown content wrapped by the component renders below the
/// leaderboard, inside the same container:
///
/// ```md
/// <FlutterBenchPage>
///
/// Markdown content...
///
/// </FlutterBenchPage>
/// ```
class FlutterBenchPage extends StatelessComponent {
  const FlutterBenchPage({this.child, super.key});

  /// Creates a [FlutterBenchPage] from Markdown element attributes.
  static FlutterBenchPage fromAttrs(
    Map<String, String> attrs,
    Component? child,
  ) => FlutterBenchPage(child: child);

  /// Static content rendered below the interactive leaderboard.
  final Component? child;

  @override
  Component build(BuildContext context) {
    var rawData = const <Map<String, Object?>>[];
    try {
      final runs = context.decodeJsonList(
        'flutterbench.results',
        BenchModelRun.fromJson,
      );
      rawData = runs.map(_modelRunToJson).toList();
    } catch (_) {
      // Fallback empty when data is not available
    }

    return main_(classes: 'flutterbench-page', [
      const div(classes: 'container', [
        // Page Title & Subtitle
        div(classes: 'bench-header', [
          h1(classes: 'bench-title', [.text('Flutter Bench')]),
          p(classes: 'bench-subtitle', [
            .text(
              'Measuring how effectively AI coding '
              'agents and models build Flutter and Dart applications.',
            ),
          ]),
        ]),

        // Sub-navigation tabs: Leaderboard · Methodology · Archive
        BenchSubnav(activePage: 'leaderboard'),
      ]),

      // Client-hydrated interactive leaderboard
      FlutterBenchInteractive(rawRunsJson: rawData),

      // Static content from Markdown, such as the methodology card and legend.
      if (child case final child?) div(classes: 'container', [child]),
    ]);
  }

  /// Converts a [BenchModelRun] back to a JSON map for client serialization.
  /// TODO(ewindmill): This shouldn't be here?
  static Map<String, Object?> _modelRunToJson(BenchModelRun run) => {
    'agent': run.agent,
    'model': run.model,
    'variant': run.variant.value,
    'tasks': run.tasks
        .map(
          (t) => {
            'id': t.id,
            'name': t.name,
            'category': t.category.value,
            'tokens': t.tokens,
            'cost': t.cost,
            'trials': t.trials.map((el) => el.toJson()).toList(),
          },
        )
        .toList(),
  };
}
