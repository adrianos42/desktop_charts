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

import 'dart:math' show Point, cos, pi, sin, max;
import 'dart:ui';

import '../text_element.dart' show TextElement;
import 'canvas_shapes.dart' show CanvasBarStack, CanvasPie;
import '../curve.dart';

extension ChartCanvas on Canvas {
  /// Value to allow to overdraw above the draw area that fades to transparent.
  static const rectTopGradient = 5.0;

  /// Renders a sector of a circle, with an optional hole in the center.
  ///
  /// [center] The x, y coordinates of the circle's center.
  /// [radius] The radius of the circle.
  /// [innerRadius] Optional radius of a hole in the center of the circle that
  ///     should not be filled in as part of the sector.
  /// [startAngle] The angle at which the arc starts, measured clockwise from
  ///     the positive x axis and expressed in radians
  /// [endAngle] The angle at which the arc ends, measured clockwise from the
  ///     positive x axis and expressed in radians.
  /// [fill] Fill color for the sector.
  void drawChartCircleSector(
    Offset offset,
    Offset center,
    double radius,
    double innerRadius,
    double startAngle,
    double endAngle, {
    required Color fill,
  }) {
    _circleSectorPainterDraw(
      canvas: this,
      center: offset + center,
      endAngle: endAngle,
      fill: fill,
      innerRadius: innerRadius,
      radius: radius,
      startAngle: startAngle,
    );
  }

  /// Draws a smooth link from source to target.
  ///
  /// [sourceUpper] The location of the upper link at the source node.
  /// [sourceLower] The location of the lower link at the source node.
  /// [targetUpper] The location of the upper link at the target node.
  /// [targetLower] The location of the lower link at the target node.
  /// [fill] The fill color for the link.
  /// [orientation] Orientation enum of the link, vertical or horizontal.
  void drawChartLink(Link link, LinkOrientation orientation, Color fill) {
    // TODO: Implement drawLink for flutter.
    throw 'Flutter drawLink() has not been implemented.';
  }

  /// Renders a simple line.
  ///
  /// [dashPattern] controls the pattern of dashes and gaps in a line. It is a
  /// list of lengths of alternating dashes and gaps. The rendering is similar
  /// to stroke-dasharray in SVG path elements. An odd number of values in the
  /// pattern will be repeated to derive an even number of values. "1,2,3" is
  /// equivalent to "1,2,3,1,2,3."
  Rect drawChartLine(
    Offset offset, {
    required List<Offset> points,
    required Color stroke,
    Rect? clipBounds,
    bool? roundEndCaps,
    double? strokeWidth,
    List<int>? dashPattern,
    LineCurve curve = const LinearLineCurve(),
  }) {
    return _linePainterDraw(
      canvas: this,
      points: points.map((e) => e + offset).toList(),
      clipBounds: clipBounds?.shift(offset),
      stroke: stroke,
      roundEndCaps: roundEndCaps,
      strokeWidth: strokeWidth,
      dashPattern: dashPattern,
      curve: curve,
    );
  }

  void drawChartLinePath(
    Offset offset, {
    required Path path,
    required Color stroke,
    Rect? clipBounds,
    double? strokeWidth,
  }) {
    _linePainterDrawPath(
      canvas: this,
      clipBounds: clipBounds?.shift(offset),
      stroke: stroke,
      strokeWidth: strokeWidth,
      path: path.shift(offset),
    );
  }

  /// Renders a pie, with an optional hole in the center.
  void drawChartPie(Offset offset, CanvasPie canvasPie) {
    final center = offset + canvasPie.center;
    final radius = canvasPie.radius;
    final innerRadius = canvasPie.innerRadius;

    for (final slice in canvasPie.slices) {
      _circleSectorPainterDraw(
        canvas: this,
        center: center,
        radius: radius,
        innerRadius: innerRadius,
        startAngle: slice.startAngle,
        endAngle: slice.endAngle,
        fill: slice.fill!,
      );
    }

    // Draw stroke lines between pie slices. This is done after the slices are
    // drawn to ensure that they appear on top.
    if (canvasPie.stroke != null && canvasPie.slices.length > 1) {
      final Paint paint = Paint()..color = canvasPie.stroke!;
      // paint.color = Color(0xffff0000);

      paint.strokeWidth = canvasPie.strokeWidth;
      paint.strokeJoin = StrokeJoin.round;
      paint.style = PaintingStyle.stroke;

      final path = Path();

      for (int i = 0; i < canvasPie.slices.length; i += 1) {
        if (canvasPie.arcLength == 2 * pi || i < canvasPie.slices.length - 1) {
          final slice = canvasPie.slices[i];

          final innerRadiusEndPoint = Offset(
            (innerRadius * cos(slice.endAngle) + center.dx).toDouble(),
            (innerRadius * sin(slice.endAngle) + center.dy).toDouble(),
          );

          final radiusEndPoint = Offset(
            (radius * cos(slice.endAngle) + center.dx).toDouble(),
            (radius * sin(slice.endAngle) + center.dy).toDouble(),
          );

          path.moveTo(innerRadiusEndPoint.dx, innerRadiusEndPoint.dy);

          path.lineTo(radiusEndPoint.dx, radiusEndPoint.dy);
        }
      }

      drawPath(path, paint);
    }
  }

  /// Renders a simple point.
  ///
  /// [point] The x, y coordinates of the point.
  ///
  /// [radius] The radius of the point.
  ///
  /// [fill] Fill color for the point.
  ///
  /// [stroke] and [strokeWidth] configure the color and thickness of the
  /// outer edge of the point. Both must be provided together for a line to
  /// appear.
  ///
  /// [blendMode] Blend mode to be used when drawing this point on canvas.
  void drawChartPoint(
    Offset offset, {
    required Offset point,
    required double radius,
    Color? fill,
    Color? stroke,
    double? strokeWidth,
  }) {
    _pointPainterDraw(
      canvas: this,
      point: offset + point,
      radius: radius,
      fill: fill,
      stroke: stroke,
      strokeWidth: strokeWidth,
    );
  }

  /// Renders a polygon shape described by a set of points.
  ///
  /// [points] describes the vertices of the polygon. The last point will always
  /// be connected to the first point to close the shape.
  ///
  /// [fill] configures the color inside the polygon. The shape will be
  /// transparent if this is not provided.
  ///
  /// [stroke] and [strokeWidth] configure the color and thickness of the
  /// edges of the polygon. Both must be provided together for a line to appear.
  Rect drawChartPolygon(
    Offset offset, {
    required List<Offset> points,
    List<Offset> bottomPoints = const [],
    bool hasBottomCurve = false,
    LineCurve curve = const LinearLineCurve(),
    Rect? clipBounds,
    Color? fill,
    Color? stroke,
    double? strokeWidth,
  }) {
    return _polygonPainterDraw(
      canvas: this,
      points: points.map((e) => offset + e).toList(),
      clipBounds: clipBounds?.shift(offset),
      fill: fill,
      stroke: stroke,
      strokeWidth: strokeWidth,
      curve: curve,
      bottomPoints: bottomPoints.map((e) => offset + e).toList(),
      hasBottomCurve: hasBottomCurve,
    );
  }

  /// Renders a simple rectangle.
  ///
  /// [drawAreaBounds] if specified and if the bounds of the rectangle exceed
  /// the draw area bounds on the top, the first x (decided by the native
  /// platform) exceeding the draw area will apply a gradient to transparent
  /// with anything exceeding the x to be transparent.
  void drawChartRect(
    Offset offset,
    Rect bounds, {
    Color? background,
    required Color fill,
    Color? stroke,
    FillPatternType? pattern,
    double? strokeWidth,
    Rect? drawAreaBounds,
  }) {
    final chartBounds = bounds.shift(offset);
    final drawBounds = drawAreaBounds?.shift(offset);

    final bool drawStroke =
        strokeWidth != null && strokeWidth > 0.0 && stroke != null;

    final strokeWidthOffset = (drawStroke ? strokeWidth : 0.0);

    // Factor out stroke width, if a stroke is enabled.
    final fillRectBounds = Rect.fromLTWH(
      chartBounds.left + (strokeWidthOffset / 2.0).truncateToDouble(),
      chartBounds.top + (strokeWidthOffset / 2.0).truncateToDouble(),
      chartBounds.width - strokeWidthOffset,
      chartBounds.height - strokeWidthOffset,
    );

    switch (pattern) {
      case FillPatternType.forwardHatch:
        _drawForwardHatchPattern(
          fillRectBounds,
          this,
          fill: fill,
          drawAreaBounds: drawBounds,
          background: background!,
        );
        break;

      case FillPatternType.solid:
      default:
        final Paint paint = Paint();
        // Use separate rect for drawing stroke
        paint.color = fill;
        paint.style = PaintingStyle.fill;

        // Apply a gradient to the top [rect_top_gradient] to transparent
        // if the rectangle is higher than the [drawAreaBounds] top.
        if (drawBounds != null && chartBounds.top < drawBounds.top) {
          paint.shader = _createHintGradient(
            drawBounds.left,
            drawBounds.top,
            fill,
          );
        }

        drawRect(fillRectBounds, paint);
        break;
    }

    // [Canvas.drawRect] does not support drawing a rectangle with both a fill
    // and a stroke at this time. Use a separate rect for the stroke.
    if (drawStroke) {
      final Paint paint = Paint();
      paint.color = stroke;
      // Set shader to null if no draw area bounds so it can use the color
      // instead.
      paint.shader = drawBounds != null
          ? _createHintGradient(drawBounds.left, drawBounds.top, stroke)
          : null;
      paint.strokeJoin = StrokeJoin.miter;
      paint.strokeWidth = strokeWidth;
      paint.style = PaintingStyle.stroke;

      drawRect(chartBounds, paint);
    }
  }

  /// Renders a rounded rectangle.
  void drawChartRRect(
    Offset offset,
    RRect bounds, {
    required Color fill,
    Color? stroke,
    Color? patternColor,
    FillPatternType? fillPattern,
    double? patternStrokeWidth,
    double? strokeWidth,
    double? radius,
  }) {
    // Use separate rect for drawing stroke
    final Paint paint = Paint()
      ..color = fill
      ..style = PaintingStyle.fill;

    drawRRect(
      bounds.shift(offset),
      paint,
    );
  }

  /// Renders a stack of bars, rounding the last bar in the stack.
  ///
  /// The first bar of the stack is expected to be the "base" bar. This would
  /// be the bottom most bar for a vertically rendered bar.
  ///
  /// [drawAreaBounds] if specified and if the bounds of the rectangle exceed
  /// the draw area bounds on the top, the first x (decided by the native
  /// platform) exceeding the draw area will apply a gradient to transparent
  /// with anything exceeding the x to be transparent.
  void drawChartBarStack(
    Offset offset,
    CanvasBarStack barStack, {
    Rect? drawAreaBounds,
    required Color background,
  }) {
    this
      ..save()
      ..clipRect(barStack.fullStackRect.shift(offset));

    // Draw each bar.
    for (int barIndex = 0; barIndex < barStack.segments.length; barIndex += 1) {
      // TODO: Add configuration for hiding stack line.
      // TODO: Don't draw stroke on bottom of bars.
      final segment = barStack.segments[barIndex];
      drawChartRect(
        offset,
        segment.bounds,
        fill: segment.fill!,
        pattern: segment.pattern,
        stroke: segment.stroke,
        strokeWidth: segment.strokeWidth,
        drawAreaBounds: drawAreaBounds,
        background: background,
      );
    }

    restore();
  }

  void drawChartText(
    Offset offset,
    TextElement textElement,
    double offsetX,
    double offsetY, {
    double rotation = 0.0,
  }) {
    final textDirection = textElement.textDirection;
    final measurement = textElement.measurement;

    offsetX += offset.dx;
    offsetY += offset.dy;

    if (rotation != 0) {
      // TODO: Remove once textAnchor works.
      if (textDirection == TextDirection.rtl) {
        offsetY += measurement.horizontalSliceWidth;
      }

      offsetX -= textElement.verticalFontShift;

      save();
      translate(offsetX, offsetY);
      rotate(rotation);

      textElement.textPainter!.paint(this, Offset.zero);

      restore();
    } else {
      // TODO: Remove once textAnchor works.
      if (textDirection == TextDirection.rtl) {
        offsetX -= measurement.horizontalSliceWidth.truncateToDouble();
      }

      // Account for missing center alignment.
      if (textDirection == null) {
        offsetX -= (measurement.horizontalSliceWidth / 2.0).truncateToDouble();
      }

      offsetY -= textElement.verticalFontShift;

      textElement.textPainter!.paint(this, Offset(offsetX, offsetY));
    }
  }

  /// Request the canvas to clip to [clipBounds].
  ///
  /// Applies to all operations until [restClipBounds] is called.
  void setChartClipBounds(Offset offset, Rect clipBounds) {
    this
      ..save()
      ..clipRect(clipBounds.shift(offset));
  }

  /// Restore
  void resetChartClipBounds() {
    restore();
  }

  /// Creates a bottom to top gradient that transitions [fill] to transparent.
  Gradient _createHintGradient(double left, double top, Color fill) {
    return Gradient.linear(
      Offset(left, top),
      Offset(left, top - rectTopGradient),
      [
        fill,
        fill.withAlpha(0),
      ],
    );
  }

  /// Draws a forward hatch pattern in the given bounds.
  void _drawForwardHatchPattern(
    Rect bounds,
    Canvas canvas, {
    required Color background,
    required Color fill,
    double fillWidth = 4.0,
    Rect? drawAreaBounds,
  }) {
    // Fill in the shape with a solid background color.
    final Paint paint = Paint()
      ..color = background
      ..style = PaintingStyle.fill;

    // Apply a gradient the background if bounds exceed the draw area.
    if (drawAreaBounds != null && bounds.top < drawAreaBounds.top) {
      paint.shader = _createHintGradient(
        drawAreaBounds.left,
        drawAreaBounds.top,
        background,
      );
    }

    canvas.drawRect(bounds, paint);

    // As a simplification, we will treat the bounds as a large square and fill
    // it up with lines from the bottom-left corner to the top-right corner.
    // Get the longer side of the bounds here for the size of this square.
    final size = max(bounds.width, bounds.height);

    final x0 = bounds.left + size + fillWidth;
    final x1 = bounds.left - fillWidth;
    final y0 = bounds.bottom - size - fillWidth;
    final y1 = bounds.bottom + fillWidth;
    const offset = 8;

    final isVertical = bounds.height >= bounds.width;

    // The "first" line segment will be drawn from the bottom left corner of the
    // bounds, up and towards the right. Start the loop N iterations "back" to
    // draw partial line segments beneath (or to the left) of this segment,
    // where N is the number of offsets that fit inside the smaller dimension of
    // the bounds.
    final smallSide = isVertical ? bounds.width : bounds.height;
    final start = -(smallSide / offset).round() * offset;

    // Keep going until we reach the top or right of the bounds, depending on
    // whether the rectangle is oriented vertically or horizontally.
    final end = size + offset;

    // Create gradient for line painter if top bounds exceeded.
    Shader? lineShader;
    if (drawAreaBounds != null && bounds.top < drawAreaBounds.top) {
      lineShader = _createHintGradient(
        drawAreaBounds.left,
        drawAreaBounds.top,
        fill,
      );
    }

    for (int i = start; i < end; i = i + offset) {
      // For vertical bounds, we need to draw lines from top to bottom. For
      // bounds, we need to draw lines from left to right.
      final modifier = isVertical ? -1 * i : i;

      // Draw a line segment in the bottom right corner of the pattern.
      _linePainterDraw(
        canvas: canvas,
        points: [
          Offset(x0 + modifier, y0),
          Offset(x1 + modifier, y1),
        ],
        stroke: fill,
        strokeWidth: 4.0,
        shader: lineShader,
        curve: const LinearLineCurve(),
      );
    }
  }
}

Color getAnimatedColor(Color previous, Color target, double animationPercent) {
  final red =
      (((target.red - previous.red) * animationPercent) + previous.red).round();
  final green =
      (((target.green - previous.green) * animationPercent) + previous.green)
          .round();
  final blue =
      (((target.blue - previous.blue) * animationPercent) + previous.blue)
          .round();
  final alpha =
      (((target.alpha - previous.alpha) * animationPercent) + previous.alpha)
          .round();

  return Color.fromARGB(alpha, red, green, blue);
}

/// Defines the pattern for a color fill.
///
/// * [forwardHatch] defines a pattern of white lines angled up and to the right
///   on top of a bar filled with the fill color.
/// * [solid] defines a simple bar filled with the fill color. This is the
///   default pattern for bars.
enum FillPatternType { forwardHatch, solid }

/// Determines the orientation of a drawn link.
///
/// * [horizontal] Link control points are averaged across the x-axis.
/// * [vertical] Link control points are averaged across the y-axis.
enum LinkOrientation { horizontal, vertical }

/// A link as defined by the two sets of points that determine the bezier
/// curves of the link.
///
/// [sourceUpper] The location of the upper link at the source node.
/// [sourceLower] The location of the lower link at the source node.
/// [targetUpper] The location of the upper link at the target node.
/// [targetLower] The location of the lower link at the target node.
class Link {
  const Link(
      this.sourceUpper, this.sourceLower, this.targetUpper, this.targetLower);

  final Offset sourceUpper;
  final Offset sourceLower;
  final Offset targetUpper;
  final Offset targetLower;
}

/// Draws a simple line.
///
/// [dashPattern] controls the pattern of dashes and gaps in a line. It is a
/// list of lengths of alternating dashes and gaps. The rendering is similar
/// to stroke-dash-array in SVG path elements. An odd number of values in the
/// pattern will be repeated to derive an even number of values. "1,2,3" is
/// equivalent to "1,2,3,1,2,3."
Rect _linePainterDraw({
  required Canvas canvas,
  required List<Offset> points,
  required Color stroke,
  required LineCurve curve,
  Rect? clipBounds,
  bool? roundEndCaps,
  double? strokeWidth,
  List<int>? dashPattern,
  Shader? shader,
}) {
  if (points.isEmpty) {
    return Rect.zero;
  }

  // Apply clip bounds as a clip region.
  if (clipBounds != null) {
    canvas
      ..save()
      ..clipRect(clipBounds);
  }

  final Paint paint = Paint()..color = stroke;

  if (shader != null) {
    paint.shader = shader;
  }

  Rect bounds = Rect.zero;

  // If the line has a single point, draw a circle.
  if (points.length == 1) {
    final point = points.first;
    paint.style = PaintingStyle.fill;
    canvas.drawCircle(point, strokeWidth ?? 0.0, paint);
  } else {
    if (strokeWidth != null) {
      paint.strokeWidth = strokeWidth;
    }
    paint.strokeJoin = StrokeJoin.miter;
    paint.style = PaintingStyle.stroke;

    if (dashPattern == null || dashPattern.isEmpty) {
      if (roundEndCaps == true) {
        paint.strokeCap = StrokeCap.round;
      }
      bounds = _linePainterdrawSolidLine(
        canvas,
        paint,
        points,
        curve,
      );
    } else {
      _linePainterdrawDashedLine(
        canvas,
        paint,
        points,
        dashPattern,
        curve,
      );
    }
  }

  if (clipBounds != null) {
    canvas.restore();
  }

  return bounds;
}

void _linePainterDrawPath({
  required Canvas canvas,
  required Path path,
  required Color stroke,
  Rect? clipBounds,
  double? strokeWidth,
  Shader? shader,
}) {
  // Apply clip bounds as a clip region.
  if (clipBounds != null) {
    canvas
      ..save()
      ..clipRect(clipBounds);
  }

  final Paint paint = Paint()..color = stroke;

  if (shader != null) {
    paint.shader = shader;
  }

  if (strokeWidth != null) {
    paint.strokeWidth = strokeWidth;
  }
  paint.strokeJoin = StrokeJoin.miter;
  paint.style = PaintingStyle.stroke;

  canvas.drawPath(path, paint);

  if (clipBounds != null) {
    canvas.restore();
  }
}

/// Draws solid lines between each point.
Rect _linePainterdrawSolidLine(
  Canvas canvas,
  Paint paint,
  List<Offset> points,
  LineCurve curve,
) {
  final path = Path()..moveTo(points.first.dx, points.first.dy);
  curve.draw(path, points);
  canvas.drawPath(path, paint);
  return path.getBounds();
}

/// Draws dashed lines lines between each point.
void _linePainterdrawDashedLine(
  Canvas canvas,
  Paint paint,
  List<Offset> points,
  List<int> dashPattern,
  LineCurve curve,
) {
  final localDashPattern = List.of(dashPattern, growable: true);

  // If an odd number of parts are defined, repeat the pattern to get an even
  // number.
  if (dashPattern.length.isOdd) {
    localDashPattern.addAll(dashPattern);
  }

  // Stores the previous point in the series.
  Offset previousSeriesPoint = points.first;

  int remainder = 0;
  bool solid = true;
  int dashPatternIndex = 0;

  // Gets the next segment in the dash pattern, looping back to the
  // beginning once the end has been reached.
  int getNextDashPatternSegment() {
    final dashSegment = localDashPattern[dashPatternIndex];
    dashPatternIndex = (dashPatternIndex + 1) % localDashPattern.length;
    return dashSegment;
  }

  // Array of points that is used to draw a connecting path when only a
  // partial dash pattern segment can be drawn in the remaining length of a
  // line segment (between two defined points in the shape).
  List<Offset>? remainderPoints;

  // Draw the path through all the rest of the points in the series.
  for (int pointIndex = 1; pointIndex < points.length; pointIndex++) {
    // Stores the current point in the series.
    final seriesPoint = points[pointIndex];

    if (previousSeriesPoint == seriesPoint) {
      // Bypass dash pattern handling if the points are the same.
    } else {
      // Stores the previous point along the current series line segment where
      // we rendered a dash (or left a gap).
      Offset previousPoint = previousSeriesPoint;

      double d = _getOffsetDistance(previousSeriesPoint, seriesPoint);

      while (d > 0) {
        final dashSegment =
            remainder > 0 ? remainder : getNextDashPatternSegment();
        remainder = 0;

        // Create a unit vector in the direction from previous to next point.
        final v = seriesPoint - previousPoint;
        final u = Offset(v.dx / v.distance, v.dy / v.distance);

        // If the remaining distance is less than the length of the dash
        // pattern segment, then cut off the pattern segment for this portion
        // of the overall line.
        final double distance = d < dashSegment ? d : dashSegment.toDouble();

        // Compute a vector representing the length of dash pattern segment to
        // be drawn.
        final nextPoint = previousPoint + (u * distance);

        // If we are in a solid portion of the dash pattern, draw a line.
        // Else, move on.
        if (solid) {
          if (remainderPoints != null) {
            // If we had a partial un-drawn dash from the previous point along
            // the line, draw a path that includes it and the end of the dash
            // pattern segment in the current line segment.
            remainderPoints.add(nextPoint);

            final path = Path()
              ..moveTo(remainderPoints.first.dx, remainderPoints.first.dy);

            for (final p in remainderPoints) {
              path.lineTo(p.dx, p.dy);
            }

            canvas.drawPath(path, paint);

            remainderPoints = null;
          } else {
            if (d < dashSegment && pointIndex < points.length - 1) {
              // If the remaining distance d is too small to fit this dash,
              // and we have more points in the line, save off a series of
              // remainder points so that we can draw a path segment moving in
              // the direction of the next point.
              //
              // Note that we don't need to save anything off for the "blank"
              // portions of the pattern because we still take the remaining
              // distance into account before starting the next dash in the
              // next line segment.
              remainderPoints = [previousPoint, nextPoint];
            } else {
              // Otherwise, draw a simple line segment for this dash.
              canvas.drawLine(previousPoint, nextPoint, paint);
            }
          }
        }

        solid = !solid;
        previousPoint = nextPoint;
        d = d - dashSegment;
      }

      // Save off the remaining distance so that we can continue the dash (or
      // gap) into the next line segment.
      remainder = -d.round();

      // If we have a remaining un-drawn distance for the current dash (or
      // gap), revert the last change to "solid" so that we will continue
      // either drawing a dash or leaving a gap.
      if (remainder > 0) {
        solid = !solid;
      }
    }

    previousSeriesPoint = seriesPoint;
  }
}

double _getOffsetDistance(Offset o1, Offset o2) {
  final p1 = Point(o1.dx, o1.dy);
  final p2 = Point(o2.dx, o2.dy);
  return p1.distanceTo(p2);
}

void _circleSectorPainterDraw({
  required Canvas canvas,
  required Offset center,
  required double radius,
  required double innerRadius,
  required double startAngle,
  required double endAngle,
  required Color fill,
}) {
  final paint = Paint()
    ..color = fill
    ..style = PaintingStyle.fill;

  final innerRadiusStartPoint = Offset(
    (innerRadius * cos(startAngle) + center.dx).toDouble(),
    (innerRadius * sin(startAngle) + center.dy).toDouble(),
  );

  final innerRadiusEndPoint = Offset(
    (innerRadius * cos(endAngle) + center.dx).toDouble(),
    (innerRadius * sin(endAngle) + center.dy).toDouble(),
  );

  final radiusStartPoint = Offset(
    (radius * cos(startAngle) + center.dx).toDouble(),
    (radius * sin(startAngle) + center.dy).toDouble(),
  );

  final isFullCircle = endAngle - startAngle == 2.0 * pi;

  final midpointAngle = (endAngle + startAngle) / 2.0;

  final path = Path()
    ..moveTo(
      innerRadiusStartPoint.dx,
      innerRadiusStartPoint.dy,
    );

  path.lineTo(radiusStartPoint.dx, radiusStartPoint.dy);

  // For full circles, draw the arc in two parts.
  if (isFullCircle) {
    path.arcTo(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      midpointAngle - startAngle,
      true,
    );
    path.arcTo(
      Rect.fromCircle(center: center, radius: radius),
      midpointAngle,
      endAngle - midpointAngle,
      true,
    );
  } else {
    path.arcTo(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      endAngle - startAngle,
      true,
    );
  }

  path.lineTo(innerRadiusEndPoint.dx, innerRadiusEndPoint.dy);

  // For full circles, draw the arc in two parts.
  if (isFullCircle) {
    path.arcTo(
      Rect.fromCircle(center: center, radius: innerRadius),
      endAngle,
      midpointAngle - endAngle,
      true,
    );
    path.arcTo(
      Rect.fromCircle(center: center, radius: innerRadius),
      midpointAngle,
      startAngle - midpointAngle,
      true,
    );
  } else {
    path.arcTo(
      Rect.fromCircle(center: center, radius: innerRadius),
      endAngle,
      startAngle - endAngle,
      true,
    );
  }

  // Drawing two copies of this line segment, before and after the arcs,
  // ensures that the path actually gets closed correctly.
  path.lineTo(radiusStartPoint.dx, radiusStartPoint.dy);

  canvas.drawPath(path, paint);
}

void _pointPainterDraw({
  required Canvas canvas,
  required Offset point,
  required double radius,
  Color? fill,
  Color? stroke,
  double? strokeWidth,
}) {
  final Paint paint = Paint();

  if (fill != null) {
    paint.color = fill;
    paint.style = PaintingStyle.fill;

    canvas.drawCircle(point, radius, paint);
  }

  // [Canvas.drawCircle] does not support drawing a circle with both a fill
  // and a stroke at this time. Use a separate circle for the stroke.
  if (stroke != null && strokeWidth != null && strokeWidth > 0.0) {
    paint.color = stroke;
    paint.strokeWidth = strokeWidth;
    paint.strokeJoin = StrokeJoin.bevel;
    paint.style = PaintingStyle.stroke;

    canvas.drawCircle(point, radius, paint);
  }
}

Rect _polygonPainterDraw({
  required Canvas canvas,
  required List<Offset> points,
  required LineCurve curve,
  Rect? clipBounds,
  Color? fill,
  Color? stroke,
  double? strokeWidth,
  List<Offset> bottomPoints = const [],
  bool hasBottomCurve = false,
}) {
  if (points.isEmpty) {
    return Rect.zero;
  }

  // Apply clip bounds as a clip region.
  if (clipBounds != null) {
    canvas
      ..save()
      ..clipRect(clipBounds);
  }

  final Paint paint = Paint();
  final Rect bounds;

  // If the line has a single point, draw a circle.
  if (points.length == 1) {
    final point = points.first;

    if (fill != null) {
      paint.color = fill;
    }

    paint.style = PaintingStyle.fill;
    canvas.drawCircle(point, strokeWidth!, paint);
    bounds = Rect.zero;
  } else {
    if (stroke != null && strokeWidth != null) {
      paint.strokeWidth = strokeWidth;
      paint.strokeJoin = StrokeJoin.bevel;
      paint.style = PaintingStyle.stroke;
    }

    if (fill != null) {
      paint.color = fill;
      paint.style = PaintingStyle.fill;
    }

    final areaPoints = List.of(points);
    final bottomAreaPoints = List.of(bottomPoints);

    final path = Path();

    if (bottomAreaPoints.isNotEmpty) {
      path.moveTo(bottomAreaPoints.first.dx, bottomAreaPoints.first.dy);

      if (hasBottomCurve) {
        curve.draw(path, bottomAreaPoints);
      } else {
        const LinearLineCurve().draw(path, bottomAreaPoints);
      }

      path.lineTo(areaPoints.first.dx, areaPoints.first.dy);
    } else {
      path.moveTo(points.first.dx, points.first.dy);
    }

    curve.draw(path, areaPoints);

    canvas.drawPath(path, paint);
    bounds = path.getBounds();
  }

  if (clipBounds != null) {
    canvas.restore();
  }

  return bounds;
}
