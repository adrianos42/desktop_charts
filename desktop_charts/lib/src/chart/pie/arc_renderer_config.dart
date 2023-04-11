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

import 'package:flutter/widgets.dart';

import '../base_chart.dart' show BaseChart, BaseChartState;
import '../processed_series.dart' show MutableSeries;
import '../series_renderer_config.dart';
import 'arc_renderer.dart' show ArcRenderer;
import 'base_arc_renderer_config.dart' show BaseArcRendererConfig;

/// Configuration for an [ArcRenderer].
class ArcRendererConfig<D> extends BaseArcRendererConfig<D> {
  ArcRendererConfig({
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
  Widget build<S extends BaseChart<D>>(
    BuildContext context, {
    required Key key,
    required BaseChartState<D, S> chartState,
    required List<MutableSeries<D>> seriesList,
    String? rendererId,
  }) {
    return _ArcRenderObjectWidget(
      chartState: chartState,
      rendererId: rendererId,
      seriesList: seriesList,
      config: this,
      key: key,
    );
  }
}

class _ArcRenderObjectWidget<D, S extends BaseChart<D>>
    extends BaseSeriesRenderObjectWidget<D, S, ArcRenderer<D, S>,
        ArcRendererConfig<D>> {
  const _ArcRenderObjectWidget({
    required super.chartState,
    required super.config,
    required super.key,
    required super.rendererId,
    required super.seriesList,
  });

  @override
  ArcRenderer<D, S> createRenderObject(BuildContext context) =>
      ArcRenderer<D, S>(
        rendererId: rendererId,
        config: config,
        chartState: chartState,
        seriesList: seriesList,
      );
}
