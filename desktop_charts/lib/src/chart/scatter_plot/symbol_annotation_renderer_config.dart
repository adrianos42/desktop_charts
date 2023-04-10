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

import 'package:flutter/widgets.dart';

import '../../symbol_renderer.dart';
import '../base_chart.dart' show BaseChart, BaseChartState;
import '../processed_series.dart' show MutableSeries;
import '../series_renderer_config.dart' show BaseSeriesRenderObjectWidget;
import 'comparison_points_decorator.dart' show ComparisonPointsDecorator;
import 'point_renderer_config.dart' show PointRendererConfig;
import 'point_renderer_decorator.dart' show PointRendererDecorator;
import 'symbol_annotation_renderer.dart' show SymbolAnnotationRenderer;

/// Configuration for [SymbolAnnotationRenderer].
///
/// This renderer is configured with a [ComparisonPointsDecorator] by default,
/// used to draw domain ranges. This decorator will draw a rectangular shape
/// between the points (domainLowerBound, measureLowerBound) and
/// (domainUpperBound, measureUpperBound), beneath the primary point for each
/// series.
class SymbolAnnotationRendererConfig<D> extends PointRendererConfig<D> {
  SymbolAnnotationRendererConfig({
    String? customRendererId,
    List<PointRendererDecorator<D>>? pointRendererDecorators,
    double radius = 5.0,
    SymbolRenderer? symbolRenderer,
    Map<String, SymbolRenderer>? customSymbolRenderers,
    this.showBottomSeparatorLine = false,
    this.showSeparatorLines = true,
    this.verticalSymbolBottomPadding = 5.0,
    this.verticalSymbolTopPadding = 5.0,
  }) : super(
            customRendererId: customRendererId,
            pointRendererDecorators: pointRendererDecorators ??
                [
                  ComparisonPointsDecorator<D>(
                    symbolRenderer: const RectangleRangeSymbolRenderer(),
                  )
                ],
            radius: radius,
            symbolRenderer: symbolRenderer,
            customSymbolRenderers: customSymbolRenderers);

  /// Whether a separator line should be drawn between the bottom row of
  /// rendered symbols and the axis ticks/labels.
  final bool showBottomSeparatorLine;

  /// Whether or not separator lines will be rendered between rows of rendered
  /// symbols.
  final bool showSeparatorLines;

  /// Space reserved at the bottom of each row where the symbol should not
  /// render into.
  final double verticalSymbolBottomPadding;

  /// Space reserved at the top of each row where the symbol should not render
  /// into.
  final double verticalSymbolTopPadding;

  @override
  Widget build<S extends BaseChart<D>>(
    BuildContext context, {
    required Key key,
    required BaseChartState<D, S> chartState,
    required List<MutableSeries<D>> seriesList,
    String? rendererId,
  }) {
    return _SymbolAnnotationRenderObjectWidget(
      chartState: chartState,
      config: this,
      key: key,
      seriesList: seriesList,
      rendererId: rendererId,
    );
  }
}

class _SymbolAnnotationRenderObjectWidget<D, S extends BaseChart<D>>
    extends BaseSeriesRenderObjectWidget<D, S, SymbolAnnotationRenderer<D, S>,
        SymbolAnnotationRendererConfig<D>> {
  const _SymbolAnnotationRenderObjectWidget({
    required super.chartState,
    required super.config,
    required super.key,
    required super.seriesList,
    required super.rendererId,
  });

  @override
  SymbolAnnotationRenderer<D, S> createRenderObject(BuildContext context) =>
      SymbolAnnotationRenderer<D, S>(
        rendererId: rendererId,
        config: config,
        chartState: chartState,
        seriesList: seriesList,
      );
}
