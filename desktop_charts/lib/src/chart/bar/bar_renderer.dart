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

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../../math.dart' show NullablePoint;
import '../base_chart.dart' show BaseChart;
import '../canvas_shapes.dart' show CanvasBarStack, CanvasRect;
import '../cartesian/axis/axis.dart' show ImmutableAxis, measureAxisIdKey;
import '../cartesian/cartesian_chart.dart';
import '../chart_canvas.dart' show ChartCanvas, FillPatternType;
import '../datum_details.dart' show DatumDetails;
import '../processed_series.dart' show ImmutableSeries;
import '../series_datum.dart' show SeriesDatum;
import 'bar_renderer_config.dart' show BarRendererConfig;
import 'bar_renderer_decorator.dart' show BarRendererDecorator;
import 'base_bar_renderer.dart'
    show
        BaseBarRenderer,
        allBarGroupWeightsKey,
        barGroupCountKey,
        barGroupIndexKey,
        barGroupWeightKey,
        previousBarGroupWeightKey;
import 'base_bar_renderer_element.dart'
    show BaseAnimatedBar, BaseBarRendererElement;

/// Renders series data as a series of bars.
class BarRenderer<D, S extends BaseChart<D>>
    extends BaseBarRenderer<D, BarRendererElement<D>, AnimatedBar<D>, S> {
  BarRenderer({
    BarRendererConfig config = const BarRendererConfig(),
    super.layoutPaintOrder = 0,
    String? rendererId,
    required super.chartState,
    required super.seriesList,
  }) : super(
          config: config,
          rendererId: rendererId ?? 'bar',
        );

  /// If we are grouped, use this spacing between the bars in a group.
  double get _barGroupInnerPadding => config.barGroupInnerPadding;

  /// The padding between bar stacks.
  ///
  /// The padding comes out of the bottom of the bar.
  double get _stackedBarPadding => config.stackedBarPadding;

  BarRendererDecorator<Object?>? get barRendererDecorator =>
      (config as BarRendererConfig).barRendererDecorator;

  @override
  void configureSeries() {
    assignMissingColors(
      getOrderedSeriesList(seriesList),
      emptyCategoryUsesSinglePalette: true,
    );
  }

  @override
  DatumDetails<D> addPositionToDetailsForSeriesDatum(
    DatumDetails<D> details,
    SeriesDatum<D> seriesDatum,
  ) {
    final series = details.series!;

    final domainAxis =
        (chartState as CartesianChartState<D, CartesianChart<D>>).domainAxis;
    final measureAxis =
        (chartState as CartesianChartState<D, CartesianChart<D>>)
            .getMeasureAxis(
      axisId: series.getAttr(measureAxisIdKey),
    );

    final barGroupIndex = series.getAttr(barGroupIndexKey)!;
    final previousBarGroupWeight = series.getAttr(previousBarGroupWeightKey);
    final barGroupWeight = series.getAttr(barGroupWeightKey);
    final allBarGroupWeights = series.getAttr(allBarGroupWeightsKey);
    final numBarGroups = series.getAttr(barGroupCountKey)!;

    final barBounds = _getBarBounds(
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
          (barBounds.left + (barBounds.width / 2)).toDouble(),
          barBounds.top.toDouble());
    } else {
      chartPosition = NullablePoint(
          isRtl ? barBounds.left.toDouble() : barBounds.right.toDouble(),
          (barBounds.top + (barBounds.height / 2)).toDouble());
    }

    return DatumDetails.from(
      details,
      chartPosition: chartPosition,
      bounds: barBounds,
    );
  }

  @override
  BarRendererElement<D> getBaseDetails(dynamic datum, int index) {
    return BarRendererElement<D>();
  }

  /// Generates an [AnimatedBar] to represent the previous and current state
  /// of one bar on the chart.
  @override
  AnimatedBar<D> makeAnimatedBar({
    List<int>? dashPattern,
    dynamic datum,
    Color? color,
    D? domainValue,
    num? measureValue,
    double? measureAxisPosition,
    Color? fillColor,
    FillPatternType? fillPattern,
    double? strokeWidth,
    double? previousBarGroupWeight,
    double? barGroupWeight,
    List<double>? allBarGroupWeights,
    bool? measureIsNull,
    bool? measureIsNegative,
    required String key,
    required ImmutableSeries<D> series,
    required BarRendererElement<D> details,
    required ImmutableAxis<D> domainAxis,
    required double domainWidth,
    required double measureOffsetValue,
    required ImmutableAxis<num> measureAxis,
    required int barGroupIndex,
    required int numBarGroups,
  }) {
    return AnimatedBar<D>(
      key: key,
      datum: datum,
      series: series,
      domainValue: domainValue,
    )..setNewTarget(
        makeBarRendererElement(
          color: color,
          dashPattern: dashPattern,
          details: details,
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

  /// Generates a [BarRendererElement] to represent the rendering data for one
  /// bar on the chart.
  @override
  BarRendererElement<D> makeBarRendererElement({
    Color? color,
    List<int>? dashPattern,
    D? domainValue,
    num? measureValue,
    double? measureAxisPosition,
    Color? fillColor,
    FillPatternType? fillPattern,
    double? strokeWidth,
    double? previousBarGroupWeight,
    double? barGroupWeight,
    List<double>? allBarGroupWeights,
    bool? measureIsNull,
    bool? measureIsNegative,
    required ImmutableAxis<D> domainAxis,
    required double domainWidth,
    required num measureOffsetValue,
    required ImmutableAxis<num> measureAxis,
    required int barGroupIndex,
    required int numBarGroups,
    required BarRendererElement<D> details,
  }) {
    return BarRendererElement<D>()
      ..color = color
      ..dashPattern = dashPattern
      ..fillColor = fillColor
      ..fillPattern = fillPattern
      ..measureAxisPosition = measureAxisPosition
      ..round = details.round
      ..strokeWidth = strokeWidth
      ..measureIsNull = measureIsNull
      ..measureIsNegative = measureIsNegative
      ..bounds = _getBarBounds(
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
    Iterable<BarRendererElement<D>> barElements,
  ) {
    final bars = <CanvasRect>[];

    final bounds = offset & size;
    final animationPercent = chartState.animationPosition.value;

    // When adjusting bars for stacked bar padding, do not modify the first bar
    // if rendering vertically and do not modify the last bar if rendering
    // horizontally.
    final unmodifiedBar =
        renderingVertically ? barElements.first : barElements.last;

    // Find the max bar width from each segment to calculate corner radius.
    double maxBarWidth = 0.0;

    bool measureIsNegative = false;

    for (final bar in barElements) {
      Rect? barBounds = bar.bounds;

      measureIsNegative = measureIsNegative || bar.measureIsNegative!;

      if (bar != unmodifiedBar) {
        barBounds = renderingVertically
            ? Rect.fromLTWH(
                bar.bounds!.left,
                max(
                    0,
                    bar.bounds!.top +
                        (measureIsNegative ? _stackedBarPadding : 0)),
                bar.bounds!.width,
                max(0, bar.bounds!.height - _stackedBarPadding),
              )
            : Rect.fromLTWH(
                max(
                    0,
                    bar.bounds!.left +
                        (measureIsNegative ? _stackedBarPadding : 0)),
                bar.bounds!.top,
                max(0, bar.bounds!.width - _stackedBarPadding),
                bar.bounds!.height,
              );
      }

      bars.add(
        CanvasRect(
          barBounds!,
          dashPattern: bar.dashPattern,
          fill: bar.fillColor,
          pattern: bar.fillPattern,
          stroke: bar.color,
          strokeWidth: bar.strokeWidth,
        ),
      );

      maxBarWidth = max(
        maxBarWidth,
        renderingVertically ? barBounds.width : barBounds.height,
      );
    }

    final barStack = CanvasBarStack(
      bars,
      stackedBarPadding: _stackedBarPadding,
    );

    // If bar stack's range width is:
    // * Within the component bounds, then draw the bar stack.
    // * Partially out of component bounds, then clip the stack where it is out
    // of bounds.
    // * Fully out of component bounds, do not draw.

    final componentBounds = bounds;

    final barOutsideBounds = renderingVertically
        ? barStack.fullStackRect.left < componentBounds.left ||
            barStack.fullStackRect.right > componentBounds.right
        : barStack.fullStackRect.top < componentBounds.top ||
            barStack.fullStackRect.bottom > componentBounds.bottom;

    // TODO: When we have initial viewport, add image test for
    // clipping.
    if (barOutsideBounds) {
      final clipBounds = _getBarStackBounds(barStack.fullStackRect, offset);

      // Do not draw the bar stack if it is completely outside of the component
      // bounds.
      if (clipBounds.width <= 0 || clipBounds.height <= 0) {
        return;
      }

      canvas.setChartClipBounds(clipBounds);
    }

    canvas.drawChartBarStack(
      barStack,
      drawAreaBounds: componentBounds,
      background: chartState.themeData.foreground, // TODO
    );

    if (barOutsideBounds) {
      canvas.resetChartClipBounds();
    }

    // Decorate the bar segments if there is a decorator.
    barRendererDecorator?.decorate(
      barElements,
      canvas,
      drawBounds: bounds,
      animationPercent: animationPercent,
      renderingVertically: renderingVertically,
      rtl: isRtl,
    );
  }

  /// Calculate the clipping region for a rectangle that represents the full bar
  /// stack.
  Rect _getBarStackBounds(
    Rect barStackRect,
    Offset offset,
  ) {
    double left;
    double right;
    double top;
    double bottom;

    final componentBounds = offset & size;

    if (renderingVertically) {
      // Only clip at the start and end so that the bar's width stays within
      // the viewport, but any bar decorations above the bar can still show.
      left = max(componentBounds.left, barStackRect.left);
      right = min(componentBounds.right, barStackRect.right);
      top = barStackRect.top;
      bottom = barStackRect.bottom;
    } else {
      // Only clip at the top and bottom so that the bar's height stays within
      // the viewport, but any bar decorations to the right of the bar can still
      // show.
      left = barStackRect.left;
      right = barStackRect.right;
      top = max(componentBounds.top, barStackRect.top);
      bottom = min(componentBounds.bottom, barStackRect.bottom);
    }

    final double width = right - left;
    final double height = bottom - top;

    return Rect.fromLTWH(left, top, width, height);
  }

  /// Generates a set of bounds that describe a bar.
  Rect _getBarBounds(
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
    // TODO: Investigate why this is negative for a DateTime domain
    // in RTL mode.
    domainWidth = domainWidth.abs();

    // If no weights were passed in, default to equal weight per bar.
    if (barGroupWeight == null) {
      barGroupWeight = 1 / numBarGroups;
      previousBarGroupWeight = barGroupIndex * barGroupWeight;
    }

    // Calculate how wide each bar should be within the group of bars. If we
    // only have one series, or are stacked, then barWidth should equal
    // domainWidth.
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
              .roundToDouble();
    }

    // Make sure that bars are at least one pixel wide, so that they will always
    // be visible on the chart. Ideally we should do something clever with the
    // size of the chart, and the density and periodicity of the data, but this
    // at least ensures that dense charts still have visible data.
    barWidth = max(1, barWidth);

    // Flip bar group index for calculating location on the domain axis if RTL.
    final adjustedBarGroupIndex =
        isRtl ? numBarGroups - barGroupIndex - 1 : barGroupIndex;

    // Calculate the start and end of the bar, taking into account accumulated
    // padding for grouped bars.
    final previousAverageWidth = adjustedBarGroupIndex > 0
        ? ((domainWidth - spacingLoss) *
                (previousBarGroupWeight! / adjustedBarGroupIndex))
            .roundToDouble()
        : 0;

    final domainStart = (domainAxis.getLocation(domainValue)! -
            (domainWidth / 2) +
            (previousAverageWidth + _barGroupInnerPadding) *
                adjustedBarGroupIndex)
        .roundToDouble();

    final domainEnd = domainStart + barWidth;

    measureValue ??= 0;

    // Calculate measure locations. Stacked bars should have their
    // offset calculated previously.
    double measureStart;
    double measureEnd;
    if (measureValue < 0) {
      measureEnd = measureAxis
          .getLocation(measureOffsetValue.toDouble())!
          .roundToDouble();
      measureStart = measureAxis
          .getLocation((measureValue + measureOffsetValue).toDouble())!
          .roundToDouble();
    } else {
      measureStart = measureAxis
          .getLocation(measureOffsetValue.toDouble())!
          .roundToDouble();
      measureEnd = measureAxis
          .getLocation((measureValue + measureOffsetValue).toDouble())!
          .roundToDouble();
    }

    Rect bounds;
    if (renderingVertically) {
      // Rect clamps to zero width/height
      bounds = Rect.fromLTWH(
        domainStart,
        measureEnd,
        domainEnd - domainStart,
        measureStart - measureEnd,
      );
    } else {
      // Rect clamps to zero width/height
      bounds = Rect.fromLTWH(
        min(measureStart, measureEnd),
        domainStart,
        (measureEnd - measureStart).abs(),
        domainEnd - domainStart,
      );
    }

    return bounds;
  }

  @override
  Rect? getBoundsForBar(BarRendererElement<D> bar) => bar.bounds;
}

abstract class ImmutableBarRendererElement<D> {
  ImmutableSeries<D>? get series;

  dynamic get datum;

  int? get index;

  Rect? get bounds;
}

class BarRendererElement<D> extends BaseBarRendererElement
    implements ImmutableBarRendererElement<D> {
  BarRendererElement();

  BarRendererElement.clone(BarRendererElement<D> other) : super.clone(other) {
    series = other.series;
    bounds = other.bounds;
    round = other.round;
    index = other.index;
    _datum = other._datum;
  }

  @override
  ImmutableSeries<D>? series;

  @override
  Rect? bounds;

  int? round;

  @override
  int? index;

  dynamic _datum;

  @override
  dynamic get datum => _datum;

  set datum(dynamic datum) {
    _datum = datum;
    index = series?.data.indexOf(datum);
  }

  @override
  void updateAnimationPercent(BaseBarRendererElement previous,
      BaseBarRendererElement target, double animationPercent) {
    final localPrevious = previous as BarRendererElement<D>;
    final localTarget = target as BarRendererElement<D>;

    final previousBounds = localPrevious.bounds!;
    final targetBounds = localTarget.bounds!;

    final top = ((targetBounds.top - previousBounds.top) * animationPercent) +
        previousBounds.top;
    final right =
        ((targetBounds.right - previousBounds.right) * animationPercent) +
            previousBounds.right;
    final bottom =
        ((targetBounds.bottom - previousBounds.bottom) * animationPercent) +
            previousBounds.bottom;
    final left =
        ((targetBounds.left - previousBounds.left) * animationPercent) +
            previousBounds.left;

    bounds = Rect.fromLTWH(
      left.roundToDouble(),
      top.roundToDouble(),
      (right - left).roundToDouble(),
      (bottom - top).roundToDouble(),
    );

    round = localTarget.round;

    super.updateAnimationPercent(previous, target, animationPercent);
  }
}

class AnimatedBar<D> extends BaseAnimatedBar<D, BarRendererElement<D>> {
  AnimatedBar({
    required super.key,
    required super.datum,
    required super.series,
    required super.domainValue,
  });

  @override
  void animateElementToMeasureAxisPosition(BaseBarRendererElement target) {
    final localTarget = target as BarRendererElement<D>;

    // TODO: Animate out bars in the middle of a stack.
    localTarget.bounds = Rect.fromLTWH(
      localTarget.bounds!.left +
          (localTarget.bounds!.width / 2).roundToDouble(),
      localTarget.measureAxisPosition!.roundToDouble(),
      0,
      0,
    );
  }

  @override
  BarRendererElement<D> getCurrentBar(double animationPercent) {
    final bar = super.getCurrentBar(animationPercent);

    // Update with series and datum information to pass to bar decorator.
    bar.series = series;
    bar.datum = datum;

    return bar;
  }

  @override
  BarRendererElement<D> clone(BarRendererElement<D> bar) =>
      BarRendererElement<D>.clone(bar);
}
