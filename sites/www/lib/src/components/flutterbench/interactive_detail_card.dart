// Copyright 2026, the Flutter authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that
// can be found in the LICENSE file.

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:site_shared/util.dart';

/// Interactive tabbed card that shows one detail panel per tab.
///
/// Ported from the FlutterBench methodology page in flutter/website
/// (sites/www/lib/src/components/flutterbench/interactive_detail_card.dart).
///
/// Each entry in [tabs] supports these keys:
/// `id`, `primary_label`, `secondary_label`, `heading`, `badge`, `variant`,
/// `overview`, `items_label`, `items` (a list of `label`/`detail` maps),
/// and `footer_text`. Text wrapped in backticks renders as inline code.
@client
class InteractiveDetailCard extends StatefulComponent {
  const InteractiveDetailCard({
    required this.title,
    required this.description,
    required this.tabs,
    this.classes = 'interactive-detail-card',
    super.key,
  });

  final String title;
  final String description;
  final List<Map<String, Object?>> tabs;
  final String classes;

  @override
  State<InteractiveDetailCard> createState() => _InteractiveDetailCardState();
}

class _InteractiveDetailCardState extends State<InteractiveDetailCard> {
  late String _activeTab = (component.tabs.firstOrNull?['id'] as String?) ?? '';

  @override
  Component build(BuildContext context) {
    return div(classes: component.classes, [
      div(classes: 'card-header-area', [
        h3([.text(component.title)]),
        p([.text(component.description)]),
      ]),
      div(classes: 'card-tabs-grid', [
        for (final tab in component.tabs)
          button(
            classes: [
              'card-tab-btn',
              'variant-${tab['variant'] as String? ?? 'blue'}',
              if (tab['id'] == _activeTab) 'active',
            ].toClasses,
            attributes: {
              'type': 'button',
              'aria-pressed': '${tab['id'] == _activeTab}',
            },
            events: {
              'click': (_) {
                setState(() {
                  _activeTab = tab['id'] as String? ?? '';
                });
              },
            },
            [
              div(
                classes: 'tab-primary-label',
                [.text(tab['primary_label'] as String? ?? '')],
              ),
              div(
                classes: 'tab-secondary-label',
                [.text(tab['secondary_label'] as String? ?? '')],
              ),
            ],
          ),
      ]),
      div(classes: 'card-panels-container', [
        for (final tab in component.tabs)
          div(
            classes: [
              'card-panel',
              if (tab['id'] == _activeTab) 'active',
            ].toClasses,
            [
              div(classes: 'panel-heading', [
                h4([.text(tab['heading'] as String? ?? '')]),
                if (tab['badge'] case final String badge)
                  span(
                    classes:
                        'panel-badge badge-${tab['variant'] as String? ?? 'blue'}',
                    [.text(badge)],
                  ),
              ]),
              p(classes: 'panel-overview', [
                _textWithCode(tab['overview'] as String? ?? ''),
              ]),
              if (tab['items'] case final List<Object?> items
                  when items.isNotEmpty)
                div(classes: 'panel-items-section', [
                  if (tab['items_label'] case final String label)
                    div(classes: 'items-label', [.text(label)]),
                  ul([
                    for (final item in items.whereType<Map<String, Object?>>())
                      li([
                        strong([
                          .text('${item['label'] as String? ?? ''}: '),
                        ]),
                        _textWithCode(item['detail'] as String? ?? ''),
                      ]),
                  ]),
                ]),
              if (tab['footer_text'] case final String footer
                  when footer.isNotEmpty)
                p(classes: 'panel-footer-text', [_textWithCode(footer)]),
            ],
          ),
      ]),
    ]);
  }
}

/// Renders [text], turning segments wrapped in backticks into inline code.
Component _textWithCode(String text) {
  if (!text.contains('`')) return .text(text);
  final parts = text.split('`');
  return .fragment([
    for (final (i, part) in parts.indexed)
      if (i.isOdd) code([.text(part)]) else if (part.isNotEmpty) .text(part),
  ]);
}
