// Copyright (C) 2023 Adriano Souza (adriano.souza113@gmail.com)

// Copyright 2018 the Charts project authors. Please see the AUTHORS file
// for details.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:math' show min, max;

import 'package:flutter/widgets.dart';

import 'chart_canvas.dart' show FillPatternType;

/// A rectangle to be painted by [ChartCanvas].
class CanvasRect {
  CanvasRect(
    this.bounds, {
    this.dashPattern,
    this.fill,
    this.pattern,
    this.stroke,
    this.strokeWidth,
  });

  final Rect bounds;
  final List<int>? dashPattern;
  final Color? fill;
  final FillPatternType? pattern;
  final Color? stroke;
  final double? strokeWidth;
}

/// A stack of [CanvasRect] to be painted by [ChartCanvas].
class CanvasBarStack {
  factory CanvasBarStack(
    List<CanvasRect> segments, {
    double stackedBarPadding = 1,
  }) {
    final firstBarBounds = segments.first.bounds;

    // Find the rectangle that would represent the full stack of bars.
    double left = firstBarBounds.left;
    double top = firstBarBounds.top;
    double right = firstBarBounds.right;
    double bottom = firstBarBounds.bottom;

    for (int barIndex = 1; barIndex < segments.length; barIndex += 1) {
      final bounds = segments[barIndex].bounds;

      left = min(left, bounds.left);
      top = min(top, bounds.top);
      right = max(right, bounds.right);
      bottom = max(bottom, bounds.bottom);
    }

    final width = right - left;
    final height = bottom - top;
    final fullStackRect = Rect.fromLTWH(left, top, width, height);

    return CanvasBarStack._internal(
      segments,
      stackedBarPadding: stackedBarPadding,
      fullStackRect: fullStackRect,
    );
  }

  CanvasBarStack._internal(
    this.segments, {
    required this.stackedBarPadding,
    required this.fullStackRect,
  });

  final List<CanvasRect> segments;
  final double stackedBarPadding;
  final Rect fullStackRect;
}

/// A list of [CanvasPieSlice]s to be painted by [ChartCanvas].
class CanvasPie {
  CanvasPie(
    this.slices,
    this.center,
    this.radius,
    this.innerRadius, {
    this.stroke,
    required this.strokeWidth,
    required this.arcLength,
  });

  final List<CanvasPieSlice> slices;
  Offset center;
  double radius;
  double innerRadius;
  double arcLength;

  /// Color of separator lines between arcs.
  final Color? stroke;

  /// Stroke width of separator lines between arcs.
  double strokeWidth;
}

/// A circle sector to be painted by [ChartCanvas].
class CanvasPieSlice {
  CanvasPieSlice(this.startAngle, this.endAngle, {this.fill});

  double startAngle;
  double endAngle;
  Color? fill;
}
