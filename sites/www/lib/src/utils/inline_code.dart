// Copyright 2026, the Flutter authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that
// can be found in the LICENSE file.

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// Splits [text] on backticks, rendering odd segments as inline `code`.
List<Component> withInlineCode(String text) {
  final segments = text.split('`');
  return [
    for (final (i, segment) in segments.indexed)
      if (segment.isNotEmpty)
        if (i.isOdd) code([.text(segment)]) else .text(segment),
  ];
}
