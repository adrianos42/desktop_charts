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

import 'dart:math' show pi;

import 'package:collection/collection.dart' show ListEquality;
import 'package:flutter/widgets.dart';

import '../../symbol_renderer.dart';
import '../series_renderer_config.dart' show SeriesRendererConfig;
import 'arc_renderer_decorator.dart' show ArcRendererDecorator;

/// The base renderer config for arc renderer and sunburst arc renderer.
@immutable
abstract class BaseArcRendererConfig<D> extends SeriesRendererConfig<D> {
  const BaseArcRendererConfig({
    this.customRendererId,
    this.arcLength = 2.0 * pi,
    this.arcRendererDecorators = const [],
    this.arcRatio,
    this.arcWidth,
    this.minHoleWidthForCenterContent = 30.0,
    this.startAngle = -pi / 2.0,
    this.strokeWidth = 1.0,
    SymbolRenderer? symbolRenderer,
  }) : symbolRenderer = symbolRenderer ?? const CircleSymbolRenderer();

  @override
  final String? customRendererId;

  @override
  final SymbolRenderer symbolRenderer;

  /// List of decorators applied to rendered arcs.
  final List<ArcRendererDecorator<D>> arcRendererDecorators;

  /// Total arc length, in radians.
  ///
  /// The default arcLength is 2π.
  final double arcLength;

  /// If set, configures the arcWidth to be a percentage of the radius.
  final double? arcRatio;

  /// Fixed width of the arc within the radius.
  ///
  /// If arcRatio is set, this value will be ignored.
  final double? arcWidth;

  /// Minimum radius of the hole in a donut chart for center content
  /// to appear.
  final double minHoleWidthForCenterContent;

  /// Start angle for pie slices, in radians.
  ///
  /// Angles are defined from the positive x axis in Cartesian space. The
  /// default startAngle is -π/2.
  final double startAngle;

  /// Stroke width of the border of the arcs.
  final double strokeWidth;

  @override
  bool operator ==(covariant BaseArcRendererConfig<D> other) {
    if (identical(this, other)) {
      return true;
    }
    return other.customRendererId == customRendererId &&
        ListEquality<ArcRendererDecorator<D>>()
            .equals(other.arcRendererDecorators, arcRendererDecorators) &&
        other.symbolRenderer == symbolRenderer &&
        other.arcLength == arcLength &&
        other.arcRatio == arcRatio &&
        other.arcWidth == arcWidth &&
        other.minHoleWidthForCenterContent == minHoleWidthForCenterContent &&
        other.startAngle == startAngle &&
        other.strokeWidth == strokeWidth;
  }

  @override
  int get hashCode => Object.hash(
        customRendererId,
        arcRendererDecorators,
        symbolRenderer,
        arcLength,
        arcRatio,
        arcWidth,
        minHoleWidthForCenterContent,
        startAngle,
        strokeWidth,
      );
}
