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

import 'package:flutter/rendering.dart';

import '../../data/series.dart' show Accessor;
import '../../text_element.dart' show TextElement;
import '../../theme.dart';
import '../chart_canvas.dart' show ChartCanvas;
import 'bar_renderer.dart' show ImmutableBarRendererElement;
import 'bar_renderer_decorator.dart' show BarRendererDecorator;

class BarLabelDecorator<D> extends BarRendererDecorator<D> {
  BarLabelDecorator({
    TextStyle? insideLabelStyleSpec,
    TextStyle? outsideLabelStyleSpec,
    this.labelAnchor,
    this.labelPosition = _defaultLabelPosition,
    this.labelPlacement = _defaultLabelPlacement,
    this.labelPadding = _defaultLabelPadding,
    this.labelVerticalPosition = _defaultlabelVerticalPosition,
  })  : insideLabelStyleSpec = insideLabelStyleSpec ??
            TextStyle(
              fontSize: 12.0,
              color: const ChartsThemeData.fallbackw().background,
              fontWeight: FontWeight.bold,
            ),
        outsideLabelStyleSpec = outsideLabelStyleSpec ??
            TextStyle(
              fontSize: 12,
              color: const ChartsThemeData.fallbackw().foreground,
              fontWeight: FontWeight.bold,
            );

  // Default configuration
  static const _defaultLabelPosition = BarLabelPosition.auto;
  static const _defaultLabelPadding = 5.0;
  static const _defaultLabelPlacement = BarLabelPlacement.followMeasureAxis;
  static const _defaultHorizontalLabelAnchor = BarLabelAnchor.start;
  static const _defaultVerticalLabelAnchor = BarLabelAnchor.end;
  static const _defaultlabelVerticalPosition = BarLabelVerticalPosition.middle;

  static const _labelSplitPattern = '\n';
  static const _defaultMultiLineLabelPadding = 2.0;

  /// Configures [TextStyle] for labels placed inside the bars.
  final TextStyle insideLabelStyleSpec;

  /// Configures [TextStyle] for labels placed outside the bars.
  final TextStyle outsideLabelStyleSpec;

  /// Configures where to place the label relative to the bars.
  final BarLabelPosition labelPosition;

  /// Configures where to place the label relative to the axis.
  final BarLabelPlacement labelPlacement;

  /// For labels drawn inside the bar, configures label anchor position.
  final BarLabelAnchor? labelAnchor;

  /// For labels on horizontal bars, configures the label's vertical position.
  final BarLabelVerticalPosition? labelVerticalPosition;

  /// Space before and after the label text.
  final double labelPadding;

  @override
  void decorate(
    Iterable<ImmutableBarRendererElement<D>> barElements,
    Canvas canvas,
    Offset offset, {
    required Rect drawBounds,
    required double animationPercent,
    required bool renderingVertically,
    bool rtl = false,
  }) {
    // Only decorate the bars when animation is at 100%.
    if (animationPercent != 1.0) {
      return;
    }

    if (renderingVertically) {
      _decorateVerticalBars(barElements, canvas, offset, drawBounds, rtl);
    } else {
      _decorateHorizontalBars(barElements, canvas, offset, drawBounds, rtl);
    }
  }

  void _decorateVerticalBars(
    Iterable<ImmutableBarRendererElement<D>> barElements,
    Canvas canvas,
    Offset offset,
    Rect drawBounds,
    bool rtl,
  ) {
    // Create [TextStyle] from [TextStyle] to be used by all the elements.
    final insideLabelStyle = insideLabelStyleSpec;
    final outsideLabelStyle = outsideLabelStyleSpec;

    for (final element in barElements) {
      final labelFn = element.series!.labelAccessor;
      final measureFn = element.series!.measureFn;
      final datumIndex = element.index;
      final label = labelFn?.call(datumIndex);
      final measure = measureFn(datumIndex) ?? 0.0;

      // If there are custom styles, use that instead of the default or the
      // style defined for the entire decorator.
      final datumInsideLabelStyle = _getDatumStyle(
        element.series!.insideLabelStyleAccessor,
        datumIndex,
        defaultStyle: insideLabelStyle,
      );
      final datumOutsideLabelStyle = _getDatumStyle(
        element.series!.outsideLabelStyleAccessor,
        datumIndex,
        defaultStyle: outsideLabelStyle,
      );

      // Skip calculation and drawing for this element if no label.
      if (label == null || label.isEmpty) {
        continue;
      }

      var labelElements = label
          .split(_labelSplitPattern)
          .map((labelPart) => TextElement(labelPart));

      final bounds = element.bounds!;

      // Get space available inside and outside the bar.
      final totalPadding = labelPadding * 2;
      final insideBarHeight = bounds.height - totalPadding;

      BarLabelPosition calculatedLabelPosition = labelPosition;
      if (calculatedLabelPosition == BarLabelPosition.auto) {
        // For auto, first try to fit the text inside the bar.
        labelElements = labelElements.map(
            (labelElement) => labelElement..textStyle = datumInsideLabelStyle);

        final labelMaxWidth = labelElements
            .map(
                (labelElement) => labelElement.measurement.horizontalSliceWidth)
            .fold<double>(0, (max, current) => max > current ? max : current);

        // Total label height depends on the label element's text style.
        final totalLabelHeight = _getTotalLabelHeight(labelElements);

        // A label fits if the length and width of the text fits.
        calculatedLabelPosition =
            totalLabelHeight < insideBarHeight && labelMaxWidth < bounds.width
                ? BarLabelPosition.inside
                : BarLabelPosition.outside;
      }

      // Set the max width, text style, and text direction.
      labelElements = labelElements.map(
        (labelElement) => labelElement
          ..textStyle = calculatedLabelPosition == BarLabelPosition.inside
              ? datumInsideLabelStyle
              : datumOutsideLabelStyle
          ..maxWidth = bounds.width
          ..textDirection = rtl ? TextDirection.rtl : TextDirection.ltr,
      );

      // Total label height depends on the label element's text style.
      final totalLabelHeight = _getTotalLabelHeight(labelElements);

      int labelsDrawn = 0;
      for (final labelElement in labelElements) {
        // Calculate the start position of label based on [labelAnchor].
        final double labelY;
        final double labelHeight =
            labelElement.measurement.verticalSliceWidth.roundToDouble();
        final double offsetHeight =
            (labelHeight + _defaultMultiLineLabelPadding) * labelsDrawn;

        if (calculatedLabelPosition == BarLabelPosition.inside) {
          final anchor = _resolveLabelAnchor(
              measure, labelAnchor ?? _defaultVerticalLabelAnchor);
          switch (anchor) {
            case BarLabelAnchor.end:
              labelY = bounds.top + labelPadding + offsetHeight;
              break;
            case BarLabelAnchor.middle:
              labelY = (bounds.bottom -
                      bounds.height / 2.0 -
                      totalLabelHeight / 2.0 +
                      offsetHeight)
                  .roundToDouble();
              break;
            case BarLabelAnchor.start:
              labelY = bounds.bottom -
                  labelPadding -
                  totalLabelHeight +
                  offsetHeight;
              break;
          }
        } else {
          // calculatedLabelPosition == LabelPosition.outside
          if (measure < 0 &&
              labelPlacement == BarLabelPlacement.opposeAxisBaseline) {
            labelY = bounds.bottom + labelPadding + offsetHeight;
          } else {
            labelY =
                bounds.top - labelPadding - totalLabelHeight + offsetHeight;
          }
        }

        // Center the label inside the bar.
        final labelX = (bounds.left +
                bounds.width / 2 -
                labelElement.measurement.horizontalSliceWidth / 2.0)
            .roundToDouble();

        canvas.drawChartText(offset, labelElement, labelX, labelY);
        labelsDrawn += 1;
      }
    }
  }

  void _decorateHorizontalBars(
    Iterable<ImmutableBarRendererElement<D>> barElements,
    Canvas canvas,
    Offset offset,
    Rect drawBounds,
    bool rtl,
  ) {
    // Create [TextStyle] from [TextStyle] to be used by all the elements.
    final insideLabelStyle = insideLabelStyleSpec;
    final outsideLabelStyle = outsideLabelStyleSpec;

    for (final element in barElements) {
      final labelFn = element.series!.labelAccessor;
      final measureFn = element.series!.measureFn;
      final datumIndex = element.index;
      final label = labelFn?.call(datumIndex);
      final measure = measureFn(datumIndex) ?? 0.0;

      // If there are custom styles, use that instead of the default or the
      // style defined for the entire decorator.
      final datumInsideLabelStyle = _getDatumStyle(
        element.series!.insideLabelStyleAccessor,
        datumIndex,
        defaultStyle: insideLabelStyle,
      );
      final datumOutsideLabelStyle = _getDatumStyle(
        element.series!.outsideLabelStyleAccessor,
        datumIndex,
        defaultStyle: outsideLabelStyle,
      );

      // Skip calculation and drawing for this element if no label.
      if (label == null || label.isEmpty) {
        continue;
      }

      final bounds = element.bounds!;

      // Get space available inside and outside the bar.
      final totalPadding = labelPadding * 2;
      final insideBarWidth = bounds.width - totalPadding;
      final outsideBarWidth = drawBounds.width - bounds.width - totalPadding;

      final labelElement = TextElement(label);
      BarLabelPosition calculatedLabelPosition = labelPosition;

      if (calculatedLabelPosition == BarLabelPosition.auto) {
        // For auto, first try to fit the text inside the bar.
        labelElement.textStyle = datumInsideLabelStyle;

        // A label fits if the space inside the bar is >= outside bar or if the
        // length of the text fits and the space. This is because if the bar has
        // more space than the outside, it makes more sense to place the label
        // inside the bar, even if the entire label does not fit.
        calculatedLabelPosition = (insideBarWidth >= outsideBarWidth ||
                labelElement.measurement.horizontalSliceWidth < insideBarWidth)
            ? BarLabelPosition.inside
            : BarLabelPosition.outside;
      }

      // Set the max width and text style.
      if (calculatedLabelPosition == BarLabelPosition.inside) {
        labelElement.textStyle = datumInsideLabelStyle;
        labelElement.maxWidth = insideBarWidth;
      } else {
        // this block for...
        // calculatedLabelPosition == LabelPosition.outside ||
        // calculatedLabelPosition == LabelPosition.right
        labelElement.textStyle = datumOutsideLabelStyle;
        labelElement.maxWidth = outsideBarWidth;
      }

      // Only calculate and draw label if there's actually space for the label.
      if ((labelElement.maxWidth! < 0 ||
              (labelElement.maxWidthStrategy == null &&
                  labelElement.measurement.horizontalSliceWidth >
                      labelElement.maxWidth!)) &&
          labelVerticalPosition != BarLabelVerticalPosition.top) {
        return;
      }

      // Calculate the start position of label based on [labelAnchor].
      final double labelX;
      if (calculatedLabelPosition == BarLabelPosition.inside) {
        final anchor = _resolveLabelAnchor(
            measure, labelAnchor ?? _defaultHorizontalLabelAnchor);

        switch (anchor) {
          case BarLabelAnchor.middle:
            labelX = (bounds.left +
                    bounds.width / 2.0 -
                    labelElement.measurement.horizontalSliceWidth / 2.0)
                .roundToDouble();
            labelElement.textDirection =
                rtl ? TextDirection.rtl : TextDirection.ltr;
            break;

          case BarLabelAnchor.end:
          case BarLabelAnchor.start:
            final alignLeft = rtl
                ? (anchor == BarLabelAnchor.end)
                : (anchor == BarLabelAnchor.start);

            if (alignLeft) {
              labelX = bounds.left + labelPadding;
              labelElement.textDirection = TextDirection.ltr;
            } else {
              labelX = bounds.right - labelPadding;
              labelElement.textDirection = TextDirection.rtl;
            }
            break;
        }
      } else if (calculatedLabelPosition == BarLabelPosition.outside) {
        if (measure < 0 &&
            labelPlacement == BarLabelPlacement.opposeAxisBaseline) {
          labelX = bounds.left - labelPadding;
          labelElement.textDirection = TextDirection.rtl;
        } else {
          labelX = bounds.right + labelPadding;
          labelElement.textDirection = TextDirection.ltr;
        }
      } else {
        // calculatedLabelPosition == BarLabelPosition.right
        if (measure < 0) {
          labelX =
              (bounds.right - labelElement.measurement.horizontalSliceWidth)
                  .roundToDouble();
        } else {
          labelX = (bounds.left +
                  drawBounds.width -
                  labelElement.measurement.horizontalSliceWidth)
              .roundToDouble();
        }
      }

      // Calculate label's y position based on BarLabelVerticalPosition.
      final double labelY;

      if (labelVerticalPosition == BarLabelVerticalPosition.middle) {
        // Center the label inside the bar.
        labelY = (bounds.top +
                (bounds.bottom - bounds.top) / 2 -
                labelElement.measurement.verticalSliceWidth / 2)
            .roundToDouble();
      } else {
        /// labelVerticalPosition == BarLabelVerticalPosition.top
        labelY = (bounds.top -
                labelElement.measurement.verticalSliceWidth -
                labelPadding)
            .roundToDouble();
      }

      canvas.drawChartText(offset, labelElement, labelX, labelY);
    }
  }

  /// Helper function to get the total height for a group of labels.
  /// This includes the padding in between the labels.
  double _getTotalLabelHeight(Iterable<TextElement> labelElements) =>
      (labelElements.first.measurement.verticalSliceWidth *
              labelElements.length)
          .round() +
      _defaultMultiLineLabelPadding * (labelElements.length - 1);

  /// Helper function to get datum specific style
  TextStyle _getDatumStyle(
    Accessor<TextStyle>? labelFn,
    int? datumIndex, {
    required TextStyle defaultStyle,
  }) {
    final styleSpec = labelFn?.call(datumIndex);
    return styleSpec ?? defaultStyle;
  }

  /// Helper function to get the bar label anchor when [BarLabelPosition] is
  /// inside.
  BarLabelAnchor _resolveLabelAnchor(num measure, BarLabelAnchor anchor) {
    if (labelPlacement == BarLabelPlacement.opposeAxisBaseline) {
      if (measure >= 0) {
        return anchor;
      }
      if (anchor == BarLabelAnchor.start) {
        return BarLabelAnchor.end;
      }
      if (anchor == BarLabelAnchor.end) {
        return BarLabelAnchor.start;
      }
      return anchor;
    }
    return anchor;
  }
}

/// Configures where to place the label relative to the bars.
enum BarLabelPosition {
  /// Automatically try to place the label inside the bar first and place it on
  /// the outside of the space available outside the bar is greater than space
  /// available inside the bar.
  auto,

  /// Always place label on the outside.
  outside,

  /// Always place label on the inside.
  inside,

  /// Right align the label with the horizontal bars. The label will be inside
  /// or above the bar based on the BarLabelVerticalPosition.
  right,
}

/// Configures where to place the label relative to the axis.
enum BarLabelPlacement {
  /// Places the label with respect to the increase in measure axis units. The
  /// bar end is the most positive position along the axis.
  ///
  /// This is the default placement.
  followMeasureAxis,

  /// Places the label with respect to the zero baseline. The bar end is the
  /// absolute value always from the zero baseline.
  opposeAxisBaseline,
}

/// Configures where to anchor the label for labels drawn inside the bars.
enum BarLabelAnchor {
  /// Anchor to the measure start.
  start,

  /// Anchor to the middle of the measure range.
  middle,

  /// Anchor to the measure end.
  end,
}

/// Configures where to place labels vertically on horizontal bars.
enum BarLabelVerticalPosition {
  /// Anchors label to be on top of bar
  top,

  /// Anchors label to be inline with bar
  middle,
}
