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

import '../base_chart.dart' show BaseChart, BaseChartState;
import '../series_renderer.dart';
import 'arc_renderer.dart' show ArcRenderer;
import 'arc_renderer_decorator.dart' show ArcRendererDecorator;
import 'base_arc_renderer_config.dart' show BaseArcRendererConfig;

/// Configuration for an [ArcRenderer].
@immutable
class ArcRendererConfig<D> extends BaseArcRendererConfig<D> {
  const ArcRendererConfig({
    super.symbolRenderer,
    super.customRendererId,
    super.arcLength = 2 * pi,
    super.arcRatio,
    super.arcWidth,
    super.minHoleWidthForCenterContent = 30,
    super.startAngle = -pi / 2,
    super.strokeWidth = 1.0,
    super.arcRendererDecorators,
  });

  @override
  SeriesRenderer<D, S> build<S extends BaseChart<D>>({
    required BaseChartState<D, S> chartState,
    String? rendererId,
  }) {
    return ArcRenderer<D, S>(
      chartState: chartState,
      rendererId: rendererId,
      config: this,
    );
  }

  @override
  bool operator ==(covariant ArcRendererConfig<D> other) {
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
