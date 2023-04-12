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
import '../tick.dart' show Tick;
import 'base_tick_draw_strategy.dart' show BaseRenderSpec, BaseTickDrawStrategy;
import 'tick_draw_strategy.dart' show TickDrawStrategy;

@immutable
class SmallTickRendererSpec<D> extends BaseRenderSpec<D> {
  const SmallTickRendererSpec({
    this.lineStyle,
    this.tickLength,
    super.labelStyle,
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
  });

  final LineStyle? lineStyle;
  final int? tickLength;

  @override
  TickDrawStrategy<D> createDrawStrategy(ChartContext context) =>
      SmallTickDrawStrategy<D>(
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
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is SmallTickRendererSpec &&
            lineStyle == other.lineStyle &&
            tickLength == other.tickLength &&
            super == other);
  }

  @override
  int get hashCode => Object.hash(lineStyle, tickLength, super.hashCode);
}

/// Draws small tick lines for each tick. Extends [BaseTickDrawStrategy].
class SmallTickDrawStrategy<D> extends BaseTickDrawStrategy<D> {
  const SmallTickDrawStrategy(
    super.chartContext, {
    int? tickLength,
    LineStyle? lineStyle,
    super.labelStyle,
    super.axisLineStyle,
    super.labelAnchor,
    super.labelJustification,
    super.labelOffsetFromAxis,
    super.labelCollisionOffsetFromAxis,
    super.labelOffsetFromTick,
    super.labelCollisionOffsetFromTick,
    super.minimumPaddingBetweenLabels,
    super.labelRotation,
    super.labelCollisionRotation,
  })  : _tickLength = tickLength,
        _lineStyle = lineStyle;

  final int? _tickLength;
  int get tickLength => _tickLength ?? chartContext!.themeData.tickLength;

  final LineStyle? _lineStyle;
  LineStyle get lineStyle =>
      chartContext!.themeData.createTickLineStyle(_lineStyle);

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
    final tickPositions = calculateTickPositions(
      tick,
      orientation,
      axisBounds,
      drawAreaBounds,
      tickLength,
    );

    final tickStart = tickPositions.first;
    final tickEnd = tickPositions.last;

    canvas.drawChartLine(
      offset,
      points: [tickStart, tickEnd],
      dashPattern: lineStyle.dashPattern,
      stroke: lineStyle.color!,
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

  List<Offset> calculateTickPositions(
    Tick<D> tick,
    AxisDirection orientation,
    Rect axisBounds,
    Rect drawAreaBounds,
    int tickLength,
  ) {
    Offset tickStart;
    Offset tickEnd;
    final tickLocation = tick.location!;
    switch (orientation) {
      case AxisDirection.up:
        final x = tickLocation;
        tickStart = Offset(x, axisBounds.bottom - tickLength);
        tickEnd = Offset(x, axisBounds.bottom);
        break;
      case AxisDirection.down:
        final x = tickLocation;
        tickStart = Offset(x, axisBounds.top);
        tickEnd = Offset(x, axisBounds.top + tickLength);
        break;
      case AxisDirection.right:
        final y = tickLocation;
        tickStart = Offset(axisBounds.left, y);
        tickEnd = Offset(axisBounds.left + tickLength, y);
        break;
      case AxisDirection.left:
        final y = tickLocation;
        tickStart = Offset(axisBounds.right - tickLength, y);
        tickEnd = Offset(axisBounds.right, y);
        break;
    }
    return [tickStart, tickEnd];
  }
}
