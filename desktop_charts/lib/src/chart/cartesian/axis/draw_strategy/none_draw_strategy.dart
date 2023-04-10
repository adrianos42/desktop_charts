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
import '../collision_report.dart' show CollisionReport;
import '../spec/axis_spec.dart' show RenderSpec;
import '../tick.dart' show Tick;
import 'tick_draw_strategy.dart';

/// Renders no ticks no labels, and claims no space in layout.
/// However, it does render the axis line if asked to by the axis.
@immutable
class NoneRenderSpec<D> extends RenderSpec<D> {
  const NoneRenderSpec({
    this.axisLineStyle,
  });

  final LineStyle? axisLineStyle;

  @override
  TickDrawStrategy<D> createDrawStrategy(ChartContext context) =>
      NoneDrawStrategy<D>(
        axisLineStyleSpec: axisLineStyle,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is NoneRenderSpec;

  @override
  int get hashCode => 0.hashCode;
}

class NoneDrawStrategy<D> implements TickDrawStrategy<D> {
  NoneDrawStrategy({
    LineStyle? axisLineStyleSpec,
  })  : noneTextStyle = const TextStyle(),
        axisLineStyle = LineStyle(
          color: axisLineStyleSpec?.color,
          dashPattern: axisLineStyleSpec?.dashPattern,
          strokeWidth: axisLineStyleSpec?.strokeWidth,
        );

  LineStyle axisLineStyle;
  TextStyle noneTextStyle;

  @override
  void updateTickWidth(
    List<Tick<D>> ticks,
    double maxWidth,
    double maxHeight,
    AxisDirection orientation, {
    bool collision = false,
  }) {}

  @override
  CollisionReport<D> collides(
          List<Tick<D>>? ticks, AxisDirection? orientation) =>
      CollisionReport(ticksCollide: false, ticks: ticks);

  @override
  void decorateTicks(List<Tick<D>> ticks) {
    // Even though no text is rendered, the text style for each element should
    // still be set to handle the case of the draw strategy being switched to
    // a different draw strategy. The draw strategy will try to animate
    // the old ticks out and the text style property is used.
    for (final tick in ticks) {
      tick.textElement!.textStyle = noneTextStyle;
    }
  }

  @override
  void drawAxisLine(
    Canvas canvas,
    AxisDirection orientation,
    Rect axisBounds,
  ) {
    Offset start;
    Offset end;

    switch (orientation) {
      case AxisDirection.up:
        start = axisBounds.bottomLeft;
        end = axisBounds.bottomRight;

        break;
      case AxisDirection.down:
        start = axisBounds.topLeft;
        end = axisBounds.topRight;
        break;
      case AxisDirection.right:
        start = axisBounds.topLeft;
        end = axisBounds.bottomLeft;
        break;
      case AxisDirection.left:
        start = axisBounds.topRight;
        end = axisBounds.bottomRight;
        break;
    }

    canvas.drawChartLine(
      points: [start, end],
      dashPattern: axisLineStyle.dashPattern,
      stroke: axisLineStyle.color ?? const Color(0xff606060), // TODO
      strokeWidth: axisLineStyle.strokeWidth,
    );
  }

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
  }) {}

  @override
  Size measureHorizontallyDrawnTicks(
    List<Tick<D>> ticks,
    double maxWidth,
    double maxHeight, {
    bool collision = false,
  }) {
    return Size(maxWidth, 0.0);
  }

  @override
  Size measureVerticallyDrawnTicks(
    List<Tick<D>> ticks,
    double maxWidth,
    double maxHeight, {
    bool collision = false,
  }) {
    return Size(0.0, maxHeight);
  }
}
