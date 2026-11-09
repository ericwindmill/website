// Copyright 2026, the Flutter authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that
// can be found in the LICENSE file.

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:site_shared/components/common/material_icon.dart';

// Card components for the Flutter Bench methodology page, ported from the
// FlutterBench methodology page in flutter/website
// (sites/www/lib/src/components/flutterbench/methodology_components.dart).
//
// Unlike the originals, these take their body content as Markdown children
// so the copy stays in `content/flutterbench/methodology.md`.
//
// Note: jaspr_content matches custom component names by prefix,
// so wrapper and card names intentionally don't share a prefix.

/// A responsive grid of [DimensionCard]s.
///
/// Used from Markdown as `<ScoreDimensions>...</ScoreDimensions>`.
class ScoreDimensions extends StatelessComponent {
  const ScoreDimensions({this.child, super.key});

  /// Creates a [ScoreDimensions] from Markdown element attributes.
  static ScoreDimensions fromAttrs(
    Map<String, String> attrs,
    Component? child,
  ) => ScoreDimensions(child: child);

  /// The [DimensionCard]s to lay out.
  final Component? child;

  @override
  Component build(BuildContext context) =>
      div(classes: 'dimension-cards-grid', [?child]);
}

/// A card describing one scoring dimension, such as Outcome or Code Quality.
///
/// Used from Markdown as:
///
/// ```md
/// <DimensionCard title="1. Outcome" icon="check_circle"
///     category="outcome" badge="60% weight">
///
/// Markdown body...
///
/// </DimensionCard>
/// ```
///
/// The [category] (`outcome`, `quality`, or `dx`) sets the accent color.
class DimensionCard extends StatelessComponent {
  const DimensionCard({
    required this.title,
    this.icon,
    this.category,
    this.footer,
    this.badge,
    this.child,
    super.key,
  });

  /// Creates a [DimensionCard] from Markdown element attributes.
  static DimensionCard fromAttrs(
    Map<String, String> attrs,
    Component? child,
  ) => DimensionCard(
    title: attrs['title'] ?? '',
    icon: attrs['icon'],
    category: attrs['category'],
    footer: attrs['footer'],
    badge: attrs['badge'],
    child: child,
  );

  final String title;

  /// The Material Symbols icon name.
  final String? icon;

  /// The accent color category: `outcome`, `quality`, or `dx`.
  final String? category;

  /// Optional text shown at the start of the card footer.
  final String? footer;

  /// Optional badge shown at the end of the card footer.
  final String? badge;

  /// The card body.
  final Component? child;

  @override
  Component build(BuildContext context) {
    final categoryClass = category ?? '';
    return div(classes: 'dimension-card $categoryClass'.trim(), [
      div(classes: 'card-header-row', [
        if (icon case final icon?)
          div(classes: 'card-icon-wrap $categoryClass', [MaterialIcon(icon)]),
        h4([.text(title)]),
      ]),
      div(classes: 'card-body', [?child]),
      if (footer != null || badge != null)
        div(classes: 'card-footer-info', [
          if (footer case final footer?) span([.text(footer)]),
          if (badge case final badge?)
            span(classes: 'badge $categoryClass', [.text(badge)]),
        ]),
    ]);
  }
}

/// A responsive grid of [RollupCard]s.
///
/// Used from Markdown as `<RollupMetrics>...</RollupMetrics>`.
class RollupMetrics extends StatelessComponent {
  const RollupMetrics({this.child, super.key});

  /// Creates a [RollupMetrics] from Markdown element attributes.
  static RollupMetrics fromAttrs(
    Map<String, String> attrs,
    Component? child,
  ) => RollupMetrics(child: child);

  /// The [RollupCard]s to lay out.
  final Component? child;

  @override
  Component build(BuildContext context) =>
      div(classes: 'rollup-cards-grid', [?child]);
}

/// A card describing one leaderboard rollup metric.
///
/// Used from Markdown as:
///
/// ```md
/// <RollupCard title="Pass Rate (%)" pill="Outcome = 1.0" highlight="true">
///
/// Markdown body...
///
/// </RollupCard>
/// ```
///
/// Set `highlight="true"` to render the card with the dark featured style.
class RollupCard extends StatelessComponent {
  const RollupCard({
    required this.title,
    this.tag,
    this.tagIcon,
    this.pill,
    this.isHighlighted = false,
    this.child,
    super.key,
  });

  /// Creates a [RollupCard] from Markdown element attributes.
  static RollupCard fromAttrs(
    Map<String, String> attrs,
    Component? child,
  ) => RollupCard(
    title: attrs['title'] ?? '',
    tag: attrs['tag'],
    tagIcon: attrs['tagicon'],
    pill: attrs['pill'],
    isHighlighted: attrs['highlight'] == 'true',
    child: child,
  );

  final String title;

  /// Optional uppercase eyebrow text, such as `'Ceiling metric'`.
  final String? tag;

  /// Optional Material Symbols icon shown before [tag].
  final String? tagIcon;

  /// Optional monospace pill shown at the end of the header row.
  final String? pill;

  /// Whether to render the card with the dark featured style.
  final bool isHighlighted;

  /// The card body.
  final Component? child;

  @override
  Component build(BuildContext context) {
    return div(
      classes: isHighlighted ? 'rollup-card highlight' : 'rollup-card',
      [
        if (tag != null || pill != null)
          div(classes: 'rollup-header', [
            if (tag case final tag?)
              span(classes: 'tag', [
                if (tagIcon case final tagIcon?) MaterialIcon(tagIcon),
                .text(tag),
              ]),
            if (pill case final pill?)
              span(classes: 'math-pill', [.text(pill)]),
          ]),
        h4([.text(title)]),
        div(classes: 'card-body', [?child]),
      ],
    );
  }
}
