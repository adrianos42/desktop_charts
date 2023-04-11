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

import 'dart:math' show max;

import 'package:flutter/rendering.dart';

import '../base_chart.dart' show BaseChart;
import '../cartesian/axis/axis.dart' show ImmutableAxis;
import '../cartesian/cartesian_chart.dart' show CartesianChartState;
import '../layout/layout_view.dart'
    show
        LayoutPosition,
        LayoutViewPaintOrder,
        LayoutViewPositionOrder;
import '../processed_series.dart' show ImmutableSeries;
import 'point_renderer.dart' show AnimatedPoint, DatumPoint, PointRenderer;
import 'symbol_annotation_renderer_config.dart'
    show SymbolAnnotationRendererConfig;

/// Series renderer which draws a row of symbols for each series below the
/// drawArea but above the bottom axis.
///
/// This renderer can draw point annotations and range annotations. Offset
/// annotations are drawn at the location of the domain along the chart's domain
/// axis, in the row for its series. Range annotations are drawn as a range
/// shape between the domainLowerBound and domainUpperBound positions along the
/// chart's domain axis. Offset annotations are drawn on top of range
/// annotations.
///
/// Limitations:
/// Does not handle horizontal bars.
class SymbolAnnotationRenderer<D, S extends BaseChart<D>>
    extends PointRenderer<D, S> {
  SymbolAnnotationRenderer({
    String? rendererId,
    super.config,
    required super.chartState,
    required super.seriesList,
  }) : super(rendererId: rendererId ?? defaultRendererId);

  static const defaultRendererId = 'symbolAnnotation';

  double _currentHeight = 0.0;

  // ignore: prefer_collection_literals, https://github.com/dart-lang/linter/issues/1649
  final _seriesInfo = Map<String, _SeriesInfo<D>>();

  //
  // Renderer methods
  //
  /// Symbol annotations do not use any measure axes, or draw anything in the
  /// main draw area associated with them.
  @override
  void configureMeasureAxes() {}

  @override
  void preprocessSeries() {
    final localConfig = config as SymbolAnnotationRendererConfig;

    _seriesInfo.clear();

    double offset = 0.0;

    for (final series in seriesList) {
      final seriesKey = series.id;

      // Default to the configured radius if none was defined by the series.
      series.radiusFn ??= (_) => config.radius;

      double maxRadius = 0.0;
      for (int index = 0; index < series.data.length; index += 1) {
        // Default to the configured radius if none was returned by the
        // accessor function.
        double? radius = series.radiusFn?.call(index)?.toDouble();
        radius ??= config.radius;

        maxRadius = max(maxRadius, radius);
      }

      final rowInnerHeight = maxRadius * 2;

      final rowHeight = localConfig.verticalSymbolBottomPadding +
          localConfig.verticalSymbolTopPadding +
          rowInnerHeight;

      final symbolCenter =
          offset + localConfig.verticalSymbolTopPadding + (rowInnerHeight / 2);

      series.measureFn = (index) => 0;
      series.measureOffsetFn = (index) => 0;

      // Override the key function to allow for range annotations that start at
      // the same point. This is a necessary hack because every annotation has a
      // measure value of 0, so the key generated in [PointRenderer] is not
      // unique enough.
      series.keyFn ??= (index) => '${series.id}__${series.domainFn(index)}__'
          '${series.domainLowerBoundFn!(index)}__'
          '${series.domainUpperBoundFn!(index)}';

      _seriesInfo[seriesKey] = _SeriesInfo<D>(
        rowHeight: rowHeight,
        rowStart: offset,
        symbolCenter: symbolCenter,
      );

      offset += rowHeight;
    }

    _currentHeight = offset.ceilToDouble();

    super.preprocessSeries();
  }

  @override
  DatumPoint<D> getPoint(
    Object? datum,
    D? domainValue,
    D? domainLowerBoundValue,
    D? domainUpperBoundValue,
    ImmutableSeries<D> series,
    ImmutableAxis<D> domainAxis,
    num? measureValue,
    num? measureLowerBoundValue,
    num? measureUpperBoundValue,
    num? measureOffsetValue,
    ImmutableAxis<num> measureAxis,
  ) {
    final domainPosition = domainAxis.getLocation(domainValue);

    final bounds = Rect.fromLTWH(0.0, 0.0, size.width, size.height); // TODO

    final domainLowerBoundPosition = domainLowerBoundValue != null
        ? domainAxis.getLocation(domainLowerBoundValue)
        : null;

    final domainUpperBoundPosition = domainUpperBoundValue != null
        ? domainAxis.getLocation(domainUpperBoundValue)
        : null;

    final seriesKey = series.id;
    final seriesInfo = _seriesInfo[seriesKey]!;

    final measurePosition = bounds.top + seriesInfo.symbolCenter;

    final measureLowerBoundPosition =
        domainLowerBoundPosition != null ? measurePosition : null;

    final measureUpperBoundPosition =
        domainUpperBoundPosition != null ? measurePosition : null;

    return DatumPoint<D>(
        datum: datum,
        domain: domainValue,
        series: series,
        x: domainPosition,
        xLower: domainLowerBoundPosition,
        xUpper: domainUpperBoundPosition,
        y: measurePosition,
        yLower: measureLowerBoundPosition,
        yUpper: measureUpperBoundPosition);
  }

  @override
  void paint(
    PaintingContext context,
    Offset offset,
  ) {
    update(offset);

    super.paint(context, offset);

    // Use the domain axis of the attached chart to render the separator lines
    // to keep the same overall style.
    if ((config as SymbolAnnotationRendererConfig).showSeparatorLines) {
      seriesPointMap.forEach((String key, List<AnimatedPoint<D>> points) {
        final seriesInfo = _seriesInfo[key]!;

        final y = offset.dy + seriesInfo.rowStart;

        final domainAxis = (chartState as CartesianChartState).domainAxis!;
        final bounds =
            Rect.fromLTWH(offset.dx, y.roundToDouble(), size.width, 0);
        domainAxis.tickDrawStrategy.drawAxisLine(
          context.canvas,
          domainAxis.axisDirection,
          bounds,
        );
      });
    }
  }

  //
  // Layout methods
  //

  // TODO @override
  // LayoutViewConfig get layoutConfig {
  //   return const LayoutViewConfig(
  //     paintOrder: LayoutViewPaintOrder.point,
  //     position: LayoutPosition.bottom,
  //     positionOrder: LayoutViewPositionOrder.symbolAnnotation,
  //   );
  // }

  @override
  void performLayout() {
    // The sizing of component is not flexible. It's height is always a multiple
    // of the number of series rendered, even if that ends up taking all of the
    // available margin space.
    size = Size(constraints.maxWidth, _currentHeight);
  }
}

class _SeriesInfo<D> {
  _SeriesInfo({
    required this.rowHeight,
    required this.rowStart,
    required this.symbolCenter,
  });

  double rowHeight;
  double rowStart;
  double symbolCenter;
}
