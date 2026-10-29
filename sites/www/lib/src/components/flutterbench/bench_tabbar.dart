// Copyright 2026, the Flutter authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that
// can be found in the LICENSE file.

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// Sub-navigation tabs for the Flutter Bench section.
///
/// Renders a horizontal set of tab links below the page heading,
/// similar to the blog category chips on flutter.dev/blog.
class BenchSubnav extends StatelessComponent {
  const BenchSubnav({required this.activePage, super.key});

  /// The currently active page identifier.
  /// One of `'leaderboard'`, `'methodology'`, or `'archive'`.
  final String activePage;

  @override
  Component build(BuildContext context) {
    return nav(classes: 'bench-subnav', [
      _buildTab(
        label: 'Leaderboard',
        href: '/flutterbench',
        isActive: activePage == 'leaderboard',
      ),
      _buildTab(
        label: 'Methodology',
        href: '/flutterbench/methodology',
        isActive: activePage == 'methodology',
      ),
      _buildTab(
        label: 'Archive',
        href: '/flutterbench/archive',
        isActive: activePage == 'archive',
      ),
    ]);
  }

  Component _buildTab({
    required String label,
    required String href,
    required bool isActive,
  }) {
    return a(
      href: href,
      target: Target.self,
      classes: 'bench-subnav-tab ${isActive ? 'active' : ''}',
      [.text(label)],
    );
  }
}
