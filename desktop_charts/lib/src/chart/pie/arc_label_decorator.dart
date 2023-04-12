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

import 'dart:math' show cos, min, sin, pi;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import '../../data/series.dart' show Accessor;
import '../../text_element.dart' show MaxWidthStrategy, TextElement;
import '../../theme.dart';
import '../chart_canvas.dart' show ChartCanvas;
import 'arc_renderer_decorator.dart' show ArcRendererDecorator;
import 'arc_renderer_element.dart' show ArcRendererElement, ArcRendererElements;

/// Renders labels for arc renderers.
///
/// This decorator performs very basic label collision detection. If the y
/// position of a label positioned outside collides with the previously drawn
/// label (on the same side of the chart), then that label will be skipped.
class ArcLabelDecorator<D> extends ArcRendererDecorator<D> {
  ArcLabelDecorator({
    TextStyle? insideLabelStyleSpec,
    TextStyle? outsideLabelStyleSpec,
    ArcLabelLeaderLineStyleSpec? leaderLineStyleSpec,
    this.labelPosition = _defaultLabelPosition,
    this.labelPadding = _defaultLabelPadding,
    this.showLeaderLines = _defaultShowLeaderLines,
  })  : insideLabelStyleSpec = insideLabelStyleSpec ?? _defaultInsideLabelStyle,
        outsideLabelStyleSpec =
            outsideLabelStyleSpec ?? _defaultOutsideLabelStyle,
        leaderLineStyleSpec = leaderLineStyleSpec ??
            ArcLabelLeaderLineStyleSpec(
              length: 20.0,
              thickness: 1.0,
              color:
                  const ChartsThemeData.fallbackw().arcLabelOutsideLeaderLine,
            );

  // Default configuration
  static const _defaultLabelPosition = ArcLabelPosition.auto;
  static const _defaultLabelPadding = 4.0;

  static final _defaultInsideLabelStyle = TextStyle(
    fontSize: 12,
    color: const Color(0xff000000), // TODO white
    fontWeight: FontWeight.bold,
  );
  static final _defaultOutsideLabelStyle = TextStyle(
    fontSize: 12,
    color: const Color(0xffffffff), // TODO black
    fontWeight: FontWeight.bold,
  );

  static const _defaultShowLeaderLines = true;

  /// Configures [TextStyle] for labels placed inside the arcs.
  final TextStyle insideLabelStyleSpec;

  /// Configures [TextStyle] for labels placed outside the arcs.
  final TextStyle outsideLabelStyleSpec;

  /// Configures [ArcLabelLeaderLineStyleSpec] for leader lines for labels
  /// placed outside the arcs.
  final ArcLabelLeaderLineStyleSpec leaderLineStyleSpec;

  /// Configures where to place the label relative to the arcs.
  final ArcLabelPosition labelPosition;

  /// Space before and after the label text.
  final double labelPadding;

  /// Whether or not to draw leader lines for labels placed outside the arcs.
  final bool showLeaderLines;

  /// Render the labels on top of series data.
  @override
  final bool renderAbove = true;

  /// fields for collision detection.
  double? _previousOutsideLabelY;
  bool? _previousLabelLeftOfChart;

  @override
  void decorate(
    List<ArcRendererElements<D>> arcElementsList,
    Canvas canvas,
    Offset offset, {
    required Rect drawBounds,
    required double animationPercent,
    bool rtl = false,
  }) {
    // Only decorate the arcs when animation is at 100%.
    if (animationPercent != 1.0) {
      return;
    }

    final insideLabelStyle = insideLabelStyleSpec;
    final outsideLabelStyle = outsideLabelStyleSpec;

    // Track the Y position of the previous outside label for collision
    // detection purposes.
    for (final arcElements in arcElementsList) {
      _previousOutsideLabelY = null;
      _previousLabelLeftOfChart = null;

      for (final element in arcElements.arcs) {
        final labelFn = element.series.labelAccessor;
        final datumIndex = element.index;
        final label = (labelFn != null) ? labelFn(datumIndex) : null;

        // If there are custom styles, use that instead of the default or the
        // style defined for the entire decorator.
        final datumInsideLabelStyle = _getDatumStyle(
          element.series.insideLabelStyleAccessor,
          datumIndex,
          defaultStyle: insideLabelStyle,
        );
        final datumOutsideLabelStyle = _getDatumStyle(
          element.series.outsideLabelStyleAccessor,
          datumIndex,
          defaultStyle: outsideLabelStyle,
        );

        // Skip calculation and drawing for this element if no label.
        if (label == null || label.isEmpty) {
          continue;
        }

        final arcAngle = element.endAngle - element.startAngle;

        final centerAngle = element.startAngle + (arcAngle / 2.0);

        final centerRadius = arcElements.innerRadius +
            ((arcElements.radius - arcElements.innerRadius) / 2.0);

        final outerPoint = Offset(
          arcElements.center.dx + arcElements.radius * cos(centerAngle),
          arcElements.center.dy + arcElements.radius * sin(centerAngle),
        );

        final bounds = Rect.fromPoints(arcElements.center, outerPoint);

        // Get space available inside and outside the arc.
        final totalPadding = labelPadding * 2.0;
        final insideArcWidth = min(
                (((arcAngle * 180.0 / pi) / 360.0) * (2.0 * pi * centerRadius))
                    .round(),
                (arcElements.radius - arcElements.innerRadius) - labelPadding)
            .roundToDouble();

        final leaderLineLength =
            showLeaderLines ? leaderLineStyleSpec.length : 0;

        final outsideArcWidth = ((drawBounds.width / 2.0) -
                bounds.width -
                totalPadding -
                // Half of the leader line is drawn inside the arc
                leaderLineLength / 2.0)
            .roundToDouble();

        final labelElement = TextElement(label)
          ..maxWidthStrategy = MaxWidthStrategy.ellipsize;

        final calculatedLabelPosition = calculateLabelPosition(
          labelElement,
          datumInsideLabelStyle,
          insideArcWidth,
          outsideArcWidth,
          element,
          labelPosition,
        );

        // Set the max width and text style.
        if (calculatedLabelPosition == ArcLabelPosition.inside) {
          labelElement.textStyle = datumInsideLabelStyle;
          labelElement.maxWidth = insideArcWidth;
        } else {
          // calculatedLabelPosition == LabelPosition.outside
          labelElement.textStyle = datumOutsideLabelStyle;
          labelElement.maxWidth = outsideArcWidth;
        }

        // Only calculate and draw label if there's actually space for the
        // label.
        if (labelElement.maxWidth! > 0.0) {
          // Calculate the start position of label based on [labelAnchor].
          if (calculatedLabelPosition == ArcLabelPosition.inside) {
            _drawInsideLabel(
                canvas, offset, arcElements, labelElement, centerAngle);
          } else {
            final l = _drawOutsideLabel(
              canvas,
              offset,
              drawBounds,
              arcElements,
              labelElement,
              centerAngle,
            );

            if (l != null) {
              updateCollisionDetectionParams(l);
            }
          }
        }
      }
    }
  }

  @protected
  ArcLabelPosition calculateLabelPosition(
    TextElement labelElement,
    TextStyle labelStyle,
    double insideArcWidth,
    double outsideArcWidth,
    ArcRendererElement<D> arcRendererElement,
    ArcLabelPosition labelPosition,
  ) {
    if (labelPosition == ArcLabelPosition.auto) {
      // For auto, first try to fit the text inside the arc.
      labelElement.textStyle = labelStyle;

      // A label fits if the space inside the arc is >= outside arc or if the
      // length of the text fits and the space. This is because if the arc has
      // more space than the outside, it makes more sense to place the label
      // inside the arc, even if the entire label does not fit.
      return (insideArcWidth >= outsideArcWidth ||
              labelElement.measurement.horizontalSliceWidth < insideArcWidth)
          ? ArcLabelPosition.inside
          : ArcLabelPosition.outside;
    } else {
      return labelPosition;
    }
  }

  /// Helper function to get datum specific style
  TextStyle _getDatumStyle(
    Accessor<TextStyle>? labelFn,
    int? datumIndex, {
    required TextStyle defaultStyle,
  }) {
    final styleSpec = (labelFn != null) ? labelFn(datumIndex) : null;
    return (styleSpec != null) ? styleSpec : defaultStyle;
  }

  /// Draws a label inside of an arc.
  void _drawInsideLabel(
    Canvas canvas,
    Offset offset,
    ArcRendererElements<D> arcElements,
    TextElement labelElement,
    double centerAngle,
  ) {
    // Center the label inside the arc.
    final labelRadius = arcElements.innerRadius +
        (arcElements.radius - arcElements.innerRadius) / 2.0;

    final labelX = (arcElements.center.dx + labelRadius * cos(centerAngle))
        .roundToDouble();

    final labelY = (arcElements.center.dy +
            labelRadius * sin(centerAngle) -
            insideLabelStyleSpec.fontSize! / 2.0)
        .truncateToDouble();

    labelElement.textDirection = null;

    canvas.drawChartText(offset, labelElement, labelX, labelY);
  }

  @protected
  void updateCollisionDetectionParams(List<Object> params) {
    // List destructuring.
    _previousLabelLeftOfChart = params[0] as bool;
    _previousOutsideLabelY = params[1] as double;
  }

  double getLabelRadius(ArcRendererElements<D> arcElements) =>
      arcElements.radius + leaderLineStyleSpec.length / 2.0;

  /// Draws a label outside of an arc.
  List<Object>? _drawOutsideLabel(
    Canvas canvas,
    Offset offset,
    Rect drawBounds,
    ArcRendererElements<D> arcElements,
    TextElement labelElement,
    double centerAngle,
  ) {
    final labelRadius = getLabelRadius(arcElements);

    final labelPoint = Offset(
      arcElements.center.dx + labelRadius * cos(centerAngle),
      arcElements.center.dy + labelRadius * sin(centerAngle),
    );

    // Use the label's chart quadrant to determine whether it's rendered to the
    // right or left.
    final centerAbs = centerAngle.abs() % (2 * pi);
    final labelLeftOfChart = pi / 2 < centerAbs && centerAbs < pi * 3 / 2;

    // Shift the label horizontally away from the center of the chart.
    double labelX = labelLeftOfChart
        ? (labelPoint.dx - labelPadding).truncateToDouble()
        : (labelPoint.dx + labelPadding).truncateToDouble();

    // Shift the label up by the size of the font.
    final labelY =
        (labelPoint.dy - outsideLabelStyleSpec.fontSize! / 2.0).roundToDouble();

    // Outside labels should flow away from the center of the chart
    labelElement.textDirection =
        labelLeftOfChart ? TextDirection.rtl : TextDirection.ltr;

    // Skip this label if it collides with the previously drawn label.
    if (detectOutsideLabelCollision(labelY, labelLeftOfChart,
        _previousOutsideLabelY, _previousLabelLeftOfChart)) {
      return null;
    }

    if (showLeaderLines) {
      final tailX = _drawLeaderLine(
        canvas,
        offset,
        labelLeftOfChart,
        labelPoint,
        arcElements.radius,
        arcElements.center,
        centerAngle,
      );

      // Shift the label horizontally by the length of the leader line.
      labelX = (labelX + tailX).truncateToDouble();

      labelElement.maxWidth =
          (labelElement.maxWidth! - tailX.abs()).truncateToDouble();
    }

    canvas.drawChartText(offset, labelElement, labelX, labelY);

    // Return a structured list of values.
    return [labelLeftOfChart, labelY];
  }

  /// Detects whether the current outside label collides with the previous label.
  @protected
  bool detectOutsideLabelCollision(
    double labelY,
    bool labelLeftOfChart,
    double? previousOutsideLabelY,
    bool? previousLabelLeftOfChart,
  ) {
    bool collides = false;

    // Given that labels are vertically centered, we can assume they will
    // collide if the current label's Y coordinate +/- the font size
    // crosses past the Y coordinate of the previous label drawn on the
    // same side of the chart.
    if (previousOutsideLabelY != null &&
        labelLeftOfChart == previousLabelLeftOfChart) {
      if (labelY > previousOutsideLabelY) {
        if (labelY - outsideLabelStyleSpec.fontSize! <= previousOutsideLabelY) {
          collides = true;
        }
      } else {
        if (labelY + outsideLabelStyleSpec.fontSize! >= previousOutsideLabelY) {
          collides = true;
        }
      }
    }

    return collides;
  }

  /// Draws a leader line for the current arc.
  double _drawLeaderLine(
    Canvas canvas,
    Offset offset,
    bool labelLeftOfChart,
    Offset labelPoint,
    double radius,
    Offset arcCenterPoint,
    double centerAngle,
  ) {
    final tailX = (labelLeftOfChart ? -1 : 1) * leaderLineStyleSpec.length;

    final leaderLineTailPoint = Offset(labelPoint.dx + tailX, labelPoint.dy);

    final centerRadius = radius - leaderLineStyleSpec.length / 2;
    final leaderLineStartPoint = Offset(
        arcCenterPoint.dx + centerRadius * cos(centerAngle),
        arcCenterPoint.dy + centerRadius * sin(centerAngle));

    canvas.drawChartLine(offset,
        points: [
          leaderLineStartPoint,
          labelPoint,
          leaderLineTailPoint,
        ],
        stroke: leaderLineStyleSpec.color,
        strokeWidth: leaderLineStyleSpec.thickness);

    return tailX;
  }
}

/// Configures where to place the label relative to the arcs.
enum ArcLabelPosition {
  /// Automatically try to place the label inside the arc first and place it on
  /// the outside of the space available outside the arc is greater than space
  /// available inside the arc.
  auto,

  /// Always place label on the outside.
  outside,

  /// Always place label on the inside.
  inside
}

/// Style configuration for leader lines.
@immutable
class ArcLabelLeaderLineStyleSpec {
  const ArcLabelLeaderLineStyleSpec({
    required this.color,
    required this.length,
    required this.thickness,
  });

  final Color color;
  final double length;
  final double thickness;

  @override
  bool operator ==(Object other) {
    return other is ArcLabelLeaderLineStyleSpec &&
        color == other.color &&
        thickness == other.thickness &&
        length == other.length;
  }

  @override
  int get hashCode => Object.hash(color, thickness, length);
}
