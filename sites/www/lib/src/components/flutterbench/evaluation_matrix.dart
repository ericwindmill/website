// Copyright 2026, the Flutter authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that
// can be found in the LICENSE file.

import 'package:jaspr/jaspr.dart';

import '../../utils/data_utils.dart';
import 'interactive_detail_card.dart';

/// The 4-axis evaluation matrix: an [InteractiveDetailCard] with one tab
/// per evaluation axis.
///
/// Reads its content from `content/flutterbench/evaluation_matrix.json`.
/// Used from Markdown as `<EvaluationMatrix />`.
class EvaluationMatrix extends StatelessComponent {
  const EvaluationMatrix({super.key});

  @override
  Component build(BuildContext context) {
    final data = context.decodeJsonObject(
      'flutterbench.evaluation_matrix',
      (json) => json,
    );
    final axes = (data['axes'] as List<Object?>? ?? const [])
        .whereType<Map<String, Object?>>();

    return InteractiveDetailCard(
      title: data['title'] as String? ?? '4-Axis Evaluation Matrix',
      description: data['description'] as String? ?? '',
      classes: 'interactive-detail-card evaluation-matrix-card',
      tabs: [
        for (final axis in axes)
          {
            'id': axis['id'],
            'primary_label': axis['tab_label'],
            'secondary_label': axis['tab_sublabel'],
            'heading': axis['heading'],
            'badge': axis['badge'],
            'variant': axis['variant'] ?? 'blue',
            'overview': axis['overview'],
            'items_label': axis['items_label'],
            'items': axis['items'],
            'footer_text': axis['footer_text'],
          },
      ],
    );
  }
}
