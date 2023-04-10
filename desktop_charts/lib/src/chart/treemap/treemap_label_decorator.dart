// Copyright (C) 2023 Adriano Souza (adriano.souza113@gmail.com)

// Copyright 2019 the Charts project authors. Please see the AUTHORS file
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

import 'dart:math' show pi;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import '../../data/series.dart';
import '../../text_element.dart';
import '../../text_utils.dart';
import '../chart_canvas.dart';
import 'treemap_renderer_decorator.dart';
import 'treemap_renderer_element.dart';

/// Decorator that renders label for treemap renderer element.
class TreeMapLabelDecorator<D> extends TreeMapRendererDecorator<D> {
  TreeMapLabelDecorator({
    TextStyle? labelStyleSpec,
    this.labelPadding = _defaultLabelPadding,
    this.allowLabelOverflow = true,
    this.enableMultiline = false,
  }) : labelStyleSpec = labelStyleSpec ?? _defaultLabelStyle;

  // Default configuration
  static const _defaultLabelPadding = 4.0;
  static const _defaultFontSize = 12.0;
  static final _defaultLabelStyle = TextStyle(
    fontSize: _defaultFontSize,
    color: const Color(0xffffffff), // TODO black
  );

  // Rotation value of 90 degrees clockwise.
  static const _clockwise90Degree = pi / 2.0;

  /// Text style spec for labels.
  final TextStyle labelStyleSpec;

  /// Padding of the label text.
  final double labelPadding;

  /// Whether or not to allow labels to draw outside of their bounding box.
  final bool allowLabelOverflow;

  /// Whether or not drawing a label in multiple lines if there is enough
  /// space.
  final bool enableMultiline;

  @override
  void decorate(
    TreeMapRendererElement<D> rendererElement,
    Canvas canvas, {
    required Rect drawBounds,
    required double animationPercent,
    bool rtl = false,
    bool renderVertically = false,
    bool renderMultiline = false,
  }) {
    // Decorates the renderer elements when animation is completed.
    if (animationPercent != 1.0) {
      return;
    }

    final labelStyle = labelStyleSpec;

    final labelFn = rendererElement.series.labelAccessor;
    final datumIndex = rendererElement.index;
    final label = labelFn != null ? labelFn(datumIndex) : null;

    // Skips if this element has no label.
    if (label == null || label.isEmpty) {
      return;
    }

    // Uses datum specific label style if provided.
    final datumLabelStyle = _datumStyle(
      rendererElement.series.insideLabelStyleAccessor,
      datumIndex,
      defaultStyle: labelStyle,
    );

    final rect = rendererElement.boundingRect;
    final labelElement = TextElement(label)
      ..textStyle = datumLabelStyle
      ..textDirection = rtl ? TextDirection.rtl : TextDirection.ltr;
    final labelHeight = labelElement.measurement.verticalSliceWidth;
    final maxLabelHeight =
        (renderVertically ? rect.width : rect.height) - (labelPadding * 2.0);
    final maxLabelWidth =
        (renderVertically ? rect.height : rect.width) - (labelPadding * 2.0);
    final multiline = enableMultiline && renderMultiline;
    final parts = wrapLabelLines(
      labelElement,
      maxLabelWidth,
      maxLabelHeight,
      allowLabelOverflow: allowLabelOverflow,
      multiline: multiline,
    );

    for (int index = 0; index < parts.length; index += 1) {
      final segment = _createLabelSegment(
        rect,
        labelHeight,
        parts[index],
        index.toDouble(),
        rtl: rtl,
        rotate: renderVertically,
      );

      // Draws a label inside of a treemap renderer element.
      canvas.drawChartText(segment.text, segment.xOffet, segment.yOffset,
          rotation: segment.rotationAngle);
    }
  }

  /// Gets datum specific style.
  TextStyle _datumStyle(
    Accessor<TextStyle>? labelStyleFn,
    int datumIndex, {
    required TextStyle defaultStyle,
  }) {
    final styleSpec = labelStyleFn?.call(datumIndex);
    return (styleSpec != null) ? styleSpec : defaultStyle;
  }

  _TreeMapLabelSegment _createLabelSegment(
    Rect elementBoundingRect,
    double labelHeight,
    TextElement labelElement,
    double position, {
    bool rtl = false,
    bool rotate = false,
  }) {
    double xOffset;
    double yOffset;

    // Set x offset for each line.
    if (rotate) {
      xOffset = elementBoundingRect.right -
          labelPadding -
          2 * labelElement.textStyle!.fontSize! -
          labelHeight * position;
    } else if (rtl) {
      xOffset = elementBoundingRect.right - labelPadding;
    } else {
      xOffset = elementBoundingRect.left + labelPadding;
    }

    // Set y offset for each line.
    if (!rotate) {
      yOffset =
          elementBoundingRect.top + labelPadding + (labelHeight * position);
    } else if (rtl) {
      yOffset = elementBoundingRect.bottom - labelPadding;
    } else {
      yOffset = elementBoundingRect.top + labelPadding;
    }

    return _TreeMapLabelSegment(
      labelElement,
      xOffset,
      yOffset,
      rotate ? _clockwise90Degree : 0.0,
    );
  }
}

/// Represents a segment of a label that will be drawn in a single line.
@immutable
class _TreeMapLabelSegment {
  const _TreeMapLabelSegment(
    this.text,
    this.xOffet,
    this.yOffset,
    this.rotationAngle,
  );

  /// Text to be drawn on the canvas.
  final TextElement text;

  /// x-coordinate offset for [text].
  final double xOffet;

  /// y-coordinate offset for [text].
  final double yOffset;

  /// Rotation angle for drawing [text].
  final double rotationAngle;
}
