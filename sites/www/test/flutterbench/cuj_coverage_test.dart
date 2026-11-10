// Copyright 2026, the Flutter authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that
// can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_website/src/models/content/flutter_bench.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

/// Checks that the FlutterBench coverage markers in the docs site's
/// CUJ catalog reference tasks that exist in the current results.
///
/// The CUJ catalog lives in the docs site, so this test reads it
/// from a path relative to `sites/www`.
void main() {
  final results = BenchResults.fromJson(
    jsonDecode(File('content/flutterbench/results.json').readAsStringSync())
        as Map<String, Object?>,
  );
  final cujs =
      loadYaml(File('../docs/src/data/cujs.yaml').readAsStringSync()) as List;

  final benchTaskIds = {
    for (final run in results.runs)
      for (final task in run.tasks) task.id,
  };

  // Maps each FlutterBench task ID referenced in `cujs.yaml`
  // to the CUJ task names that reference it.
  final referencedIds = <String, List<String>>{};
  for (final cuj in cujs.cast<YamlMap>()) {
    for (final task in (cuj['tasks'] as YamlList).cast<YamlMap>()) {
      final ids = task['flutterbench'] as YamlList? ?? YamlList();
      for (final id in ids.cast<String>()) {
        (referencedIds[id] ??= []).add(task['name'] as String);
      }
    }
  }

  test('every flutterbench ID in cujs.yaml is a FlutterBench task', () {
    final unknown = {
      for (final MapEntry(key: id, value: names) in referencedIds.entries)
        if (!benchTaskIds.contains(id)) id: names,
    };
    expect(
      unknown,
      isEmpty,
      reason:
          'These IDs in sites/docs/src/data/cujs.yaml '
          "don't match any task ID in results.json.",
    );
  });

  test('every FlutterBench task covers at least one CUJ task', () {
    expect(
      benchTaskIds.difference(referencedIds.keys.toSet()),
      isEmpty,
      reason:
          'Add these task IDs to a `flutterbench` list '
          'in sites/docs/src/data/cujs.yaml.',
    );
  });
}
