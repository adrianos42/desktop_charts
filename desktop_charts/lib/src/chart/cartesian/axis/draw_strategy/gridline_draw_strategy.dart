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

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import '../../../../theme.dart';
import '../../../chart_canvas.dart' show ChartCanvas;
import '../../../chart_context.dart' show ChartContext;
import '../spec/axis_spec.dart' show TickLabelAnchor;
import '../tick.dart' show Tick;
import 'base_tick_draw_strategy.dart' show BaseTickDrawStrategy;
import 'small_tick_draw_strategy.dart' show SmallTickRendererSpec;
import 'tick_draw_strategy.dart' show TickDrawStrategy;

@immutable
class GridlineRendererSpec<D> extends SmallTickRendererSpec<D> {
  const GridlineRendererSpec({
    int? tickLength,
    super.labelStyle,
    super.lineStyle,
    super.labelAnchor,
    super.labelJustification,
    super.labelOffsetFromAxis,
    super.labelCollisionOffsetFromAxis,
    super.labelOffsetFromTick,
    super.labelCollisionOffsetFromTick,
    super.minimumPaddingBetweenLabels,
    super.labelRotation,
    super.labelCollisionRotation,
    super.axisLineStyle,
  }) : super(tickLength: tickLength ?? 0);

  @override
  TickDrawStrategy<D> createDrawStrategy(ChartContext context) =>
      GridlineTickDrawStrategy<D>(
        context,
        tickLength: tickLength,
        lineStyle: lineStyle,
        labelStyle: labelStyle,
        axisLineStyle: axisLineStyle,
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
        (other is GridlineRendererSpec && super == other);
  }
}

/// Draws line across chart draw area for each tick.
///
/// Extends [BaseTickDrawStrategy].
class GridlineTickDrawStrategy<D> extends BaseTickDrawStrategy<D> {
  GridlineTickDrawStrategy(
    super.chartContext, {
    LineStyle? lineStyle,
    LineStyle? axisLineStyle,
    int? tickLength,
    super.labelAnchor,
    super.labelStyle,
    super.labelJustification,
    super.labelOffsetFromAxis,
    super.labelCollisionOffsetFromAxis,
    super.labelOffsetFromTick,
    super.labelCollisionOffsetFromTick,
    super.minimumPaddingBetweenLabels,
    super.labelRotation,
    super.labelCollisionRotation,
  })  : tickLength = tickLength ?? 0,
        _lineStyle = lineStyle,
        super(axisLineStyle: axisLineStyle ?? lineStyle);

  int tickLength;
  final LineStyle? _lineStyle;

  LineStyle get lineStyle => LineStyle(
        color: _lineStyle?.color ?? chartContext!.themeData.tickColor,
        dashPattern: _lineStyle?.dashPattern,
        strokeWidth: _lineStyle?.strokeWidth,
      );

  @override
  void draw(
    Canvas canvas,
    Offset offset,
    Tick<D> tick, {
    required AxisDirection orientation,
    required Rect axisBounds,
    required Rect drawAreaBounds,
    required bool isFirst,
    required bool isLast,
    bool collision = false,
  }) {
    Offset lineStart;
    Offset lineEnd;
    final tickLocation = tick.location!;
    switch (orientation) {
      case AxisDirection.up:
        final x = tickLocation;
        lineStart = Offset(x, axisBounds.bottom - tickLength);
        lineEnd = Offset(x, drawAreaBounds.bottom);
        break;
      case AxisDirection.down:
        final x = tickLocation;
        lineStart = Offset(x, drawAreaBounds.top + tickLength);
        lineEnd = Offset(x, axisBounds.top);
        break;
      case AxisDirection.right:
        final y = tickLocation;
        if (tickLabelAnchor(collision: collision) == TickLabelAnchor.after ||
            tickLabelAnchor(collision: collision) == TickLabelAnchor.before) {
          lineStart = Offset(axisBounds.right, y);
        } else {
          lineStart = Offset(axisBounds.left + tickLength, y);
        }
        lineEnd = Offset(drawAreaBounds.left, y);
        break;
      case AxisDirection.left:
        final y = tickLocation;

        if (tickLabelAnchor(collision: collision) == TickLabelAnchor.after ||
            tickLabelAnchor(collision: collision) == TickLabelAnchor.before) {
          lineStart = Offset(axisBounds.left, y);
        } else {
          lineStart = Offset(axisBounds.right, y);
        }
        lineEnd = Offset(drawAreaBounds.right, y);
        break;
    }

    canvas.drawChartLine(
      offset,
      points: [lineStart, lineEnd],
      dashPattern: lineStyle.dashPattern,
      stroke: lineStyle.color!.withOpacity(tick.textElement!.opacity),
      strokeWidth: lineStyle.strokeWidth,
    );

    drawLabel(
      canvas,
      offset,
      tick,
      orientation: orientation,
      axisBounds: axisBounds,
      isFirst: isFirst,
      isLast: isLast,
      collision: collision,
    );
  }
}
