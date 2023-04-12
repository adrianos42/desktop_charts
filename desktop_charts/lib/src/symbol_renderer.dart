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

import 'dart:math' show min, sqrt;

import 'package:flutter/widgets.dart';

import 'chart/chart_canvas.dart' show ChartCanvas, FillPatternType;

/// Strategy for rendering a symbol.
@immutable
abstract class BaseSymbolRenderer {
  const BaseSymbolRenderer();

  bool shouldRepaint(covariant BaseSymbolRenderer oldRenderer);

  @override
  bool operator ==(Object other) {
    return other is BaseSymbolRenderer;
  }

  @override
  int get hashCode => runtimeType.hashCode;
}

/// Strategy for rendering a symbol bounded within a box.
@immutable
abstract class SymbolRenderer extends BaseSymbolRenderer {
  const SymbolRenderer({
    required this.isSolid,
  });

  /// Whether the symbol should be rendered as a solid shape, or a hollow shape.
  ///
  /// If this is true, then fillColor and strokeColor will be used to fill in
  /// the shape, and draw a border, respectively. The stroke (border) will only
  /// be visible if a non-zero strokeWidth is configured.
  ///
  /// If this is false, then the shape will be filled in with a white color
  /// (overriding fillColor). strokeWidth will default to 2 if none was
  /// configured.
  final bool isSolid;

  void draw(
    Canvas canvas,
    Offset offset,
    Rect bounds, {
    List<int>? dashPattern,
    Color? fillColor,
    FillPatternType? fillPattern,
    Color? strokeColor,
    double? strokeWidth,
  });

  @protected
  double? getSolidStrokeWidth(double? strokeWidth) {
    return isSolid ? strokeWidth : (strokeWidth ?? 2.0);
  }

  @protected
  Color? getSolidFillColor(Color? fillColor) {
    return isSolid ? fillColor : const Color(0xff000000); // TODO white
  }

  @override
  bool operator ==(Object other) {
    return other is SymbolRenderer && other.isSolid == isSolid;
  }

  @override
  int get hashCode => Object.hash(super.hashCode, isSolid);
}

/// Strategy for rendering a symbol centered around a point.
///
/// An optional second point can describe an extended symbol.
abstract class PointSymbolRenderer extends BaseSymbolRenderer {
  const PointSymbolRenderer();

  void draw(
    Canvas canvas,
    Offset offset,
    Offset p1,
    double radius, {
    required Offset p2,
    Color? fillColor,
    Color? strokeColor,
  });
}

/// Rounded rectangular symbol with corners having [radius].
class RoundedRectSymbolRenderer extends SymbolRenderer {
  const RoundedRectSymbolRenderer({
    this.radius = 1.0,
    super.isSolid = true,
  });

  final double radius;

  @override
  void draw(
    Canvas canvas,
    Offset offset,
    Rect bounds, {
    List<int>? dashPattern,
    Color? fillColor,
    FillPatternType? fillPattern,
    Color? strokeColor,
    double? strokeWidth,
  }) {
    canvas.drawChartRRect(
      offset,
      RRect.fromRectAndRadius(bounds, Radius.circular(radius)),
      fill: getSolidFillColor(fillColor ?? const Color(0x7f00ff00))!,
      fillPattern: fillPattern,
      stroke: strokeColor,
    );
  }

  @override
  bool shouldRepaint(RoundedRectSymbolRenderer oldRenderer) {
    return this != oldRenderer;
  }

  @override
  bool operator ==(Object other) {
    return other is RoundedRectSymbolRenderer &&
        other.radius == radius &&
        super == other;
  }

  @override
  int get hashCode => Object.hash(super.hashCode, radius);
}

/// Line symbol renderer.
class LineSymbolRenderer extends SymbolRenderer {
  const LineSymbolRenderer({
    List<int>? dashPattern,
    super.isSolid = true,
    double? strokeWidth,
  })  : strokeWidth = strokeWidth ?? strokeWidthForRoundEndCaps,
        _dashPattern = dashPattern;

  static const roundEndCapsPixels = 2;
  static const minLengthToRoundCaps = (roundEndCapsPixels * 2) + 1;
  static const strokeWidthForRoundEndCaps = 4.0;
  static const strokeWidthForNonRoundedEndCaps = 2.0;

  /// Thickness of the line stroke.
  final double strokeWidth;

  /// Dash pattern for the line.
  final List<int>? _dashPattern;

  @override
  void draw(
    Canvas canvas,
    Offset offset,
    Rect bounds, {
    List<int>? dashPattern,
    Color? fillColor,
    FillPatternType? fillPattern,
    Color? strokeColor,
    double? strokeWidth,
  }) {
    final centerHeight = (bounds.bottom - bounds.top) / 2;

    // If we have a dash pattern, do not round the end caps, and set
    // strokeWidth to a smaller value. Using round end caps makes smaller
    // patterns blurry.
    final localDashPattern = dashPattern ?? _dashPattern;
    final roundEndCaps = localDashPattern == null;

    // If we have a dash pattern, the normal stroke width makes them look
    // strangely tall.
    final localStrokeWidth = localDashPattern == null
        ? getSolidStrokeWidth(strokeWidth ?? strokeWidth)
        : strokeWidthForNonRoundedEndCaps;

    // Adjust the length so the total width includes the rounded pixels.
    // Otherwise the cap is drawn past the bounds and appears to be cut off.
    // If bounds is not long enough to accommodate the line, do not adjust.
    double left = bounds.left;
    double right = bounds.right;

    if (roundEndCaps && bounds.width >= minLengthToRoundCaps) {
      left += roundEndCapsPixels;
      right -= roundEndCapsPixels;
    }

    // TODO: Pass in strokeWidth, roundEndCaps, and dashPattern from
    // line renderer config.
    canvas.drawChartLine(
      offset,
      points: [Offset(left, centerHeight), Offset(right, centerHeight)],
      dashPattern: localDashPattern,
      // TODO fill: getSolidFillColor(fillColor)!,
      roundEndCaps: roundEndCaps,
      stroke: strokeColor!,
      strokeWidth: localStrokeWidth,
    );
  }

  @override
  bool shouldRepaint(LineSymbolRenderer oldRenderer) {
    return this != oldRenderer;
  }

  @override
  bool operator ==(Object other) {
    return other is LineSymbolRenderer &&
        other.strokeWidth == strokeWidth &&
        super == other;
  }

  @override
  int get hashCode => Object.hash(
        super.hashCode,
        strokeWidth,
      );
}

/// Circle symbol renderer.
class CircleSymbolRenderer extends SymbolRenderer {
  const CircleSymbolRenderer({
    super.isSolid = true,
  });

  @override
  void draw(
    Canvas canvas,
    Offset offset,
    Rect bounds, {
    List<int>? dashPattern,
    Color? fillColor,
    FillPatternType? fillPattern,
    Color? strokeColor,
    double? strokeWidth,
  }) {
    final center = Offset(
      bounds.left + (bounds.width / 2),
      bounds.top + (bounds.height / 2),
    );
    final radius = min(bounds.width, bounds.height) / 2;
    canvas.drawChartPoint(
      offset,
      point: center,
      radius: radius,
      fill: getSolidFillColor(fillColor),
      stroke: strokeColor,
      strokeWidth: getSolidStrokeWidth(strokeWidth),
    );
  }

  @override
  bool shouldRepaint(CircleSymbolRenderer oldRenderer) {
    return this != oldRenderer;
  }

  @override
  bool operator ==(Object other) =>
      other is CircleSymbolRenderer && super == other;

  @override
  int get hashCode => Object.hash(super.hashCode, runtimeType.hashCode);
}

/// Rectangle symbol renderer.
class RectSymbolRenderer extends SymbolRenderer {
  const RectSymbolRenderer({
    super.isSolid = true,
  });

  @override
  void draw(
    Canvas canvas,
    Offset offset,
    Rect bounds, {
    List<int>? dashPattern,
    Color? fillColor,
    FillPatternType? fillPattern,
    Color? strokeColor,
    double? strokeWidth,
  }) {
    canvas.drawChartRect(
      offset, bounds,
      fill: getSolidFillColor(fillColor)!,
      stroke: strokeColor,
      strokeWidth: getSolidStrokeWidth(
        strokeWidth,
      ),
      background: Color(0xff000000), // TODO
    );
  }

  @override
  bool shouldRepaint(RectSymbolRenderer oldRenderer) {
    return this != oldRenderer;
  }

  @override
  bool operator ==(Object other) =>
      other is RectSymbolRenderer && super == other;

  @override
  int get hashCode => Object.hash(super.hashCode, runtimeType.hashCode);
}

/// This [SymbolRenderer] renders an upward pointing equilateral triangle.
class TriangleSymbolRenderer extends SymbolRenderer {
  const TriangleSymbolRenderer({
    super.isSolid = true,
  });

  @override
  void draw(
    Canvas canvas,
    Offset offset,
    Rect bounds, {
    List<int>? dashPattern,
    Color? fillColor,
    FillPatternType? fillPattern,
    Color? strokeColor,
    double? strokeWidth,
  }) {
    // To maximize the size of the triangle in the available space, we can use
    // the width as the length of each size. Set the bottom edge to be the full
    // width, and then calculate the height based on the 30/60/90 degree right
    // triangle whose tall side is the height of our equilateral triangle.
    final dy = sqrt(3) / 2 * bounds.width;
    final centerX = (bounds.left + bounds.right) / 2;
    canvas.drawChartPolygon(
      offset,
      points: [
        Offset(bounds.left, bounds.top + dy),
        Offset(bounds.right, bounds.top + dy),
        Offset(centerX, bounds.top),
      ],
      fill: getSolidFillColor(fillColor),
      stroke: strokeColor,
      strokeWidth: getSolidStrokeWidth(strokeWidth),
    );
  }

  @override
  bool shouldRepaint(TriangleSymbolRenderer oldRenderer) {
    return this != oldRenderer;
  }

  @override
  bool operator ==(Object other) =>
      other is TriangleSymbolRenderer && super == other;

  @override
  int get hashCode => Object.hash(super.hashCode, runtimeType.hashCode);
}

/// Draws a cylindrical shape connecting two points.
@immutable
class CylinderSymbolRenderer extends PointSymbolRenderer {
  const CylinderSymbolRenderer();

  @override
  void draw(
    Canvas canvas,
    Offset offset,
    Offset p1,
    double radius, {
    required Offset p2,
    Color? fillColor,
    Color? strokeColor,
    double? strokeWidth,
  }) {
    canvas.drawChartLine(
      offset,
      points: [p1, p2],
      stroke: strokeColor!,
      roundEndCaps: true,
      strokeWidth: radius * 2,
    );
  }

  @override
  bool shouldRepaint(CylinderSymbolRenderer oldRenderer) {
    return this != oldRenderer;
  }

  @override
  bool operator ==(Object other) => other is CylinderSymbolRenderer;

  @override
  int get hashCode => Object.hash(super.hashCode, runtimeType.hashCode);
}

/// Draws a rectangular shape connecting two points.
@immutable
class RectangleRangeSymbolRenderer extends PointSymbolRenderer {
  const RectangleRangeSymbolRenderer();

  @override
  void draw(
    Canvas canvas,
    Offset offset,
    Offset p1,
    double radius, {
    required Offset p2,
    Color? fillColor,
    Color? strokeColor,
    double? strokeWidth,
  }) {
    canvas.drawChartLine(
      offset,
      points: [p1, p2],
      stroke: strokeColor!,
      roundEndCaps: false,
      strokeWidth: radius * 2,
    );
  }

  @override
  bool shouldRepaint(RectangleRangeSymbolRenderer oldRenderer) {
    return this != oldRenderer;
  }

  @override
  bool operator ==(Object other) => other is RectangleRangeSymbolRenderer;

  @override
  int get hashCode => Object.hash(super.hashCode, runtimeType.hashCode);
}

/// Flutter widget responsible for painting a common SymbolRenderer from the
/// chart.
///
/// If you want to customize the symbol, then use [CustomSymbolRenderer].
class SymbolRendererCanvas implements SymbolRendererBuilder {
  const SymbolRendererCanvas({
    required this.symbolRenderer,
    this.dashPattern,
  });

  final SymbolRenderer symbolRenderer;
  final List<int>? dashPattern;

  @override
  Widget build(
    BuildContext context, {
    Color? color,
    required Size size,
    bool enabled = true,
  }) {
    if (color != null && !enabled) {
      color = color.withOpacity(0.26);
    }

    return SizedBox.fromSize(
      size: size,
      child: CustomPaint(
        painter: _SymbolCustomPaint(
          context,
          symbolRenderer,
          color,
          dashPattern,
        ),
      ),
    );
  }
}

/// Convenience class allowing you to pass your Widget builder through the
/// common chart so that it is created for you by the Legend.
///
/// This allows a custom SymbolRenderer in Flutter without having to create
/// a completely custom legend.
abstract class CustomSymbolRenderer extends SymbolRenderer
    implements SymbolRendererBuilder {
  const CustomSymbolRenderer() : super(isSolid: false);

  /// Must override this method to build the custom Widget with the given color
  /// as
  @override
  Widget build(
    BuildContext context, {
    Color? color,
    required Size size,
    bool enabled = true,
  });

  @override
  void draw(
    Canvas canvas,
    Offset offset,
    Rect bounds, {
    List<int>? dashPattern,
    Color? fillColor,
    FillPatternType? fillPattern,
    Color? strokeColor,
    double? strokeWidth,
  }) {}

  @override
  bool shouldRepaint(SymbolRenderer oldRenderer) {
    return false; // Repainting is handled directly in Flutter.
  }
}

/// Common interface for [CustomSymbolRenderer] & [SymbolRendererCanvas] for
/// convenience for [LegendEntryLayout].
abstract class SymbolRendererBuilder {
  Widget build(
    BuildContext context, {
    Color? color,
    required Size size,
    bool enabled,
  });
}

/// The Widget which fulfills the guts of [SymbolRendererCanvas] actually
/// painting the symbol to a canvas using [CustomPainter].
class _SymbolCustomPaint extends CustomPainter {
  _SymbolCustomPaint(
      this.context, this.symbolRenderer, this.color, this.dashPattern);

  final BuildContext context;
  final SymbolRenderer symbolRenderer;
  final Color? color;
  final List<int>? dashPattern;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Rect.fromLTWH(0, 0, size.width, size.height);
    final commonColor = color;
    symbolRenderer.draw(
      canvas,
      Offset.zero,
      bounds,
      fillColor: commonColor,
      strokeColor: commonColor,
      dashPattern: dashPattern,
    );
  }

  @override
  bool shouldRepaint(_SymbolCustomPaint oldDelegate) {
    return symbolRenderer.shouldRepaint(oldDelegate.symbolRenderer);
  }
}
