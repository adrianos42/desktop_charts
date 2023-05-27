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

import 'package:collection/collection.dart' show ListEquality;
import 'package:flutter/widgets.dart';

import '../../symbol_renderer.dart';
import '../base_chart.dart' show BaseChart, BaseChartState;
import '../series_renderer_config.dart' show SeriesRendererConfig;
import 'line_renderer.dart' show LineRenderer;
import '../../curve.dart';

/// Configuration for a line renderer.
@immutable
class LineRendererConfig<D> extends SeriesRendererConfig<D> {
  const LineRendererConfig({
    this.customRendererId,
    this.radius = 3.5,
    this.stacked = false,
    this.strokeWidth = 2.0,
    this.dashPattern,
    this.includeLine = true,
    this.includePoints = false,
    this.includeArea = false,
    this.areaOpacity = 0.1,
    this.roundEndCaps = false,
    this.lineCurve = LineCurve.linearCurve,
    SymbolRenderer? symbolRenderer,
  }) : symbolRenderer = symbolRenderer ?? const LineSymbolRenderer();

  @override
  final String? customRendererId;

  @override
  final SymbolRenderer symbolRenderer;

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

  /// Configures the opacity of the area skirt on the chart.
  final double areaOpacity;

  /// Whether lines should have round end caps, or square if false.
  final bool roundEndCaps;

  /// The default curve for all series.
  final LineCurve lineCurve;

  @override
  LineRenderer<D, S> build<S extends BaseChart<D>>({
    required BaseChartState<D, S> chartState,
    String? rendererId,
  }) {
    return LineRenderer(
      chartState: chartState,
      rendererId: rendererId,
      config: this,
    );
  }

  @override
  bool operator ==(covariant LineRendererConfig<D> other) {
    if (identical(this, other)) {
      return true;
    }
    return other.customRendererId == customRendererId &&
        other.symbolRenderer == symbolRenderer &&
        other.radius == radius &&
        other.stacked == stacked &&
        other.strokeWidth == strokeWidth &&
        const ListEquality<int>().equals(other.dashPattern, dashPattern) &&
        other.includeLine == includeLine &&
        other.includePoints == includePoints &&
        other.includeArea == includeArea &&
        other.areaOpacity == areaOpacity &&
        other.roundEndCaps == roundEndCaps &&
        other.lineCurve == lineCurve;
  }

  @override
  int get hashCode => Object.hash(
        customRendererId,
        symbolRenderer,
        radius,
        stacked,
        strokeWidth,
        dashPattern,
        includeLine,
        includePoints,
        includeArea,
        areaOpacity,
        roundEndCaps,
        lineCurve,
      );
}
