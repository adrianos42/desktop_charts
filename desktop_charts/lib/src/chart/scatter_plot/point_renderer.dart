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

import 'dart:math' show min, Point;

import 'package:collection/collection.dart' show IterableExtension;
import 'package:flutter/widgets.dart';
import 'package:vector_math/vector_math.dart' show Vector2;

import '../../data/series.dart' show Accessor, AttributeKey, TypedAccessor;
import '../../math.dart' show distanceBetweenPointAndLineSegment, NullablePoint;
import '../../symbol_renderer.dart' show CircleSymbolRenderer, SymbolRenderer;
import '../base_chart.dart' show BaseChart;
import '../cartesian/axis/axis.dart' show ImmutableAxis, measureAxisIdKey;
import '../cartesian/cartesian_chart.dart';
import '../cartesian/cartesian_renderer.dart' show BaseCartesianRenderer;
import '../chart_canvas.dart' show getAnimatedColor;
import '../datum_details.dart' show DatumDetails;
import '../processed_series.dart' show ImmutableSeries;
import '../series_datum.dart' show SeriesDatum;
import 'comparison_points_decorator.dart' show ComparisonPointsDecorator;
import 'point_renderer_config.dart' show PointRendererConfig;
import 'point_renderer_decorator.dart' show PointRendererDecorator;

const pointElementsKey =
    AttributeKey<List<PointRendererElement<Object>>>('PointRenderer.elements');

const pointSymbolRendererFnKey =
    AttributeKey<Accessor<String?>>('PointRenderer.symbolRendererFn');

const pointSymbolRendererIdKey =
    AttributeKey<String>('PointRenderer.symbolRendererId');

/// Defines a fixed radius for data bounds lines (typically drawn by attaching a
/// [ComparisonPointsDecorator] to the renderer.
const boundsLineRadiusKey =
    AttributeKey<double>('SymbolAnnotationRenderer.boundsLineRadius');

/// Defines an [AccessorFn] for the radius for data bounds lines (typically
/// drawn by attaching a [ComparisonPointsDecorator] to the renderer.
const boundsLineRadiusFnKey = AttributeKey<Accessor<double?>>(
    'SymbolAnnotationRenderer.boundsLineRadiusFn');

const defaultSymbolRendererId = '__default__';

/// Large number used as a starting sentinel for data distance comparisons.
///
/// This is generally larger than the distance from any datum to the mouse.
const _maxInitialDistance = 10000.0;

class PointRenderer<D, S extends BaseChart<D>>
    extends BaseCartesianRenderer<D, S> {
  PointRenderer({
    String? rendererId,
    PointRendererConfig<D>? config,
    required super.chartState,
    required super.seriesList,
  })  : config = config ?? PointRendererConfig<D>(),
        pointRendererDecorators = config?.pointRendererDecorators ?? [],
        super(
          rendererId: rendererId ?? 'point',
          symbolRenderer:
              config?.symbolRenderer ?? const CircleSymbolRenderer(),
        );

  final PointRendererConfig<D> config;

  final List<PointRendererDecorator<D>> pointRendererDecorators;

  /// Store a map of series drawn on the chart, mapped by series name.
  ///
  /// [Map] is used to render the series on the canvas in the same
  /// order as the data was given to the chart.
  @protected
  // ignore: prefer_collection_literals, https://github.com/dart-lang/linter/issues/1649
  var seriesPointMap = Map<String, List<AnimatedPoint<D>>>();

  // Store a list of lines that exist in the series data.
  //
  // This list will be used to remove any [_AnimatedPoint] that were rendered in
  // previous draw cycles, but no longer have a corresponding datum in the new
  // data.
  final _currentKeys = <String>[];

  @override
  void configureSeries() {
    // TODO assignMissingColors(seriesList, emptyCategoryUsesSinglePalette: false);
  }

  @override
  void preprocessSeries() {
    for (final series in seriesList) {
      final elements = <PointRendererElement<D>>[];

      // Default to the configured radius if none was defined by the series.
      series.radiusFn ??= (_) => config.radius;

      // Create an accessor function for the bounds line radius, if needed. If
      // the series doesn't define an accessor function, then each datum's
      // boundsLineRadius value will be filled in by using the following
      // values, in order of what is defined:
      //
      // 1) boundsLineRadius defined on the series.
      // 2) boundsLineRadius defined on the renderer config.
      // 3) Final fallback is to use the point radius for this datum.
      var boundsLineRadiusFn = series.getAttr(boundsLineRadiusFnKey);

      if (boundsLineRadiusFn == null) {
        double? boundsLineRadius = series.getAttr(boundsLineRadiusKey);
        boundsLineRadius ??= config.boundsLineRadius;
        if (boundsLineRadius != null) {
          boundsLineRadiusFn = (_) => boundsLineRadius!.toDouble();
          series.setAttr(boundsLineRadiusFnKey, boundsLineRadiusFn);
        }
      }

      final symbolRendererFn = series.getAttr(pointSymbolRendererFnKey);

      // Add a key function to help animate points moved in position in the
      // series data between chart draw cycles. Ideally we should require the
      // user to provide a key function, but this at least provides some
      // smoothing when adding/removing data.
      series.keyFn ??=
          (int? index) => '${series.id}__${series.domainFn(index)}__'
              '${series.measureFn(index)}';

      for (int index = 0; index < series.data.length; index += 1) {
        // Default to the configured radius if none was returned by the
        // accessor function.
        double? radius = series.radiusFn!(index);
        radius ??= config.radius;

        double? boundsLineRadius;
        if (boundsLineRadiusFn != null) {
          boundsLineRadius = (boundsLineRadiusFn is TypedAccessor)
              ? (boundsLineRadiusFn as TypedAccessor<dynamic, double>)(
                  series.data[index], index)
              : boundsLineRadiusFn(index);
        }
        boundsLineRadius ??= config.boundsLineRadius;
        boundsLineRadius ??= radius;

        // Default to the configured stroke width if none was returned by the
        // accessor function.
        double? strokeWidth =
            series.strokeWidthFn != null ? series.strokeWidthFn!(index) : null;
        strokeWidth ??= config.strokeWidth;

        // Get the ID of the [SymbolRenderer] for this point. An ID may be
        // specified on the datum, or on the series. If neither is specified,
        // fall back to the default.
        String? symbolRendererId;
        if (symbolRendererFn != null) {
          symbolRendererId = symbolRendererFn(index);
        }
        symbolRendererId ??= series.getAttr(pointSymbolRendererIdKey);
        symbolRendererId ??= defaultSymbolRendererId;

        // Get the colors. If no fill color is provided, default it to the
        // primary data color.
        final colorFn = series.colorFn;
        final fillColorFn = series.fillColorFn ?? colorFn;

        final color = colorFn!(index);

        // Fill color is an optional override for color. Make sure we get a
        // value if the series doesn't define anything specific.
        Color? fillColor = fillColorFn!(index);
        fillColor ??= color;

        final details = PointRendererElement<D>(
          index: index,
          color: color,
          fillColor: fillColor,
          radius: radius.toDouble(),
          boundsLineRadius: boundsLineRadius.toDouble(),
          strokeWidth: strokeWidth.toDouble(),
          symbolRendererId: symbolRendererId,
        );

        elements.add(details);
      }

      series.setAttr(pointElementsKey, elements);
    }
  }

  @override
  void update(Offset offset) {
    super.update(offset);

    _currentKeys.clear();

    // Build a list of sorted series IDs as we iterate through the list, used
    // later for sorting.
    final sortedSeriesIds = <String>[];

    for (final series in seriesList) {
      sortedSeriesIds.add(series.id);

      final domainAxis =
          (chartState as CartesianChartState<D, CartesianChart<D>>).domainAxis;
      final domainFn = series.domainFn;
      final domainLowerBoundFn = series.domainLowerBoundFn;
      final domainUpperBoundFn = series.domainUpperBoundFn;
      final measureAxis =
          (chartState as CartesianChartState<D, CartesianChart<D>>)
              .getMeasureAxis(axisId: series.getAttr(measureAxisIdKey));
      final measureFn = series.measureFn;
      final measureLowerBoundFn = series.measureLowerBoundFn;
      final measureUpperBoundFn = series.measureUpperBoundFn;
      final measureOffsetFn = series.measureOffsetFn;
      final seriesKey = series.id;
      final keyFn = series.keyFn!;

      final pointList = seriesPointMap.putIfAbsent(seriesKey, () => []);

      final elementsList = series.getAttr(pointElementsKey);

      for (int index = 0; index < series.data.length; index += 1) {
        final Object? datum = series.data[index];
        final details = elementsList![index];

        final domainValue = domainFn(index);
        final domainLowerBoundValue = domainLowerBoundFn?.call(index);
        final domainUpperBoundValue = domainUpperBoundFn?.call(index);

        final measureValue = measureFn(index);
        final measureLowerBoundValue = measureLowerBoundFn?.call(index);
        final measureUpperBoundValue = measureUpperBoundFn?.call(index);
        final measureOffsetValue = measureOffsetFn!(index);

        // Create a point using the final location.
        final point = getPoint(
          datum,
          domainValue,
          domainLowerBoundValue,
          domainUpperBoundValue,
          series,
          domainAxis!,
          measureValue,
          measureLowerBoundValue,
          measureUpperBoundValue,
          measureOffsetValue,
          measureAxis,
        );

        final pointKey = keyFn(index);

        // If we already have an AnimatingPoint for that index, use it.
        AnimatedPoint<D>? animatingPoint =
            pointList.firstWhereOrNull((point) => point.key == pointKey);

        // If we don't have any existing arc element, create a arc and
        // have it animate in from the position of the previous arc's end
        // angle. If there were no previous arcs, then animate everything in
        // from 0.
        if (animatingPoint == null) {
          // Create a point and have it animate in from axis.
          final point = getPoint(
              datum,
              domainValue,
              domainLowerBoundValue,
              domainUpperBoundValue,
              series,
              domainAxis,
              0.0,
              0.0,
              0.0,
              0.0,
              measureAxis);

          animatingPoint = AnimatedPoint<D>(
              key: pointKey, overlaySeries: series.overlaySeries)
            ..setNewTarget(PointRendererElement<D>(
              index: details.index,
              color: details.color,
              fillColor: details.fillColor,
              measureAxisPosition: measureAxis.getLocation(0.0),
              point: point,
              radius: details.radius,
              boundsLineRadius: details.boundsLineRadius,
              strokeWidth: details.strokeWidth,
              symbolRendererId: details.symbolRendererId,
            ));

          pointList.add(animatingPoint);
        }

        // Update the set of arcs that still exist in the series data.
        _currentKeys.add(pointKey);

        // Get the pointElement we are going to setup.
        final pointElement = PointRendererElement<D>(
          index: index,
          color: details.color,
          fillColor: details.fillColor,
          measureAxisPosition: measureAxis.getLocation(0.0),
          point: point,
          radius: details.radius,
          boundsLineRadius: details.boundsLineRadius,
          strokeWidth: details.strokeWidth,
          symbolRendererId: details.symbolRendererId,
        );

        animatingPoint.setNewTarget(pointElement);
      }
    }

    // Sort the renderer elements to be in the same order as the series list.
    // They may get disordered between chart draw cycles if a behavior adds or
    // removes series from the list (e.g. click to hide on legends).
    seriesPointMap = {for (final k in sortedSeriesIds) k: seriesPointMap[k]!};

    // Animate out points that don't exist anymore.
    seriesPointMap.forEach((String key, List<AnimatedPoint<D>> points) {
      for (final point in points) {
        if (_currentKeys.contains(point.key) != true) {
          point.animateOut();
        }
      }
    });
  }

  @override
  void paint(
    PaintingContext context,
    Offset offset,
  ) {
    update(offset);

    super.paint(context, offset);

    final animationPercent = chartState.animationPosition.value;
    final bounds = Rect.fromLTWH(offset.dx, offset.dy, size.width, size.height);

    // Clean up the points that no longer exist.
    if (chartState.animationPosition.isCompleted) {
      final keysToRemove = <String>[];

      seriesPointMap.forEach((String key, List<AnimatedPoint<D>> points) {
        points.removeWhere((AnimatedPoint<D> point) => point.animatingOut);

        if (points.isEmpty) {
          keysToRemove.add(key);
        }
      });

      keysToRemove.forEach(seriesPointMap.remove);
    }

    seriesPointMap.forEach((String key, List<AnimatedPoint<D>> points) {
      points
          .map<PointRendererElement<D>>((AnimatedPoint<D> animatingPoint) =>
              animatingPoint.getCurrentPoint(animationPercent))
          .forEach((point) {
        // Decorate the points with decorators that should appear below the main
        // series data.
        pointRendererDecorators
            .where((decorator) => !decorator.renderAbove)
            .forEach((decorator) {
          decorator.decorate(
            point,
            context.canvas,
            drawBounds: bounds,
            animationPercent: animationPercent,
            rtl: isRtl,
          );
        });

        // Skip points whose center lies outside the draw bounds. Those that lie
        // near the edge will be allowed to render partially outside. This
        // prevents harshly clipping off half of the shape.
        if (point.point!.dy != null &&
            bounds.contains(point.point!.toPoint())) {
          final bounds = Rect.fromLTWH(
            point.point!.dx! - point.radius,
            point.point!.dy! - point.radius,
            point.radius * 2.0,
            point.radius * 2.0,
          );

          if (point.symbolRendererId == defaultSymbolRendererId) {
            symbolRenderer!.paint(context.canvas, bounds,
                fillColor: point.fillColor,
                strokeColor: point.color,
                strokeWidth: point.strokeWidth);
          } else {
            final id = point.symbolRendererId;
            if (!config.customSymbolRenderers!.containsKey(id)) {
              throw ArgumentError('Invalid custom symbol renderer id "$id"');
            }

            final customRenderer = config.customSymbolRenderers![id]!;
            customRenderer.paint(context.canvas, bounds,
                fillColor: point.fillColor,
                strokeColor: point.color,
                strokeWidth: point.strokeWidth);
          }
        }

        // Decorate the points with decorators that should appear above the main
        // series data. This is the typical place for labels.
        pointRendererDecorators
            .where((decorator) => decorator.renderAbove)
            .forEach((decorator) {
          decorator.decorate(
            point,
            context.canvas,
            drawBounds: bounds,
            animationPercent: animationPercent,
            rtl: isRtl,
          );
        });
      });
    });
  }

  bool get isRtl => chartState.isRTL;

  @protected
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

    final domainLowerBoundPosition = domainLowerBoundValue != null
        ? domainAxis.getLocation(domainLowerBoundValue)
        : null;

    final domainUpperBoundPosition = domainUpperBoundValue != null
        ? domainAxis.getLocation(domainUpperBoundValue)
        : null;

    final measurePosition = measureValue != null && measureOffsetValue != null
        ? measureAxis
            .getLocation((measureValue + measureOffsetValue).toDouble())
        : null;

    final measureLowerBoundPosition = measureLowerBoundValue != null
        ? measureAxis.getLocation(
            (measureLowerBoundValue + measureOffsetValue!).toDouble())
        : null;

    final measureUpperBoundPosition = measureUpperBoundValue != null
        ? measureAxis.getLocation(
            (measureUpperBoundValue + measureOffsetValue!).toDouble())
        : null;

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
  List<DatumDetails<D>> getNearestDatumDetailPerSeries(
    Offset chartPoint,
    bool byDomain,
    Rect? boundsOverride, {
    bool selectOverlappingPoints = false,
    bool selectExactEventLocation = false,
  }) {
    final nearest = <DatumDetails<D>>[];
    final inside = <DatumDetails<D>>[];

    // Was it even in the component bounds?
    if (!isPointWithinBounds(chartPoint, boundsOverride!)) {
      return nearest;
    }

    for (final points in seriesPointMap.values) {
      PointRendererElement<D>? nearestPoint;

      _Distances nearestDistances = const _Distances(
        domainDistance: _maxInitialDistance,
        measureDistance: _maxInitialDistance,
        relativeDistance: _maxInitialDistance,
      );

      for (final point in points) {
        if (point.overlaySeries) {
          break;
        }

        final p = point._currentPoint!.point!;

        final componentBounds =
            Rect.fromLTWH(0.0, 0.0, size.width, size.height); // TODO

        // Don't look at points not in the drawArea.
        if (p.dx! < componentBounds.left || p.dx! > componentBounds.right) {
          break;
        }

        final distances = _getDatumDistance(point, chartPoint);

        if (selectOverlappingPoints) {
          if (distances.insidePoint!) {
            inside.add(_createDatumDetails(point._currentPoint!, distances));
          }
        }

        // If any point was added to the inside list on previous iterations,
        // we don't need to go through calculating nearest points because we
        // only return inside list as a result in that case.
        if (inside.isEmpty) {
          // Do not consider the points outside event location when
          // selectExactEventLocation flag is set.
          if (!selectExactEventLocation || distances.insidePoint!) {
            if (byDomain) {
              if ((distances.domainDistance <
                      nearestDistances.domainDistance) ||
                  (distances.domainDistance ==
                          nearestDistances.domainDistance &&
                      distances.measureDistance <
                          nearestDistances.measureDistance)) {
                nearestPoint = point._currentPoint;
                nearestDistances = distances;
              }
            } else {
              if (distances.relativeDistance <
                  nearestDistances.relativeDistance) {
                nearestPoint = point._currentPoint;
                nearestDistances = distances;
              }
            }
          }
        }
      }

      // Found a point, add it to the list.
      if (nearestPoint != null) {
        nearest.add(_createDatumDetails(nearestPoint, nearestDistances));
      }
    }

    // Note: the details are already sorted by domain & measure distance in
    // base chart. If asking for all overlapping points, return the list of
    // inside points - only if there was overlap.
    return (selectOverlappingPoints && inside.isNotEmpty) ? inside : nearest;
  }

  DatumDetails<D> _createDatumDetails(
      PointRendererElement<D> point, _Distances distances) {
    SymbolRenderer? pointSymbolRenderer;
    if (point.symbolRendererId == defaultSymbolRendererId) {
      pointSymbolRenderer = symbolRenderer;
    } else {
      final id = point.symbolRendererId;
      if (!config.customSymbolRenderers!.containsKey(id)) {
        throw ArgumentError('Invalid custom symbol renderer id "$id"');
      }
      pointSymbolRenderer = config.customSymbolRenderers![id];
    }
    return DatumDetails<D>(
      datum: point.point!.datum,
      domain: point.point!.domain,
      series: point.point!.series,
      domainDistance: distances.domainDistance,
      measureDistance: distances.measureDistance,
      relativeDistance: distances.relativeDistance,
      symbolRenderer: pointSymbolRenderer,
    );
  }

  /// Returns a structure containing domain, measure, and relative distance between
  /// a datum and a point within the chart.
  _Distances _getDatumDistance(AnimatedPoint<D> point, Offset chartPoint) {
    final datumPoint = point._currentPoint!.point!;
    final radius = point._currentPoint!.radius;
    final boundsLineRadius = point._currentPoint!.boundsLineRadius;

    // Compute distances from [chartPoint] to the primary point of the datum.
    final domainDistance = (chartPoint.dx - datumPoint.dx!).abs();

    final measureDistance = datumPoint.dy != null
        ? (chartPoint.dy - datumPoint.dy!).abs()
        : _maxInitialDistance;

    double relativeDistance = datumPoint.dy != null
        ? Point(chartPoint.dx, chartPoint.dy).distanceTo(Point(
            datumPoint.toPoint().dx,
            datumPoint.toPoint().dy,
          ))
        : _maxInitialDistance;

    bool insidePoint = false;

    if (datumPoint.xLower != null &&
        datumPoint.xUpper != null &&
        datumPoint.yLower != null &&
        datumPoint.yUpper != null) {
      // If we have data bounds, compute the relative distance between
      // [chartPoint] and the nearest point of the data bounds element. We will
      // use the smaller of this distance and the distance from the primary
      // point as the relativeDistance from this datum.
      final relativeDistanceBounds = distanceBetweenPointAndLineSegment(
          Vector2(chartPoint.dx, chartPoint.dy),
          Vector2(datumPoint.xLower!, datumPoint.yLower!),
          Vector2(datumPoint.xUpper!, datumPoint.yUpper!));

      insidePoint = (relativeDistance < radius) ||
          ( // This may be inaccurate if the symbol is drawn without end caps.
              relativeDistanceBounds < boundsLineRadius);

      // Keep the smaller relative distance after we have determined whether
      // [chartPoint] is located inside the datum.
      relativeDistance = min(relativeDistance, relativeDistanceBounds);
    } else {
      insidePoint = relativeDistance < radius;
    }

    return _Distances(
      domainDistance: domainDistance,
      measureDistance: measureDistance,
      relativeDistance: relativeDistance,
      insidePoint: insidePoint,
    );
  }

  @override
  DatumDetails<D> addPositionToDetailsForSeriesDatum(
      DatumDetails<D> details, SeriesDatum<D> seriesDatum) {
    final series = details.series!;

    final domainAxis =
        (chartState as CartesianChartState<D, CartesianChart<D>>).domainAxis;
    final measureAxis =
        (chartState as CartesianChartState<D, CartesianChart<D>>)
            .getMeasureAxis(axisId: series.getAttr(measureAxisIdKey));

    final point = getPoint(
      seriesDatum.datum,
      details.domain,
      details.domainLowerBound,
      details.domainUpperBound,
      series,
      domainAxis!,
      details.measure,
      details.measureLowerBound,
      details.measureUpperBound,
      details.measureOffset,
      measureAxis,
    );

    final symbolRendererFn = series.getAttr(pointSymbolRendererFnKey);

    // Get the ID of the [SymbolRenderer] for this point. An ID may be
    // specified on the datum, or on the series. If neither is specified,
    // fall back to the default.
    String? symbolRendererId;
    if (symbolRendererFn != null) {
      symbolRendererId = symbolRendererFn(details.index);
    }
    symbolRendererId ??= series.getAttr(pointSymbolRendererIdKey);
    symbolRendererId ??= defaultSymbolRendererId;

    // Now that we have the ID, get the configured [SymbolRenderer].
    SymbolRenderer? nearestSymbolRenderer;
    if (symbolRendererId == defaultSymbolRendererId) {
      nearestSymbolRenderer = symbolRenderer;
    } else {
      final id = symbolRendererId;
      if (!config.customSymbolRenderers!.containsKey(id)) {
        throw ArgumentError('Invalid custom symbol renderer id "$id"');
      }

      nearestSymbolRenderer = config.customSymbolRenderers![id];
    }

    return DatumDetails.from(
      details,
      chartPosition: NullablePoint(point.dx, point.dy),
      chartPositionLower: NullablePoint(point.xLower, point.yLower),
      chartPositionUpper: NullablePoint(point.xUpper, point.yUpper),
      symbolRenderer: nearestSymbolRenderer,
    );
  }
}

class DatumPoint<D> extends NullablePoint {
  const DatumPoint({
    this.datum,
    this.domain,
    this.series,
    required double? x,
    required this.xLower,
    required this.xUpper,
    required double? y,
    required this.yLower,
    required this.yUpper,
  }) : super(x, y);

  factory DatumPoint.from(
    DatumPoint<D> other, {
    double? x,
    double? xLower,
    double? xUpper,
    double? y,
    double? yLower,
    double? yUpper,
  }) {
    return DatumPoint<D>(
      datum: other.datum,
      domain: other.domain,
      series: other.series,
      x: x ?? other.dx,
      xLower: xLower ?? other.xLower,
      xUpper: xUpper ?? other.xUpper,
      y: y ?? other.dy,
      yLower: yLower ?? other.yLower,
      yUpper: yUpper ?? other.yUpper,
    );
  }

  final Object? datum;
  final D? domain;
  final ImmutableSeries<D>? series;

  // Coordinates for domain bounds.
  final double? xLower;
  final double? xUpper;

  // Coordinates for measure bounds.
  final double? yLower;
  final double? yUpper;
}

class PointRendererElement<D> {
  PointRendererElement({
    this.point,
    this.index,
    this.color,
    this.fillColor,
    this.measureAxisPosition,
    required this.radius,
    required this.boundsLineRadius,
    required this.strokeWidth,
    this.symbolRendererId,
  });

  PointRendererElement<D> clone() {
    return PointRendererElement<D>(
      point: point != null ? DatumPoint<D>.from(point!) : null,
      index: index,
      color: color,
      fillColor: fillColor,
      measureAxisPosition: measureAxisPosition,
      radius: radius,
      boundsLineRadius: boundsLineRadius,
      strokeWidth: strokeWidth,
      symbolRendererId: symbolRendererId,
    );
  }

  DatumPoint<D>? point;
  int? index;
  Color? color;
  Color? fillColor;
  double? measureAxisPosition;
  double radius;
  double boundsLineRadius;
  double strokeWidth;
  String? symbolRendererId;

  void updateAnimationPercent(
    PointRendererElement<D> previous,
    PointRendererElement<D> target,
    double animationPercent,
  ) {
    final targetPoint = target.point!;
    final previousPoint = previous.point!;

    final x = ((targetPoint.dx! - previousPoint.dx!) * animationPercent) +
        previousPoint.dx!;

    final xLower = targetPoint.xLower != null && previousPoint.xLower != null
        ? ((targetPoint.xLower! - previousPoint.xLower!) * animationPercent) +
            previousPoint.xLower!
        : null;

    final xUpper = targetPoint.xUpper != null && previousPoint.xUpper != null
        ? ((targetPoint.xUpper! - previousPoint.xUpper!) * animationPercent) +
            previousPoint.xUpper!
        : null;

    double? y;
    if (targetPoint.dy != null && previousPoint.dy != null) {
      y = ((targetPoint.dy! - previousPoint.dy!) * animationPercent) +
          previousPoint.dy!;
    } else if (targetPoint.dy != null) {
      y = targetPoint.dy;
    } else {
      y = null;
    }

    final yLower = targetPoint.yLower != null && previousPoint.yLower != null
        ? ((targetPoint.yLower! - previousPoint.yLower!) * animationPercent) +
            previousPoint.yLower!
        : null;

    final yUpper = targetPoint.yUpper != null && previousPoint.yUpper != null
        ? ((targetPoint.yUpper! - previousPoint.yUpper!) * animationPercent) +
            previousPoint.yUpper!
        : null;

    point = DatumPoint<D>.from(
      targetPoint,
      x: x,
      xLower: xLower,
      xUpper: xUpper,
      y: y,
      yLower: yLower,
      yUpper: yUpper,
    );

    color = getAnimatedColor(previous.color!, target.color!, animationPercent);

    fillColor = getAnimatedColor(
        previous.fillColor!, target.fillColor!, animationPercent);

    radius =
        (target.radius - previous.radius) * animationPercent + previous.radius;

    boundsLineRadius = ((target.boundsLineRadius - previous.boundsLineRadius) *
            animationPercent) +
        previous.boundsLineRadius;

    strokeWidth =
        ((target.strokeWidth - previous.strokeWidth) * animationPercent) +
            previous.strokeWidth;
  }
}

class AnimatedPoint<D> {
  AnimatedPoint({
    required this.key,
    required this.overlaySeries,
  });

  final String key;
  final bool overlaySeries;

  PointRendererElement<D>? _previousPoint;
  late PointRendererElement<D> _targetPoint;
  PointRendererElement<D>? _currentPoint;

  // Flag indicating whether this point is being animated out of the chart.
  bool animatingOut = false;

  /// Animates a point that was removed from the series out of the view.
  ///
  /// This should be called in place of "setNewTarget" for points that represent
  /// data that has been removed from the series.
  ///
  /// Animates the height of the point down to the measure axis position
  /// (position of 0).
  void animateOut() {
    final newTarget = _currentPoint!.clone();

    // Set the target measure value to the axis position.
    final targetPoint = newTarget.point!;
    final y = newTarget.measureAxisPosition!.roundToDouble();
    newTarget.point = DatumPoint<D>.from(
      targetPoint,
      x: targetPoint.dx,
      y: y,
      yLower: y,
      yUpper: y,
    );

    // Animate the radius and stroke width to 0 so that we don't get a lingering
    // point after animation is done.
    newTarget.radius = 0.0;
    newTarget.strokeWidth = 0.0;

    setNewTarget(newTarget);
    animatingOut = true;
  }

  void setNewTarget(PointRendererElement<D> newTarget) {
    animatingOut = false;
    _currentPoint ??= newTarget.clone();
    _previousPoint = _currentPoint!.clone();
    _targetPoint = newTarget;
  }

  PointRendererElement<D> getCurrentPoint(double animationPercent) {
    if (animationPercent == 1.0 || _previousPoint == null) {
      _currentPoint = _targetPoint;
      _previousPoint = _targetPoint;
      return _currentPoint!;
    }

    _currentPoint!.updateAnimationPercent(
        _previousPoint!, _targetPoint, animationPercent);

    return _currentPoint!;
  }
}

/// Distances between a datum and a point in the chart.
@immutable
class _Distances {
  const _Distances({
    required this.domainDistance,
    required this.measureDistance,
    required this.relativeDistance,
    this.insidePoint,
  });

  /// Distance between two points along the domain axis.
  final double domainDistance;

  /// Distance between two points along the measure axis.
  final double measureDistance;

  /// Cartesian distance between the two points.
  final double relativeDistance;

  /// Whether or not the point was located inside the datum.
  final bool? insidePoint;
}
