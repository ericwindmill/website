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
/// from `content/flutterbench/results.json` and passes the raw JSON to the
/// client-hydrated [FlutterBenchInteractive] component.
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
    // Parse on the server so malformed results fail the build,
    // then pass the validated raw JSON across to the client.
    final (:rawJson, :results) = context.decodeJsonObject(
      'flutterbench.results',
      (json) => (rawJson: json, results: BenchResults.fromJson(json)),
    );
    final snapshot = results.snapshot;
    final environment = snapshot.environment;

    return main_(classes: 'flutterbench-page', [
      div(classes: 'container', [
        // Page Title & Subtitle
        div(classes: 'bench-header', [
          const h1(classes: 'bench-title', [.text('Flutter Bench')]),
          const p(classes: 'bench-subtitle', [
            .text(
              'Measuring how effectively AI coding '
              'agents and models build Flutter and Dart applications.',
            ),
          ]),
          p(classes: 'bench-snapshot-meta', [
            .text(
              '${snapshot.label} results · '
              'Flutter ${environment.flutterVersion} · '
              'Dart ${environment.dartVersion}',
            ),
          ]),
        ]),

        // Sub-navigation tabs: Leaderboard · Methodology · Archive
        const BenchSubnav(activePage: 'leaderboard'),
      ]),

      // Client-hydrated interactive leaderboard
      FlutterBenchInteractive(rawResultsJson: rawJson),

      // Static content from Markdown, such as the methodology card and legend.
      if (child case final child?) div(classes: 'container', [child]),
    ]);
  }
}
