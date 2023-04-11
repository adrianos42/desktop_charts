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

import 'dart:math' show atan2, cos, sin, pi, Point;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import '../../data/series.dart' show AttributeKey;
import '../../math.dart' show NullablePoint;
import '../base_chart.dart' show BaseChart;
import '../canvas_shapes.dart' show CanvasPieSlice, CanvasPie;
import '../chart_canvas.dart' show ChartCanvas;
import '../datum_details.dart' show DatumDetails;
import '../series_datum.dart' show SeriesDatum;
import '../series_renderer.dart' show BaseSeriesRenderer;
import 'arc_renderer_decorator.dart' show ArcRendererDecorator;
import 'arc_renderer_element.dart'
    show ArcRendererElement, ArcRendererElements, AnimatedArcs, AnimatedArc;
import 'base_arc_renderer_config.dart' show BaseArcRendererConfig;

const arcElementsKey =
    AttributeKey<List<ArcRendererElement<dynamic>>>('ArcRenderer.elements');

abstract class BaseArcRenderer<D, S extends BaseChart<D>>
    extends BaseSeriesRenderer<D, S> {
  BaseArcRenderer({
    required this.config,
    required super.rendererId,
    required super.chartState,
    required super.seriesList,
  })  : _arcRendererDecorators = config.arcRendererDecorators,
        super(symbolRenderer: config.symbolRenderer);

  final BaseArcRendererConfig<D> config;

  final List<ArcRendererDecorator<D>> _arcRendererDecorators;

  @override
  void configureSeries() {
    assignMissingColors(
      seriesList,
      emptyCategoryUsesSinglePalette: false,
    );
  }

  bool get isRtl => chartState.isRTL;

  /// Returns an expanded [DatumDetails] object that contains location data.
  DatumDetails<D> getExpandedDatumDetails(SeriesDatum<D> seriesDatum) {
    final series = seriesDatum.series;
    final Object? datum = seriesDatum.datum;
    final datumIndex = seriesDatum.index;

    final domain = series.domainFn(datumIndex);
    final measure = series.measureFn(datumIndex);
    final color = series.colorFn!(datumIndex);

    final chartPosition = _getChartPosition(series.id, '${series.id}__$domain');

    return DatumDetails(
      datum: datum,
      domain: domain,
      measure: measure,
      series: series,
      color: color,
      chartPosition: NullablePoint.from(chartPosition),
    );
  }

  /// Returns the List of AnimatedArcList associated with the renderer. The Pie
  /// Chart has one AnimatedArcList and the Sunburst chart usually has multiple
  /// elements.
  @protected
  List<AnimatedArcs<D>> getArcLists({String? seriesId});

  /// Returns the chart position for a given datum by series ID and domain
  /// value.
  ///
  /// [seriesId] the series ID.
  ///
  /// [key] the key in the current animated arc list.
  Offset? _getChartPosition(String seriesId, String key) {
    Offset? chartPosition;

    final arcLists = getArcLists(seriesId: seriesId);

    if (arcLists.isEmpty) {
      return chartPosition;
    }

    for (final arcList in arcLists) {
      for (final arc in arcList.arcs) {
        if (arc.key == key) {
          // Now that we have found the matching arc, calculate the center
          // point halfway between the inner and outer radius, and the start
          // and end angles.
          final centerAngle = arc.currentArcStartAngle! +
              (arc.currentArcEndAngle! - arc.currentArcStartAngle!) / 2.0;

          final centerPointRadius = arcList.innerRadius! +
              (arcList.radius! - arcList.innerRadius!) / 2.0;

          chartPosition = Offset(
            centerPointRadius * cos(centerAngle) + arcList.center!.dx,
            centerPointRadius * sin(centerAngle) + arcList.center!.dy,
          );

          break;
        }
      }
    }

    return chartPosition;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    super.paint(context, offset);

    final animationPercent = chartState.animationPosition.value; // TODO

    final bounds = Rect.fromLTWH(offset.dx, offset.dy, size.width, size.height);

    final arcLists = getArcLists();
    final arcsToElements = <AnimatedArcs<D>, ArcRendererElements<D>>{};

    for (final arcList in arcLists) {
      final elementsList = ArcRendererElements<D>(
        arcs: List.empty(growable: true),
        center: arcList.center!,
        innerRadius: arcList.innerRadius!,
        radius: arcList.radius!,
        startAngle: config.startAngle,
        stroke: arcList.stroke,
        strokeWidth: arcList.strokeWidth,
      );

      arcsToElements[arcList] = elementsList;
    }

    // Decorate the arcs with decorators that should appear below the main
    // series data.
    _arcRendererDecorators
        .where((decorator) => !decorator.renderAbove)
        .forEach((decorator) {
      decorator.decorate(
        arcLists
            .map<ArcRendererElements<D>>((e) => arcsToElements[e]!)
            .toList(),
        context.canvas,
        drawBounds: bounds,
        animationPercent: animationPercent,
        rtl: isRtl,
      );
    });

    for (final arcList in arcLists) {
      final circleSectors = <CanvasPieSlice>[];

      arcList.arcs
          .map<ArcRendererElement<D>>((AnimatedArc<D> animatingArc) =>
              animatingArc.getCurrentArc(animationPercent))
          .forEach((arc) {
        circleSectors.add(CanvasPieSlice(
          arc.startAngle,
          arc.endAngle,
          fill: arc.color,
        ));

        arcsToElements[arcList]!.arcs.add(arc);
      });

      // Draw the arcs.
      context.canvas.drawChartPie(
        CanvasPie(
          circleSectors,
          arcList.center!,
          arcList.radius!,
          arcList.innerRadius!,
          stroke: arcList.stroke,
          strokeWidth: arcList.strokeWidth ?? 0.0,
          arcLength: config.arcLength,
        ),
      );
    }

    // Decorate the arcs with decorators that should appear above the main
    // series data. This is the typical place for labels.
    _arcRendererDecorators
        .where((decorator) => decorator.renderAbove)
        .forEach((decorator) {
      decorator.decorate(
        arcLists
            .map<ArcRendererElements<D>>((e) => arcsToElements[e]!)
            .toList(),
        context.canvas,
        drawBounds: bounds,
        animationPercent: animationPercent,
        rtl: isRtl,
      );
    });
  }

  @override
  List<DatumDetails<D>> getNearestDatumDetailPerSeries(
    Offset chartPoint,
    bool byDomain,
    Rect? boundsOverride, {
    bool selectOverlappingPoints = false,
    bool selectExactEventLocation = false,
  }) {
    final nearest = <DatumDetails<D>>[];

    // Was it even in the component bounds?
    if (!isPointWithinBounds(chartPoint, boundsOverride!)) {
      return nearest;
    }

    final arcLists = getArcLists();

    for (final arcList in arcLists) {
      if (arcList.series!.overlaySeries) {
        return nearest;
      }

      final center = arcList.center!;
      final innerRadius = arcList.innerRadius!;
      final radius = arcList.radius!;

      final distance = Point(center.dx, center.dy).distanceTo(
        Point(chartPoint.dx, chartPoint.dy),
      );

      // Calculate the angle of [chartPoint] from the center of the arcs.
      double chartPointAngle = atan2(
        chartPoint.dy - center.dy,
        chartPoint.dx - center.dx,
      );

      // atan2 returns NaN if we are at the exact center of the circle.
      if (chartPointAngle.isNaN) {
        chartPointAngle = config.startAngle;
      }

      // atan2 returns an angle in the range -PI..PI, from the positive x-axis.
      // Our arcs start at the positive y-axis, in the range -PI/2..3PI/2. Thus,
      // if angle is in the -x, +y section of the circle, we need to adjust the
      // angle into our range.
      if (chartPointAngle < config.startAngle && chartPointAngle < 0) {
        chartPointAngle = 2 * pi + chartPointAngle;
      }

      for (final arc in arcList.arcs) {
        if (innerRadius <= distance &&
            distance <= radius &&
            arc.currentArcStartAngle! <= chartPointAngle &&
            chartPointAngle <= arc.currentArcEndAngle!) {
          nearest.add(DatumDetails<D>(
            series: arcList.series,
            datum: arc.datum,
            domain: arc.domain,
            domainDistance: 0.0,
            measureDistance: 0.0,
          ));
        }
      }
    }

    return nearest;
  }

  @override
  DatumDetails<D> addPositionToDetailsForSeriesDatum(
      DatumDetails<D> details, SeriesDatum<D> seriesDatum) {
    final chartPosition =
        _getChartPosition(details.series!.id, details.domain.toString());

    return DatumDetails.from(details,
        chartPosition: NullablePoint.from(chartPosition));
  }
}
