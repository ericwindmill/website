// Copyright 2026, the Flutter authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that
// can be found in the LICENSE file.

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'bench_tabbar.dart';

/// Shared header component for Flutter Bench pages.
///
/// Renders the page title, subtitle, and sub-navigation tabs.
/// Used by the methodology and archive pages via `<FlutterBenchHeader />`.
class FlutterBenchHeader extends StatelessComponent {
  const FlutterBenchHeader({
    this.activePage = 'leaderboard',
    super.key,
  });

  final String activePage;

  /// Creates a [FlutterBenchHeader] from markdown element attributes.
  static FlutterBenchHeader fromAttrs(Map<String, String> attrs) =>
      FlutterBenchHeader(activePage: attrs['activepage'] ?? 'leaderboard');

  @override
  Component build(BuildContext context) {
    return div(classes: 'flutterbench-page', [
      div(classes: 'container', [
        const div(classes: 'bench-header', [
          h1(classes: 'bench-title', [.text('Flutter Bench')]),
          p(classes: 'bench-subtitle', [
            // TODO(ewindmill): can this be written into the md file?
            .text(
              'A public leaderboard measuring how effectively AI coding '
              'agents and models build Flutter and Dart applications.',
            ),
          ]),
        ]),
        BenchSubnav(activePage: activePage),
      ]),
    ]);
  }
}
