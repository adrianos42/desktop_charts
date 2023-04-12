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

import 'dart:ui' show TextDirection, TextBaseline;

import 'package:flutter/painting.dart' show TextPainter, TextSpan, TextStyle;

import 'text_measurement.dart' show TextMeasurement;

/// Interface for accessing text measurement and painter.
class TextElement {
  TextElement(
    this.text, {
    TextStyle? style,
    this.textScaleFactor,
  }) : _textStyle = style;

  TextElement withText(String text) {
    return TextElement(
      text,
      style: _textStyle,
      textScaleFactor: textScaleFactor,
    )
      .._maxWidth = _maxWidth
      .._maxWidthStrategy = _maxWidthStrategy
      .._opacity = _opacity
      .._textDirection = _textDirection
      .._textStyle = _textStyle
      .._painterReady = false;
  }

  /// The [TextStyle] of this [TextElement].
  TextStyle? get textStyle => _textStyle;
  set textStyle(TextStyle? value) {
    if (_textStyle == value) {
      return;
    }
    _textStyle = value;
    _painterReady = false;
  }

  /// The max width of this [TextElement] during measure and layout.
  ///
  /// If the text exceeds maxWidth, the [maxWidthStrategy] is used.
  double? get maxWidth => _maxWidth;

  set maxWidth(double? value) {
    if (_maxWidth == value) {
      return;
    }
    _maxWidth = value;
    _painterReady = false;
  }

  /// The strategy to use if this [TextElement] exceeds the [maxWidth].
  MaxWidthStrategy? get maxWidthStrategy => _maxWidthStrategy;

  set maxWidthStrategy(MaxWidthStrategy? maxWidthStrategy) {
    if (_maxWidthStrategy == maxWidthStrategy) {
      return;
    }
    _maxWidthStrategy = maxWidthStrategy;
    _painterReady = false;
  }

  /// The opacity of this element, in addition to the alpha set on the color
  /// of this element.
  set opacity(double? value) {
    if (value != _opacity) {
      _painterReady = false;
      _opacity = value;
    }
  }

  double get opacity => _opacity ?? 1.0;

  // The text of this [TextElement].
  final String text;

  final double? textScaleFactor;

  /// Will return the [maxWidth] if set and the actual text width is larger.
  TextMeasurement get measurement {
    if (!_painterReady) {
      _refreshPainter();
    }

    return _measurement;
  }

  /// The direction to render the text relative to the coordinate.
  TextDirection? get textDirection => _textDirection;
  set textDirection(TextDirection? direction) {
    if (_textDirection == direction) {
      return;
    }
    _textDirection = direction;
    _painterReady = false;
  }

  /// Return true if settings are all the same.
  ///
  /// Purposely excludes measurement because the measurement will request the
  /// native [TextElement] to layout, which is expensive. We want to avoid the
  /// layout by comparing with another [TextElement] to see if they have the
  /// same settings.
  static bool elementSettingsSame(TextElement a, TextElement b) {
    return a.textStyle == b.textStyle &&
        a.maxWidth == b.maxWidth &&
        a.maxWidthStrategy == b.maxWidthStrategy &&
        a.text == b.text &&
        a.textDirection == b.textDirection;
  }

  static const ellipsis = '\u{2026}';

  bool _painterReady = false;
  TextStyle? _textStyle;
  TextDirection? _textDirection;

  double? _maxWidth;
  MaxWidthStrategy? _maxWidthStrategy;

  late TextPainter _textPainter;

  late TextMeasurement _measurement;

  double? _opacity;

  /// The estimated distance between where we asked to draw the text (top, left)
  /// and where it visually started (top + verticalFontShift, left).
  ///
  /// 10% of reported font height seems to be about right.
  int get verticalFontShift {
    if (!_painterReady) {
      _refreshPainter();
    }

    return (_textPainter.height * 0.1).ceil();
  }

  TextPainter? get textPainter {
    if (!_painterReady) {
      _refreshPainter();
    }
    return _textPainter;
  }

  /// Create text painter and measure based on current settings
  void _refreshPainter() {
    final color = textStyle?.color;

    _textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color?.withOpacity(opacity),
          fontSize: textStyle?.fontSize?.toDouble(),
          fontFamily: textStyle?.fontFamily,
          height: textStyle?.height,
        ),
      ),
    )
      ..textDirection = textDirection ?? TextDirection.ltr
      ..ellipsis =
          maxWidthStrategy == MaxWidthStrategy.ellipsize ? ellipsis : null;

    if (textScaleFactor != null) {
      _textPainter.textScaleFactor = textScaleFactor!;
    }

    final rMaxWidth = maxWidth ?? double.infinity;

    _textPainter.layout(maxWidth: rMaxWidth.clamp(0.0, double.infinity));

    final baseline =
        _textPainter.computeDistanceToActualBaseline(TextBaseline.alphabetic);

    // Estimating the actual draw height to 70% of measures size.
    //
    // The font reports a size larger than the drawn size, which makes it
    // difficult to shift the text around to get it to visually line up
    // vertically with other components.
    _measurement = TextMeasurement(
      horizontalSliceWidth: _textPainter.width,
      verticalSliceWidth: _textPainter.height * 0.70,
      baseline: baseline,
    );

    _painterReady = true;
  }
}

/// The strategy to use if a [TextElement] exceeds the [maxWidth].
enum MaxWidthStrategy {
  truncate,
  ellipsize,
}
