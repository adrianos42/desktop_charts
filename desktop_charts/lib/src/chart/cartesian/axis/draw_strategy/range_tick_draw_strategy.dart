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

import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import '../../../../theme.dart';
import '../../../chart_canvas.dart' show ChartCanvas;
import '../../../chart_context.dart' show ChartContext;
import '../range_axis_tick.dart' show RangeAxisTicks;
import '../spec/axis_spec.dart' show TickLabelAnchor, TickLabelJustification;
import '../tick.dart' show Tick;
import 'base_tick_draw_strategy.dart' show BaseTickDrawStrategy;
import 'small_tick_draw_strategy.dart'
    show SmallTickRendererSpec, SmallTickDrawStrategy;
import 'tick_draw_strategy.dart' show TickDrawStrategy;

/// Displays individual ticks and range ticks and with a shade for ranges.
/// Sample ticks looks like:
/// -------------------------------------------------------------------
///  |   |                       |            |                    |
///  |   (Individual tick)       |            (Individual tick)    |
///  |///////Range Label/////////|///////////Range Label///////////|
@immutable
class RangeTickRendererSpec<D> extends SmallTickRendererSpec<D> {
  RangeTickRendererSpec({
    TextStyle? labelStyle,
    LineStyle? lineStyle,
    TickLabelAnchor? labelAnchor,
    TickLabelJustification? labelJustification,
    double? labelOffsetFromAxis,
    double? labelCollisionOffsetFromAxis,
    double? labelOffsetFromTick,
    double? labelCollisionOffsetFromTick,
    this.rangeShadeHeight,
    this.rangeShadeOffsetFromAxis,
    this.rangeShadeStyle,
    this.rangeTickLength,
    this.rangeTickOffset,
    this.rangeLabelStyle,
    int? tickLength,
    double? minimumPaddingBetweenLabels,
    double? labelRotation,
    double? labelCollisionRotation,
  })  : defaultLabelStyle = TextStyle(
          fontSize: 9.0,
          color: const ChartsThemeData.fallbackw().tickColor, // TODO
        ),
        super(
          axisLineStyle: lineStyle,
          labelStyle: labelStyle,
          labelAnchor: labelAnchor,
          labelJustification: labelJustification,
          labelOffsetFromAxis:
              labelOffsetFromAxis ?? defaultLabelOffsetFromAxis,
          labelCollisionOffsetFromAxis: labelCollisionOffsetFromAxis,
          labelOffsetFromTick:
              labelOffsetFromTick ?? defaultLabelOffsetFromTick,
          labelCollisionOffsetFromTick: labelCollisionOffsetFromTick,
          tickLength: tickLength,
          minimumPaddingBetweenLabels: minimumPaddingBetweenLabels,
          labelRotation: labelRotation,
          labelCollisionRotation: labelCollisionRotation,
        );

  // Specifies range shade's style.
  final LineStyle? rangeShadeStyle;
  // Specifies range label text style.
  final TextStyle? rangeLabelStyle;
  // Specifies range tick's length.
  final int? rangeTickLength;
  // Specifies range shade's height.
  final double? rangeShadeHeight;
  // Specifies the starting offset of range shade from axis in pixels.
  final double? rangeShadeOffsetFromAxis;
  // A range tick offset from the original location. The start point offset is
  // toward the origin and end point offset is toward the end of axis.
  final double? rangeTickOffset;

  final TextStyle? defaultLabelStyle;

  static const double defaultLabelOffsetFromAxis = 2.0;
  static const double defaultLabelOffsetFromTick = -4.0;

  @override
  TickDrawStrategy<D> createDrawStrategy(ChartContext context) =>
      RangeTickDrawStrategy<D>(
        context,
        tickLength: tickLength,
        rangeLabelTextStyle: rangeLabelStyle,
        rangeTickLength: rangeTickLength,
        rangeShadeHeight: rangeShadeHeight,
        rangeShadeOffsetFromAxis: rangeShadeOffsetFromAxis,
        rangeTickOffset: rangeTickOffset,
        lineStyleSpec: lineStyle,
        labelStyle: labelStyle ?? defaultLabelStyle,
        axisLineStyle: axisLineStyle,
        rangeShadeStyleSpec: rangeShadeStyle,
        labelAnchor: labelAnchor,
        labelJustification: labelJustification,
        labelOffsetFromAxis: labelOffsetFromAxis,
        labelCollisionOffsetFromAxis: labelCollisionOffsetFromAxis,
        labelOffsetFromTick: labelOffsetFromTick,
        labelCollisionOffsetFromTick: labelCollisionOffsetFromTick,
        minimumPaddingBetweenLabels: minimumPaddingBetweenLabels,
        labelRotation: labelRotation,
        labelCollisionRotation: labelCollisionRotation,
      );

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is RangeTickRendererSpec && super == other);
  }
}

/// Draws small tick lines for each tick. Extends [BaseTickDrawStrategy].
class RangeTickDrawStrategy<D> extends SmallTickDrawStrategy<D> {
  RangeTickDrawStrategy(
    ChartContext chartContext, {
    int? rangeTickLength,
    double? rangeShadeHeight,
    double? rangeShadeOffsetFromAxis,
    double? rangeTickOffset,
    TextStyle? rangeLabelTextStyle,
    LineStyle? rangeShadeStyleSpec,
    LineStyle? lineStyleSpec,
    super.labelStyle,
    super.axisLineStyle,
    TickLabelAnchor? labelAnchor,
    super.labelJustification,
    super.labelOffsetFromAxis,
    super.labelCollisionOffsetFromAxis,
    super.labelOffsetFromTick,
    super.labelCollisionOffsetFromTick,
    super.minimumPaddingBetweenLabels,
    super.labelRotation,
    super.labelCollisionRotation,
    super.tickLength,
  })  : _rangeLabelTextStyle = rangeLabelTextStyle,
        _rangeShadeStyleSpec = rangeShadeStyleSpec,
        super(
          chartContext,
          lineStyle: lineStyleSpec,
          labelAnchor: labelAnchor ?? TickLabelAnchor.after,
        ) {
    rangeTickOffset = rangeTickOffset ?? rangeTickOffset;
    rangeTickLength = rangeTickLength ?? rangeTickLength;
    rangeShadeHeight = rangeShadeHeight ?? rangeShadeHeight;
    rangeShadeOffsetFromAxis =
        rangeShadeOffsetFromAxis ?? rangeShadeOffsetFromAxis;
  }

  int rangeTickLength = 24;
  double rangeShadeHeight = 12.0;
  double rangeShadeOffsetFromAxis = 12.0;
  double rangeTickOffset = 12.0;

  LineStyle get rangeShadeStyle =>
      chartContext!.themeData.createTickLineStyle(_rangeShadeStyleSpec);

  TextStyle get rangeLabelStyle =>
      _rangeLabelTextStyle ??
      labelStyle.copyWith(
        color: labelStyle.color ?? chartContext!.themeData.tickColor,
        fontSize: rangeShadeHeight - 1.0,
      );

  final TextStyle? _rangeLabelTextStyle;
  TextStyle get rangeLabelTextStyle =>
      _rangeLabelTextStyle ??
      labelStyle.copyWith(
        fontSize: rangeShadeHeight - 1.0,
        color: chartContext!.themeData.tickColor,
      );

  final LineStyle? _rangeShadeStyleSpec;
  // TODO Palette.gray.shade300
  LineStyle get rangeShadeStyleSpec =>
      _rangeShadeStyleSpec ??
      LineStyle(
        color: chartContext!.themeData.noDataColor,
      );

  @override
  void draw(
    Canvas canvas,
    Tick<D> tick, {
    required AxisDirection orientation,
    required Rect axisBounds,
    required Rect drawAreaBounds,
    required bool isFirst,
    required bool isLast,
    bool collision = false,
  }) {
    if (tick is RangeAxisTicks<D>) {
      drawRangeShadeAndRangeLabel(tick, canvas, orientation, axisBounds,
          drawAreaBounds, isFirst, isLast);
    } else {
      super.draw(canvas, tick,
          orientation: orientation,
          axisBounds: axisBounds,
          drawAreaBounds: drawAreaBounds,
          isFirst: isFirst,
          isLast: isLast,
          collision: collision);
    }
  }

  @override
  Size measureVerticallyDrawnTicks(
    List<Tick<D>> ticks,
    double maxWidth,
    double maxHeight, {
    bool collision = false,
  }) {
    // TODO: Add spacing to account for the distance between the
    // text and the axis baseline (even if it isn't drawn).

    final maxHorizontalSliceWidth = ticks.fold(0.0, (double prevMax, tick) {
      assert(tick.textElement != null);
      final labelElements = splitLabel(tick.textElement!);
      if (tick is RangeAxisTicks) {
        // Find the maximum within prevMax, label total height and
        // labelOffsetFromAxis + rangeShadeHeight.
        return max(
            max(
                prevMax,
                calculateWidthForRotatedLabel(
                      labelRotation(collision: collision),
                      getLabelHeight(labelElements),
                      getLabelWidth(labelElements),
                    ) +
                    labelOffsetFromAxis(collision: collision)),
            labelOffsetFromAxis(collision: collision) + rangeShadeHeight);
      } else {
        return max(
          prevMax,
          calculateWidthForRotatedLabel(
                labelRotation(collision: collision),
                getLabelHeight(labelElements),
                getLabelWidth(labelElements),
              ) +
              labelOffsetFromAxis(collision: collision),
        );
      }
    }).roundToDouble();

    return Size(maxHorizontalSliceWidth, maxHeight);
  }

  @override
  Size measureHorizontallyDrawnTicks(
    List<Tick<D>> ticks,
    double maxWidth,
    double maxHeight, {
    bool collision = false,
  }) {
    final maxVerticalSliceWidth = ticks.fold(0.0, (double prevMax, tick) {
      final labelElements = splitLabel(tick.textElement!);

      if (tick is RangeAxisTicks) {
        // Find the maximum within prevMax, label total height and
        // labelOffsetFromAxis + rangeShadeHeight.
        return max(
            max(
              prevMax,
              calculateHeightForRotatedLabel(
                    labelRotation(collision: collision),
                    getLabelHeight(labelElements),
                    getLabelWidth(labelElements),
                  ) +
                  rangeShadeOffsetFromAxis,
            ),
            rangeShadeOffsetFromAxis + rangeShadeHeight);
      } else {
        return max(
                prevMax,
                calculateHeightForRotatedLabel(
                  labelRotation(collision: collision),
                  getLabelHeight(labelElements),
                  getLabelWidth(labelElements),
                )) +
            labelOffsetFromAxis(collision: collision);
      }
    }).roundToDouble();

    return Size(maxWidth, maxVerticalSliceWidth);
  }

  void drawRangeShadeAndRangeLabel(
    RangeAxisTicks<D> tick,
    Canvas canvas,
    AxisDirection orientation,
    Rect axisBounds,
    Rect drawAreaBounds,
    bool isFirst,
    bool isLast,
  ) {
    // Create virtual range start and end ticks for position calculation.
    final rangeStartTick = Tick<D>(
      value: tick.rangeStartValue,
      location: tick.rangeStartLocation - rangeTickOffset,
      textElement: null,
    );
    final rangeEndTick = Tick<D>(
      value: tick.rangeEndValue,
      location: isLast
          ? tick.rangeEndLocation + rangeTickOffset
          : tick.rangeEndLocation - rangeTickOffset,
      textElement: null,
    );
    // Calculate range start positions.
    final rangeStartPositions = calculateTickPositions(rangeStartTick,
        orientation, axisBounds, drawAreaBounds, rangeTickLength);
    final rangeStartTickStart = rangeStartPositions.first;
    final rangeStartTickEnd = rangeStartPositions.last;

    // Calculate range end positions.
    final rangeEndPositions = calculateTickPositions(
        rangeEndTick, orientation, axisBounds, drawAreaBounds, rangeTickLength);
    final rangeEndTickStart = rangeEndPositions.first;
    final rangeEndTickEnd = rangeEndPositions.last;

    // Draw range shade.
    Rect rangeShade;
    switch (orientation) {
      case AxisDirection.up:
      case AxisDirection.down:
        rangeShade = Rect.fromLTWH(
          rangeStartTickStart.dx,
          rangeStartTickStart.dy + rangeShadeOffsetFromAxis,
          rangeEndTickStart.dx - rangeStartTickStart.dx,
          rangeShadeHeight,
        );
        break;
      case AxisDirection.right:
        rangeShade = Rect.fromLTWH(
          rangeEndTickStart.dx + rangeShadeOffsetFromAxis,
          rangeEndTickStart.dy,
          rangeShadeHeight,
          rangeEndTickStart.dy - rangeEndTickStart.dy,
        );
        break;
      case AxisDirection.left:
        rangeShade = Rect.fromLTWH(
          rangeEndTickStart.dx - rangeShadeOffsetFromAxis - rangeShadeHeight,
          rangeEndTickStart.dy,
          rangeShadeHeight,
          rangeEndTickStart.dy - rangeEndTickStart.dy,
        );
        break;
    }
    canvas.drawChartRect(
      rangeShade,
      fill: rangeShadeStyle.color!,
      stroke: rangeShadeStyle.color,
      strokeWidth: rangeShadeStyle.strokeWidth,
    );

    // Draw the start and end boundaries of the range.
    canvas.drawChartLine(
      points: [rangeStartTickStart, rangeStartTickEnd],
      dashPattern: lineStyle.dashPattern,
      stroke: lineStyle.color!,
      strokeWidth: lineStyle.strokeWidth,
    );
    canvas.drawChartLine(
      points: [rangeEndTickStart, rangeEndTickEnd],
      dashPattern: lineStyle.dashPattern,
      stroke: lineStyle.color!,
      strokeWidth: lineStyle.strokeWidth,
    );

    // Prepare range label.
    final rangeLabelTextElement = tick.textElement!
      ..textStyle = rangeLabelStyle;

    final labelElements = splitLabel(rangeLabelTextElement);
    final labelWidth = getLabelWidth(labelElements);

    // Draw range label on top of range shade.
    double multiLineLabelOffset = 0.0;
    for (final line in labelElements) {
      double x = 0.0;
      double y = 0.0;

      if (orientation == AxisDirection.down ||
          orientation == AxisDirection.up) {
        y = rangeStartTickStart.dy.toInt() + rangeShadeOffsetFromAxis - 1;

        x = (rangeStartTickStart.dx +
                (rangeEndTickStart.dx - rangeStartTickStart.dx - labelWidth) /
                    2.0)
            .roundToDouble();
      }
      // TODO: add support for orientation left and right.
      canvas.drawChartText(line, x, y + multiLineLabelOffset);
      multiLineLabelOffset += BaseTickDrawStrategy.multiLineLabelPadding +
          line.measurement.verticalSliceWidth.roundToDouble();
    }
  }
}
