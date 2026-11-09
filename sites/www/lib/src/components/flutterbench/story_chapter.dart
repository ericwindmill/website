// Copyright 2026, the Flutter authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that
// can be found in the LICENSE file.

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// Renders one numbered "story chapter" section for long-form
/// Flutter Bench pages, such as the methodology page.
///
/// Each chapter has a numbered kicker, an anchored `h2` heading,
/// and a per-chapter accent color that tints its background.
///
/// Used from Markdown as:
///
/// ```md
/// <StoryChapter number="01" title="Overview">
///
/// Markdown content...
///
/// </StoryChapter>
/// ```
class StoryChapter extends StatelessComponent {
  const StoryChapter({
    required this.number,
    required this.title,
    this.anchorId,
    this.child,
    super.key,
  });

  /// Creates a [StoryChapter] from Markdown element attributes.
  ///
  /// Attribute names are lowercased by the Markdown parser.
  static StoryChapter fromAttrs(
    Map<String, String> attrs,
    Component? child,
  ) => StoryChapter(
    number: attrs['number'] ?? '',
    title: attrs['title'] ?? '',
    anchorId: attrs['id'],
    child: child,
  );

  /// The two-digit chapter number, such as `'01'`.
  final String number;

  /// The chapter heading text.
  final String title;

  /// The heading's `id`, defaulting to a slug of [title].
  final String? anchorId;

  /// The chapter's body content.
  final Component? child;

  @override
  Component build(BuildContext context) {
    final headingId = anchorId ?? _slugify(title);
    return section(
      classes: 'story-chapter',
      attributes: {'data-chapter': number},
      [
        div(classes: 'chapter-header-group', [
          div(classes: 'chapter-kicker', [
            span(classes: 'chapter-number', [.text(number)]),
            const span(classes: 'chapter-rule', []),
          ]),
          div(classes: 'header-wrapper', [
            h2(id: headingId, [.text(title)]),
            a(href: '#$headingId', classes: 'heading-link', const [.text('#')]),
          ]),
        ]),
        if (child case final child?) div(classes: 'chapter-content', [child]),
      ],
    );
  }
}

String _slugify(String text) => text
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
    .trim()
    .replaceAll(RegExp(r'\s+'), '-');
