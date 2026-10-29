// Copyright 2026, the Flutter authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that
// can be found in the LICENSE file.

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// Methodology teaser card placed directly under the leaderboard table.
class BenchMethodologyCard extends StatelessComponent {
  const BenchMethodologyCard({super.key});

  @override
  Component build(BuildContext context) {
    return const div(classes: 'bench-methodology-card', [
      h3([.text('Benchmark Methodology')]),
      p([
        // TODO(ewindmill): Can this be written into the md files?
        .text(
          'Flutter Bench rigorously evaluates AI coding agents across realistic Flutter and Dart development workflows. '
          'Our benchmark consists of balanced short-horizon tasks (such as reactive form validation and custom painters) '
          'and multi-file long-horizon challenges (including architecture refactors, declarative deep linking, and offline SQLite synchronization). '
          'Every task run is executed across 4 independent trials to ensure statistical repeatability. '
          'Solutions are graded through a combination of code-based verification suites, rubric-guided LLM evaluation, and human-verified golden references, '
          'producing an overall Result Score weighted by functional Outcome (60%), Code Quality (30%), and Developer Experience (10%). '
          'We evaluate each model under both a standalone Baseline harness and an AI Tooling harness equipped with official Flutter MCP tools and skills.',
        ),
      ]),
      a(href: '/flutterbench/methodology', classes: 'methodology-link', [
        span([.text('Read the complete methodology guide')]),
        span([.text(' →')]),
      ]),
    ]);
  }
}
