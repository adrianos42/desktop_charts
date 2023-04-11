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

import 'dart:math' show max, min;

import 'package:flutter/widgets.dart';

import '../../math.dart' show NullablePoint;
import '../base_chart.dart' show BaseChart;
import '../cartesian/axis/axis.dart' show ImmutableAxis, measureAxisIdKey;
import '../cartesian/cartesian_chart.dart'
    show CartesianChart, CartesianChartState;
import '../chart_canvas.dart' show ChartCanvas, FillPatternType;
import '../datum_details.dart' show DatumDetails;
import '../processed_series.dart' show ImmutableSeries;
import '../series_datum.dart' show SeriesDatum;
import 'bar_target_line_renderer_config.dart' show BarTargetLineRendererConfig;
import 'base_bar_renderer.dart'
    show
        BaseBarRenderer,
        allBarGroupWeightsKey,
        barGroupWeightKey,
        barGroupCountKey,
        barGroupIndexKey,
        previousBarGroupWeightKey;
import 'base_bar_renderer_element.dart'
    show BaseAnimatedBar, BaseBarRendererElement;

/// Renders series data as a series of bar target lines.
///
/// Usually paired with a BarRenderer to display target metrics alongside actual
/// metrics.
class BarTargetLineRenderer<D, S extends BaseChart<D>> extends BaseBarRenderer<
    D, BarTargetLineRendererElement, AnimatedBarTargetLine<D>, S> {
  BarTargetLineRenderer({
    BarTargetLineRendererConfig<D>? config,
    String? rendererId,
    required super.chartState,
    required super.seriesList,
  })  : _barGroupInnerPadding = config?.barGroupInnerPadding ?? 0.0,
        super(
          config: config ?? BarTargetLineRendererConfig<D>(),
          rendererId: rendererId ?? 'barTargetLine',
        );

  /// If we are grouped, use this spacing between the bars in a group.
  final double _barGroupInnerPadding;

  /// Standard color for all bar target lines.
  Color get _color => chartState.themeData.foreground;

  @override
  void configureSeries() {
    for (final series in seriesList) {
      series.colorFn ??= (_) => _color;
      series.fillColorFn ??= (_) => _color;

      // Fill in missing seriesColor values with the color of the first datum in
      // the series. Note that [Series.colorFn] should always return a color.
      if (series.seriesColor == null) {
        try {
          series.seriesColor = series.colorFn!(0);
        } catch (exception) {
          series.seriesColor = _color;
        }
      }
    }
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

    final barGroupIndex = series.getAttr(barGroupIndexKey)!;
    final previousBarGroupWeight = series.getAttr(previousBarGroupWeightKey);
    final barGroupWeight = series.getAttr(barGroupWeightKey);
    final allBarGroupWeights = series.getAttr(allBarGroupWeightsKey);
    final numBarGroups = series.getAttr(barGroupCountKey)!;

    final points = _getTargetLinePoints(
      details.domain,
      domainAxis!,
      domainAxis.rangeBand.roundToDouble(),
      config.maxBarWidth,
      details.measure,
      details.measureOffset!,
      measureAxis,
      barGroupIndex,
      previousBarGroupWeight,
      barGroupWeight,
      allBarGroupWeights,
      numBarGroups,
    );

    NullablePoint chartPosition;

    if (renderingVertically) {
      chartPosition = NullablePoint(
        (points[0].dx + (points[1].dx - points[0].dx) / 2).toDouble(),
        points[0].dy.toDouble(),
      );
    } else {
      chartPosition = NullablePoint(
        points[0].dx.toDouble(),
        (points[0].dy + (points[1].dy - points[0].dy) / 2).toDouble(),
      );
    }

    return DatumDetails.from(details, chartPosition: chartPosition);
  }

  @override
  BarTargetLineRendererElement getBaseDetails(dynamic datum, int index) {
    return BarTargetLineRendererElement();
  }

  /// Generates an [AnimatedBarTargetLine] to represent the previous and
  /// current state of one bar target line on the chart.
  @override
  AnimatedBarTargetLine<D> makeAnimatedBar({
    required String key,
    required ImmutableSeries<D> series,
    dynamic datum,
    Color? color,
    List<int>? dashPattern,
    required BarTargetLineRendererElement details,
    D? domainValue,
    required ImmutableAxis<D> domainAxis,
    required double domainWidth,
    double? measureValue,
    required double measureOffsetValue,
    required ImmutableAxis<num> measureAxis,
    double? measureAxisPosition,
    Color? fillColor,
    FillPatternType? fillPattern,
    required int barGroupIndex,
    double? previousBarGroupWeight,
    double? barGroupWeight,
    List<double>? allBarGroupWeights,
    required int numBarGroups,
    double? strokeWidth,
    bool? measureIsNull,
    bool? measureIsNegative,
  }) {
    return AnimatedBarTargetLine(
        key: key, datum: datum, series: series, domainValue: domainValue)
      ..setNewTarget(
        makeBarRendererElement(
          color: color,
          details: details,
          dashPattern: dashPattern,
          domainValue: domainValue,
          domainAxis: domainAxis,
          domainWidth: domainWidth,
          measureValue: measureValue,
          measureOffsetValue: measureOffsetValue,
          measureAxisPosition: measureAxisPosition,
          measureAxis: measureAxis,
          fillColor: fillColor,
          fillPattern: fillPattern,
          strokeWidth: strokeWidth,
          barGroupIndex: barGroupIndex,
          previousBarGroupWeight: previousBarGroupWeight,
          barGroupWeight: barGroupWeight,
          allBarGroupWeights: allBarGroupWeights,
          numBarGroups: numBarGroups,
          measureIsNull: measureIsNull,
          measureIsNegative: measureIsNegative,
        ),
      );
  }

  /// Generates a [BarTargetLineRendererElement] to represent the rendering
  /// data for one bar target line on the chart.
  @override
  BarTargetLineRendererElement makeBarRendererElement({
    Color? color,
    List<int>? dashPattern,
    required BarTargetLineRendererElement details,
    D? domainValue,
    required ImmutableAxis<D> domainAxis,
    required double domainWidth,
    num? measureValue,
    required num measureOffsetValue,
    required ImmutableAxis<num> measureAxis,
    double? measureAxisPosition,
    Color? fillColor,
    FillPatternType? fillPattern,
    double? strokeWidth,
    required int barGroupIndex,
    double? previousBarGroupWeight,
    double? barGroupWeight,
    List<double>? allBarGroupWeights,
    required int numBarGroups,
    bool? measureIsNull,
    bool? measureIsNegative,
  }) {
    return BarTargetLineRendererElement()
      ..color = color
      ..dashPattern = dashPattern
      ..fillColor = fillColor
      ..fillPattern = fillPattern
      ..measureAxisPosition = measureAxisPosition
      ..strokeWidth = strokeWidth
      ..measureIsNull = measureIsNull
      ..measureIsNegative = measureIsNegative
      ..points = _getTargetLinePoints(
        domainValue,
        domainAxis,
        domainWidth,
        config.maxBarWidth,
        measureValue,
        measureOffsetValue,
        measureAxis,
        barGroupIndex,
        previousBarGroupWeight,
        barGroupWeight,
        allBarGroupWeights,
        numBarGroups,
      );
  }

  @override
  void paintBar(
    Canvas canvas,
    Offset offset,
    Iterable<BarTargetLineRendererElement> barElements,
  ) {
    final bounds = offset & size;

    for (final bar in barElements) {
      // TODO: Combine common line attributes into
      // lineStyle or similar.
      canvas.drawChartLine(
        clipBounds: bounds,
        points: bar.points,
        stroke: bar.color!,
        strokeWidth: bar.strokeWidth,
        dashPattern: bar.dashPattern,
      );
    }
  }

  /// Generates a set of points that describe a bar target line.
  List<Offset> _getTargetLinePoints(
    D? domainValue,
    ImmutableAxis<D> domainAxis,
    double domainWidth,
    double? maxBarWidth,
    num? measureValue,
    num measureOffsetValue,
    ImmutableAxis<num> measureAxis,
    int barGroupIndex,
    double? previousBarGroupWeight,
    double? barGroupWeight,
    List<double>? allBarGroupWeights,
    int numBarGroups,
  ) {
    // If no weights were passed in, default to equal weight per bar.
    if (barGroupWeight == null) {
      barGroupWeight = 1 / numBarGroups;
      previousBarGroupWeight = barGroupIndex * barGroupWeight;
    }

    final localConfig = config as BarTargetLineRendererConfig<D>;

    // Calculate how wide each bar target line should be within the group of
    // bar target lines. If we only have one series, or are stacked, then
    // barWidth should equal domainWidth.
    final spacingLoss = _barGroupInnerPadding * (numBarGroups - 1);
    double desiredWidth =
        ((domainWidth - spacingLoss) / numBarGroups).roundToDouble();

    if (maxBarWidth != null) {
      desiredWidth = min(desiredWidth, maxBarWidth);
      domainWidth = desiredWidth * numBarGroups + spacingLoss;
    }

    // If the series was configured with a weight pattern, treat the "max" bar
    // width as the average max width. The overall total width will still equal
    // max times number of bars, but this results in a nicer final picture.
    double barWidth = desiredWidth;
    if (allBarGroupWeights != null) {
      barWidth =
          (desiredWidth * numBarGroups * allBarGroupWeights[barGroupIndex])
              .floorToDouble();
    }
    // Get the overdraw boundaries.
    final overDrawOuter = localConfig.overDrawOuter;
    final overDraw = localConfig.overDraw;

    final overDrawStart = (barGroupIndex == 0) && overDrawOuter != null
        ? overDrawOuter
        : overDraw;

    final overDrawEnd =
        (barGroupIndex == numBarGroups - 1) && overDrawOuter != null
            ? overDrawOuter
            : overDraw;

    // Flip bar group index for calculating location on the domain axis if RTL.
    final adjustedBarGroupIndex =
        isRtl ? numBarGroups - barGroupIndex - 1 : barGroupIndex;

    // Calculate the start and end of the bar target line, taking into account
    // accumulated padding for grouped bars.
    final double previousAverageWidth = adjustedBarGroupIndex > 0
        ? ((domainWidth - spacingLoss) *
                (previousBarGroupWeight! / adjustedBarGroupIndex))
            .roundToDouble()
        : 0.0;

    final domainStart = (domainAxis.getLocation(domainValue)! -
            (domainWidth / 2) +
            (previousAverageWidth + _barGroupInnerPadding) *
                adjustedBarGroupIndex -
            overDrawStart)
        .roundToDouble();

    final domainEnd = domainStart + barWidth + overDrawStart + overDrawEnd;

    measureValue = measureValue ?? 0;

    // Calculate measure locations. Stacked bars should have their
    // offset calculated previously.
    final measureStart = measureAxis
        .getLocation((measureValue + measureOffsetValue).toDouble())!
        .roundToDouble();

    List<Offset> points;
    if (renderingVertically) {
      points = [
        Offset(domainStart, measureStart),
        Offset(domainEnd, measureStart)
      ];
    } else {
      points = [
        Offset(measureStart, domainStart),
        Offset(measureStart, domainEnd)
      ];
    }
    return points;
  }

  @override
  Rect getBoundsForBar(BarTargetLineRendererElement bar) {
    final points = bar.points;
    assert(points.isNotEmpty);
    double top = points.first.dy;
    double bottom = points.first.dy;
    double left = points.first.dx;
    double right = points.first.dx;
    for (final point in points.skip(1)) {
      top = min(top, point.dy);
      left = min(left, point.dx);
      bottom = max(bottom, point.dy);
      right = max(right, point.dx);
    }
    return Rect.fromLTRB(left, top, right, bottom);
  }
}

class BarTargetLineRendererElement extends BaseBarRendererElement {
  BarTargetLineRendererElement();

  BarTargetLineRendererElement.clone(BarTargetLineRendererElement other)
      : points = List.of(other.points),
        super.clone(other);

  late List<Offset> points;

  @override
  void updateAnimationPercent(BaseBarRendererElement previous,
      BaseBarRendererElement target, double animationPercent) {
    final localPrevious = previous as BarTargetLineRendererElement;
    final localTarget = target as BarTargetLineRendererElement;

    final previousPoints = localPrevious.points;
    final targetPoints = localTarget.points;

    late Offset lastPoint;

    int pointIndex;
    for (pointIndex = 0; pointIndex < targetPoints.length; pointIndex += 1) {
      final targetPoint = targetPoints[pointIndex];

      // If we have more points than the previous line, animate in the point
      // by starting its measure position at the last known official point.
      Offset previousPoint;
      if (previousPoints.length - 1 >= pointIndex) {
        previousPoint = previousPoints[pointIndex];
        lastPoint = previousPoint;
      } else {
        previousPoint = Offset(targetPoint.dx, lastPoint.dy);
      }

      final x = ((targetPoint.dx - previousPoint.dx) * animationPercent) +
          previousPoint.dx;

      final y = ((targetPoint.dy - previousPoint.dy) * animationPercent) +
          previousPoint.dy;

      if (points.length - 1 >= pointIndex) {
        points[pointIndex] = Offset(x.roundToDouble(), y.roundToDouble());
      } else {
        points.add(Offset(x.roundToDouble(), y.roundToDouble()));
      }
    }

    // Removing extra points that don't exist anymore.
    if (pointIndex < points.length) {
      points.removeRange(pointIndex, points.length);
    }

    strokeWidth = ((localTarget.strokeWidth! - localPrevious.strokeWidth!) *
            animationPercent) +
        localPrevious.strokeWidth!;

    super.updateAnimationPercent(previous, target, animationPercent);
  }
}

class AnimatedBarTargetLine<D>
    extends BaseAnimatedBar<D, BarTargetLineRendererElement> {
  AnimatedBarTargetLine({
    required String key,
    required dynamic datum,
    required ImmutableSeries<D> series,
    required D? domainValue,
  }) : super(
          key: key,
          datum: datum,
          series: series,
          domainValue: domainValue,
        );

  @override
  void animateElementToMeasureAxisPosition(BaseBarRendererElement target) {
    final localTarget = target as BarTargetLineRendererElement;

    final newPoints = <Offset>[];
    for (int index = 0; index < localTarget.points.length; index += 1) {
      final targetPoint = localTarget.points[index];

      newPoints.add(
        Offset(
          targetPoint.dx,
          localTarget.measureAxisPosition!.roundToDouble(),
        ),
      );
    }
    localTarget.points = newPoints;
  }

  @override
  BarTargetLineRendererElement clone(BarTargetLineRendererElement bar) =>
      BarTargetLineRendererElement.clone(bar);
}
