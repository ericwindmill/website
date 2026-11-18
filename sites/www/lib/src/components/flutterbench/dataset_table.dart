// Copyright 2026, the Flutter authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that
// can be found in the LICENSE file.

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../utils/data_utils.dart';
import '../../utils/inline_code.dart';

/// The table of tasks in the Flutter Bench dataset,
/// showing what a developer asks for in each task and what's evaluated.
///
/// Reads its content from `content/flutterbench/dataset_tasks.json`.
/// Used from Markdown as `<DatasetTable />`, or as
/// `<DatasetTable limit="2" />` to show only the first few tasks.
class DatasetTable extends StatelessComponent {
  const DatasetTable({this.limit, super.key});

  /// Creates a [DatasetTable] from Markdown element attributes.
  static DatasetTable fromAttrs(Map<String, String> attrs) =>
      DatasetTable(limit: int.tryParse(attrs['limit'] ?? ''));

  /// The maximum number of tasks to show, or `null` to show all of them.
  final int? limit;

  @override
  Component build(BuildContext context) {
    final data = context.decodeJsonObject(
      'flutterbench.dataset_tasks',
      (json) => json,
    );
    var tasks = (data['tasks'] as List<Object?>? ?? const [])
        .whereType<Map<String, Object?>>()
        .map(_DatasetTask.fromJson);
    if (limit case final limit?) tasks = tasks.take(limit);

    return div(classes: 'table-wrapper', [
      table(classes: 'dataset-table', [
        const thead([
          tr([
            th([.text('Name')]),
            th([.text('Developer intent')]),
            th([.text('Evaluates')]),
          ]),
        ]),
        tbody([
          for (final task in tasks)
            tr([
              td([.text(task.name)]),
              td(classes: 'developer-request', [
                .text(task.developerRequest),
              ]),
              td(withInlineCode(task.evaluates)),
            ]),
        ]),
      ]),
    ]);
  }
}

/// A single task row in [DatasetTable].
final class _DatasetTask {
  const _DatasetTask({
    required this.id,
    required this.name,
    required this.cuj,
    required this.developerRequest,
    required this.evaluates,
  });

  factory _DatasetTask.fromJson(Map<String, Object?> json) => _DatasetTask(
    id: json['id'] as String,
    name: json['name'] as String,
    cuj: json['cuj'] as String,
    developerRequest: json['developer_request'] as String,
    evaluates: json['evaluates'] as String,
  );

  /// The task ID, such as `SHT-04`, or `-` if it has none.
  /// Kept for reference, but not rendered.
  final String id;

  final String name;

  /// The task's CUJ ID, or `-` if it has none.
  /// Kept for reference, but not rendered.
  final String cuj;

  /// What the developer asks the agent to do, in the developer's voice.
  final String developerRequest;

  /// What the task grades, and optionally what's out of scope.
  ///
  /// Backtick-delimited spans render as inline code.
  final String evaluates;
}
