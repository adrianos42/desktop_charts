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
import '../layout/layout_view.dart' show LayoutViewConfig, LayoutViewPaintOrder;
import '../processed_series.dart' show MutableSeries;
import '../series_renderer_config.dart'
    show RendererAttributes, SeriesRendererConfig, BaseSeriesRenderObjectWidget;
import 'line_renderer.dart' show LineRenderer;

/// Configuration for a line renderer.
@immutable
class LineRendererConfig<D> extends LayoutViewConfig
    implements SeriesRendererConfig<D> {
  LineRendererConfig({
    this.customRendererId,
    this.radius = 3.5,
    this.stacked = false,
    this.strokeWidth = 2.0,
    this.dashPattern,
    this.includeLine = true,
    this.includePoints = false,
    this.includeArea = false,
    this.layoutPaintOrder = LayoutViewPaintOrder.line,
    this.areaOpacity = 0.1,
    this.roundEndCaps = false,
    SymbolRenderer? symbolRenderer,
  }) : symbolRenderer = symbolRenderer ?? const LineSymbolRenderer();

  @override
  final String? customRendererId;

  @override
  final SymbolRenderer symbolRenderer;

  @override
  final RendererAttributes rendererAttributes = RendererAttributes();

  /// Radius of points on the line, if [includePoints] is enabled.
  final double radius;

  /// Whether or not series should be rendered in a stack.
  ///
  /// This is typically enabled when including area skirts.
  final bool stacked;

  /// Stroke width of the line.
  final double strokeWidth;

  /// Dash pattern for the line.
  final List<int>? dashPattern;

  /// Configures whether a line representing the data will be drawn.
  final bool includeLine;

  /// Configures whether points representing the data will be drawn.
  final bool includePoints;

  /// Configures whether an area skirt representing the data will be drawn.
  ///
  /// An area skirt will be drawn from the line for each series, down to the
  /// domain axis. It will be layered underneath the primary line on the chart.
  ///
  /// The area skirt color will be a semi-transparent version of the series
  /// color, using [areaOpacity] as the opacity.
  ///
  /// When stacking is enabled, the bottom of each area skirt will instead be
  /// the previous line in the stack. The bottom area will be drawn down to the
  /// domain axis.
  final bool includeArea;

  /// The order to paint this renderer on the canvas.
  final int layoutPaintOrder;

  /// Configures the opacity of the area skirt on the chart.
  final double areaOpacity;

  /// Whether lines should have round end caps, or square if false.
  final bool roundEndCaps;

  @override
  Widget build<S extends BaseChart<D>>(
    BuildContext context, {
    required Key key,
    required BaseChartState<D, S> chartState,
    required List<MutableSeries<D>> seriesList,
    String? rendererId,
  }) {
    return _LineRenderObjectWidget(
      chartState: chartState,
      config: this,
      key: key,
      rendererId: rendererId,
      seriesList: seriesList,
    );
  }
}

class _LineRenderObjectWidget<D, S extends BaseChart<D>>
    extends BaseSeriesRenderObjectWidget<D, S, LineRenderer<D, S>,
        LineRendererConfig<D>> {
  const _LineRenderObjectWidget({
    required super.chartState,
    required super.config,
    required super.key,
    required super.rendererId,
    required super.seriesList,
  });

  @override
  LineRenderer<D, S> createRenderObject(BuildContext context) =>
      LineRenderer<D, S>(
        rendererId: rendererId,
        config: config,
        chartState: chartState,
        seriesList: seriesList,
      );
}
