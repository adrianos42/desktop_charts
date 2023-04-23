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

import 'package:desktop/desktop.dart';
import 'package:flutter/rendering.dart';

import '../../../text_element.dart' show MaxWidthStrategy, TextElement;
import '../../../theme.dart';
import '../../base_chart.dart'
    show BaseChartState, LifecycleListener, BaseChart;
import '../../chart_canvas.dart' show ChartCanvas;
import '../chart_behavior.dart'
    show
        BehaviorPosition,
        ChartBehavior,
        OutsideJustification,
        ChartBehaviorState;

const _defaultBehaviorPosition = BehaviorPosition.top;
const _defaultMaxWidthStrategy = MaxWidthStrategy.ellipsize;
const _defaultTitleDirection = ChartTitleDirection.auto;
const _defaultTitleOutsideJustification = OutsideJustification.middle;
const _defaultInnerPadding = 8.0;
const _defaultTitlePadding = 16.0;
const _defaultOuterPadding = 12.0;

/// Chart behavior that adds title text to a chart. An optional second line of
/// text may be rendered as a sub-title.
///
/// Titles will by default be rendered as the outermost component in the chart
/// margin.
@immutable
class ChartTitle<D> extends ChartBehavior<D> {
  const ChartTitle(
    this.title, {
    this.titleStyle,
    this.subtitle,
    this.subtitleStyle,
    this.layoutMinSize,
    this.layoutPreferredSize,
    BehaviorPosition position = _defaultBehaviorPosition,
    this.maxWidthStrategy = _defaultMaxWidthStrategy,
    this.titleDirection = _defaultTitleDirection,
    OutsideJustification titleOutsideJustification =
        _defaultTitleOutsideJustification,
    this.innerPadding = _defaultInnerPadding,
    this.titlePadding = _defaultTitlePadding,
    this.outerPadding = _defaultOuterPadding,
  })  : _position = position,
        _titleOutsideJustification = titleOutsideJustification;

  /// Minimum size of the legend component. Optional.
  ///
  /// If the legend is positioned in the top or bottom margin, then this
  /// configures the legend's height. If positioned in the start or end
  /// position, this configures the legend's width.
  final double? layoutMinSize;

  /// Preferred size of the legend component. Defaults to 0.
  ///
  /// If the legend is positioned in the top or bottom margin, then this
  /// configures the legend's height. If positioned in the start or end
  /// position, this configures the legend's width.
  final double? layoutPreferredSize;

  /// Strategy for handling title text that is too large to fit. Defaults to
  /// truncating the text with ellipses.
  final MaxWidthStrategy maxWidthStrategy;

  /// Primary text for the title.
  final String title;

  /// Direction of the chart title text.
  ///
  /// This defaults to horizontal for a title in the top or bottom
  /// [behaviorPosition], or vertical for start or end [behaviorPosition].
  final ChartTitleDirection titleDirection;

  final OutsideJustification _titleOutsideJustification;

  /// Justification of the title text if it is positioned outside of the draw
  /// area.
  @override
  OutsideJustification get outsideJustification => _titleOutsideJustification;

  /// Style of the [title] text.
  final TextStyle? titleStyle;

  /// Secondary text for the sub-title.
  ///
  /// [subtitle] is rendered on a second line below the [title], and may be
  /// styled differently.
  final String? subtitle;

  /// Style of the [subtitle] text.
  final TextStyle? subtitleStyle;

  /// Space between the "inside" of the chart, and the title behavior itself.
  ///
  /// This padding is applied to all the edge of the title that is in the
  /// direction of the draw area. For a top positioned title, this is applied
  /// to the bottom edge. [outerPadding] is applied to the top, left, and right
  /// edges.
  ///
  /// If a sub-title is defined, this is the space between the sub-title text
  /// and the inside of the chart. Otherwise, it is the space between the title
  /// text and the inside of chart.
  final double innerPadding;

  /// Space between the title and sub-title text, if defined.
  ///
  /// This padding is not used if no sub-title is provided.
  final double titlePadding;

  /// Space between the "outside" of the chart, and the title behavior itself.
  ///
  /// This padding is applied to all 3 edges of the title that are not in the
  /// direction of the draw area. For a top positioned title, this is applied
  /// to the top, left, and right edges. [innerPadding] is applied to the
  /// bottom edge.
  final double outerPadding;

  final BehaviorPosition _position;

  @override
  BehaviorPosition get position => _position;
// TODO    return layoutPosition(
//        _config.behaviorPosition, _config.titleOutsideJustification, isRtl);

  @override
  String get role => 'ChartTitle-$position';

  @override
  ChartBehaviorState<D, S, ChartTitle<D>> build<S extends BaseChart<D>>({
    required BaseChartState<D, S> chartState,
  }) {
    return _ChartTitleState<D, S>(
      behavior: this,
      chartState: chartState,
    );
  }
}

class _ChartTitleState<D, S extends BaseChart<D>>
    extends ChartBehaviorState<D, S, ChartTitle<D>> {
  _ChartTitleState({
    required super.behavior,
    required super.chartState,
  });

  @override
  Widget buildBehaviorWidget(BuildContext context) {
    return _ChartTitleRenderObjectWidget(
      behavior: behavior,
      chartState: chartState,
      subtitleStyle: behavior.subtitleStyle ??
          Theme.of(context).textTheme.subtitle, // TODO theme
      titleStyle: behavior.titleStyle ??
          Theme.of(context).textTheme.title, // TODO theme
    );
  }
}

class _ChartTitleRenderObjectWidget<D> extends LeafRenderObjectWidget {
  /// Constructs a [ChartTitle].
  ///
  /// [title] contains the text for the chart title.
  const _ChartTitleRenderObjectWidget({
    required this.behavior,
    required this.titleStyle,
    required this.subtitleStyle,
    required this.chartState,
    super.key,
  });

  final BaseChartState<D, BaseChart<D>> chartState;
  final ChartTitle<D> behavior;
  final TextStyle titleStyle;
  final TextStyle subtitleStyle;

  @override
  _ChartTitleRender<D> createRenderObject(BuildContext context) =>
      _ChartTitleRender<D>(
        chartState: chartState,
        behavior: behavior,
        subtitleStyle: subtitleStyle,
        titleStyle: titleStyle,
      );

  @override
  void updateRenderObject(
      BuildContext context, _ChartTitleRender<D> renderObject) {
    renderObject
      ..titleStyle = titleStyle
      ..subtitleStyle = subtitleStyle
      ..behavior = behavior;
  }
}

/// Layout view component for [ChartTitle].
class _ChartTitleRender<D> extends RenderBox {
  _ChartTitleRender({
    required ChartTitle<D> behavior,
    required TextStyle titleStyle,
    required TextStyle subtitleStyle,
    required this.chartState,
  })  : _behavior = behavior,
        _titleStyle = titleStyle,
        _subtitleStyle = subtitleStyle;

  final BaseChartState<D, BaseChart<D>> chartState;

  ChartTitle<D> _behavior;
  set behavior(ChartTitle<D> value) {
    _behavior = value;
    markNeedsPaint();
  }

  TextStyle _titleStyle;
  set titleStyle(TextStyle value) {
    _resetTextElementCache();
    _titleStyle = value;
    markNeedsPaint();
  }

  TextStyle _subtitleStyle;
  set subtitleStyle(TextStyle value) {
    _resetTextElementCache();
    _subtitleStyle = value;
    markNeedsPaint();
  }

  bool get isRtl => chartState.isRTL;

  /// Cached layout element for the title text.
  ///
  /// This is used to prevent expensive Flutter painter layout calls on every
  /// animation frame during the paint cycle. It should never be cached during
  /// layout measurement.
  TextElement? _titleTextElement;

  /// Cached layout element for the sub-title text.
  ///
  /// This is used to prevent expensive Flutter painter layout calls on every
  /// animation frame during the paint cycle. It should never be cached during
  /// layout measurement.
  TextElement? _subtitleTextElement;

  /// Resets the cached text elements used during the paint step.
  void _resetTextElementCache() {
    _titleTextElement = null;
    _subtitleTextElement = null;
  }

  void _updateViewData() {
    markNeedsLayout();
  }

  /// Get the direction of the title, resolving "auto" position into the
  /// appropriate direction for the position of the behavior.
  ChartTitleDirection get _resolvedTitleDirection {
    ChartTitleDirection resolvedTitleDirection = _behavior.titleDirection;

    if (resolvedTitleDirection == ChartTitleDirection.auto) {
      switch (_behavior.position) {
        case BehaviorPosition.bottom:
        case BehaviorPosition.inside:
        case BehaviorPosition.insideBelowAxis:
        case BehaviorPosition.top:
          resolvedTitleDirection = ChartTitleDirection.horizontal;
          break;
        case BehaviorPosition.end:
        case BehaviorPosition.start:
          resolvedTitleDirection = ChartTitleDirection.vertical;
          break;
      }
    }

    return resolvedTitleDirection;
  }

  /// Gets the resolved location for a label element.
  Offset? _getLabelPosition(
      bool isPrimaryTitle,
      Rect bounds,
      ChartTitleDirection titleDirection,
      TextElement textElement,
      double titleHeight,
      double subtitleHeight) {
    switch (_behavior.position) {
      case BehaviorPosition.bottom:
      case BehaviorPosition.top:
        return _getHorizontalLabelPosition(isPrimaryTitle, bounds,
            titleDirection, textElement, titleHeight, subtitleHeight);

      case BehaviorPosition.start:
      case BehaviorPosition.end:
        return _getVerticalLabelPosition(isPrimaryTitle, bounds, titleDirection,
            textElement, titleHeight, subtitleHeight);

      case BehaviorPosition.inside:
      case BehaviorPosition.insideBelowAxis:
        return null;
    }
  }

  /// Gets the resolved location for a title in the top or bottom margin.
  Offset _getHorizontalLabelPosition(
      bool isPrimaryTitle,
      Rect bounds,
      ChartTitleDirection titleDirection,
      TextElement textElement,
      double titleHeight,
      double subtitleHeight) {
    double labelX = 0.0;
    double labelY = 0.0;

    switch (_behavior.outsideJustification) {
      case OutsideJustification.middle:
      case OutsideJustification.middleDrawArea:
        final textWidth = (isRtl ? 1.0 : -1.0) *
            textElement.measurement.horizontalSliceWidth /
            2.0;
        labelX = (bounds.left + bounds.width / 2.0 + textWidth).roundToDouble();

        textElement.textDirection =
            isRtl ? TextDirection.rtl : TextDirection.ltr;
        break;

      case OutsideJustification.end:
      case OutsideJustification.endDrawArea:
      case OutsideJustification.start:
      case OutsideJustification.startDrawArea:
        final alignLeft = isRtl
            ? (_behavior.outsideJustification == OutsideJustification.end ||
                _behavior.outsideJustification ==
                    OutsideJustification.endDrawArea)
            : (_behavior.outsideJustification == OutsideJustification.start ||
                _behavior.outsideJustification ==
                    OutsideJustification.startDrawArea);

        // Don't apply outer padding if we are aligned to the draw area.
        final padding = (_behavior.outsideJustification ==
                    OutsideJustification.endDrawArea ||
                _behavior.outsideJustification ==
                    OutsideJustification.startDrawArea)
            ? 0.0
            : _behavior.outerPadding;

        if (alignLeft) {
          labelX = (bounds.left + padding).roundToDouble();
          textElement.textDirection = TextDirection.ltr;
        } else {
          labelX = (bounds.right - padding).roundToDouble();
          textElement.textDirection = TextDirection.rtl;
        }
        break;
    }

    // labelY is always relative to the component bounds.
    if (_behavior.position == BehaviorPosition.bottom) {
      final padding = _behavior.innerPadding +
          (isPrimaryTitle ? 0.0 : _behavior.titlePadding + titleHeight);

      labelY = (bounds.top + padding).roundToDouble();
    } else {
      double padding = 0.0 + _behavior.innerPadding;
      if (isPrimaryTitle) {
        padding += (subtitleHeight > 0.0
                ? _behavior.titlePadding + subtitleHeight
                : 0.0) +
            titleHeight;
      } else {
        padding += subtitleHeight;
      }

      labelY = (bounds.bottom - padding).roundToDouble();
    }

    return Offset(labelX, labelY);
  }

  /// Gets the resolved location for a title in the left or right margin.
  Offset _getVerticalLabelPosition(
      bool isPrimaryTitle,
      Rect bounds,
      ChartTitleDirection titleDirection,
      TextElement textElement,
      double titleHeight,
      double subtitleHeight) {
    double labelX = 0.0;
    double labelY = 0.0;

    switch (_behavior.outsideJustification) {
      case OutsideJustification.middle:
      case OutsideJustification.middleDrawArea:
        final textWidth = (isRtl ? -1 : 1) *
            textElement.measurement.horizontalSliceWidth /
            2.0;
        labelY = (bounds.top + bounds.height / 2 + textWidth).roundToDouble();

        textElement.textDirection =
            isRtl ? TextDirection.rtl : TextDirection.ltr;
        break;

      case OutsideJustification.end:
      case OutsideJustification.endDrawArea:
      case OutsideJustification.start:
      case OutsideJustification.startDrawArea:
        final alignLeft = isRtl
            ? (_behavior.outsideJustification == OutsideJustification.end ||
                _behavior.outsideJustification ==
                    OutsideJustification.endDrawArea)
            : (_behavior.outsideJustification == OutsideJustification.start ||
                _behavior.outsideJustification ==
                    OutsideJustification.startDrawArea);

        // Don't apply outer padding if we are aligned to the draw area.
        final padding = (_behavior.outsideJustification ==
                    OutsideJustification.endDrawArea ||
                _behavior.outsideJustification ==
                    OutsideJustification.startDrawArea)
            ? 0.0
            : _behavior.outerPadding;

        if (alignLeft) {
          labelY = (bounds.bottom - padding).roundToDouble();
          textElement.textDirection = TextDirection.ltr;
        } else {
          labelY = (bounds.top + padding).roundToDouble();
          textElement.textDirection = TextDirection.rtl;
        }
        break;
    }

    // labelX is always relative to the component bounds.
    if (_behavior.position == BehaviorPosition.end) {
      // TODO _layoutPosition
      final padding = _behavior.outerPadding +
          (isPrimaryTitle ? 0 : _behavior.titlePadding + titleHeight);

      labelX = (bounds.left + padding).roundToDouble();
    } else {
      final padding = _behavior.outerPadding +
          titleHeight +
          (isPrimaryTitle
              ? (subtitleHeight > 0
                  ? _behavior.titlePadding + subtitleHeight
                  : 0)
              : 0.0);

      labelX = (bounds.right - padding).roundToDouble();
    }

    return Offset(labelX, labelY);
  }

  Size measure(double maxWidth, double maxHeight) {
    double? minWidth;
    double? minHeight;
    double preferredWidth = 0.0;
    double preferredHeight = 0.0;

    // Always assume that we need outer padding and title padding, but only add
    // in the sub-title padding if we have one. Title is required, but sub-title
    // is optional.
    final totalPadding = _behavior.outerPadding +
        _behavior.innerPadding +
        (_behavior.subtitle != null ? _behavior.titlePadding : 0.0);

    // Create [TextStyle] from [TextStyle] to be used by all the elements.
    final textStyle = _titleStyle;

    final textElement = TextElement(_behavior.title)
      ..maxWidthStrategy = _behavior.maxWidthStrategy
      ..textStyle = textStyle;

    final subtitleTextStyle = _subtitleStyle;

    final TextElement? subtitleTextElement = _behavior.subtitle == null
        ? null
        : (TextElement(_behavior.subtitle!)
          ..maxWidthStrategy = _behavior.maxWidthStrategy
          ..textStyle = subtitleTextStyle);

    final resolvedTitleDirection = _resolvedTitleDirection;

    switch (_behavior.position) {
      case BehaviorPosition.bottom:
      case BehaviorPosition.top:
        final textHeight =
            (resolvedTitleDirection == ChartTitleDirection.vertical
                    ? textElement.measurement.horizontalSliceWidth
                    : textElement.measurement.verticalSliceWidth)
                .roundToDouble();

        final subtitleTextHeight = subtitleTextElement != null
            ? (resolvedTitleDirection == ChartTitleDirection.vertical
                    ? subtitleTextElement.measurement.horizontalSliceWidth
                    : subtitleTextElement.measurement.verticalSliceWidth)
                .roundToDouble()
            : 0.0;

        final measuredHeight =
            (textHeight + subtitleTextHeight + totalPadding).roundToDouble();
            
        minHeight = _behavior.layoutMinSize != null
            ? min(_behavior.layoutMinSize!, measuredHeight)
            : measuredHeight;

        preferredWidth = maxWidth;

        preferredHeight = _behavior.layoutPreferredSize != null
            ? min(_behavior.layoutPreferredSize!, maxHeight)
            : measuredHeight;
        break;

      case BehaviorPosition.end:
      case BehaviorPosition.start:
        final textWidth =
            (resolvedTitleDirection == ChartTitleDirection.vertical
                    ? textElement.measurement.verticalSliceWidth
                    : textElement.measurement.horizontalSliceWidth)
                .roundToDouble();

        final subtitleTextWidth = subtitleTextElement != null
            ? (resolvedTitleDirection == ChartTitleDirection.vertical
                    ? subtitleTextElement.measurement.verticalSliceWidth
                    : subtitleTextElement.measurement.horizontalSliceWidth)
                .roundToDouble()
            : 0.0;

        final measuredWidth =
            (textWidth + subtitleTextWidth + totalPadding).roundToDouble();
        minWidth = _behavior.layoutMinSize != null
            ? min(_behavior.layoutMinSize!, measuredWidth)
            : measuredWidth;

        preferredWidth = _behavior.layoutPreferredSize != null
            ? min(_behavior.layoutPreferredSize!, maxWidth)
            : measuredWidth;

        preferredHeight = maxHeight;
        break;

      case BehaviorPosition.inside:
      case BehaviorPosition.insideBelowAxis:
        preferredWidth = min(constraints.maxWidth, maxWidth);
        preferredHeight = min(constraints.maxHeight, maxHeight);
        break;
    }

    return constraints.constrain(Size(preferredWidth, preferredHeight));
  }

  late final LifecycleListener<D> _lifecycleListener;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);

    _lifecycleListener =
        LifecycleListener<D>(onAxisConfigured: _updateViewData);

    chartState.addLifecycleListener(_lifecycleListener);
  }

  @override
  void detach() {
    chartState.removeLifecycleListener(_lifecycleListener);
    super.detach();
  }

  @override
  void performLayout() {
    // Reset the cached text elements used during the paint step.
    _resetTextElementCache();

    size = measure(constraints.maxWidth, constraints.maxHeight);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final resolvedTitleDirection = _resolvedTitleDirection;

    final componentBounds = Offset.zero & size;

    double titleHeight = 0.0;
    double subtitleHeight = 0.0;

    // First, measure the height of the title and sub-title.
    // Chart titles do not animate. As an optimization for Flutter, cache the
    // [TextElement] to avoid an expensive painter layout operation on
    // subsequent animation frames.
    if (_titleTextElement == null) {
      final textStyle = _titleStyle;

      _titleTextElement = TextElement(_behavior.title)
        ..maxWidthStrategy = _behavior.maxWidthStrategy
        ..textStyle = textStyle;

      _titleTextElement!.maxWidth =
          resolvedTitleDirection == ChartTitleDirection.horizontal
              ? componentBounds.width
              : componentBounds.height;
    }

    // Get the height of the title so that we can off-set both text elements.
    titleHeight = _titleTextElement!.measurement.verticalSliceWidth;

    if (_behavior.subtitle != null) {
      // Chart titles do not animate. As an optimization for Flutter, cache the
      // [TextElement] to avoid an expensive painter layout operation on
      // subsequent animation frames.
      if (_subtitleTextElement == null) {
        // Create [TextStyle] from [TextStyle] to be used by all the
        // elements.
        final textStyle = _subtitleStyle;

        _subtitleTextElement = TextElement(_behavior.subtitle!)
          ..maxWidthStrategy = _behavior.maxWidthStrategy
          ..textStyle = textStyle;

        _subtitleTextElement!.maxWidth =
            resolvedTitleDirection == ChartTitleDirection.horizontal
                ? componentBounds.width
                : componentBounds.height;
      }

      // Get the height of the sub-title so that we can off-set both text
      // elements.
      subtitleHeight = _subtitleTextElement!.measurement.verticalSliceWidth;
    }

    // Draw a title if the text is not empty.
    final labelPoint = _getLabelPosition(
      true,
      componentBounds,
      resolvedTitleDirection,
      _titleTextElement!,
      titleHeight,
      subtitleHeight,
    );

    if (labelPoint != null) {
      final rotation = resolvedTitleDirection == ChartTitleDirection.vertical
          ? -pi / 2.0
          : 0.0;

      context.canvas.drawChartText(
        offset,
        _titleTextElement!,
        labelPoint.dx,
        labelPoint.dy,
        rotation: rotation,
      );
    }

    // Draw a sub-title if the text is not empty.
    if (_behavior.subtitle != null) {
      final labelPoint = _getLabelPosition(
        false,
        componentBounds,
        resolvedTitleDirection,
        _subtitleTextElement!,
        titleHeight,
        subtitleHeight,
      );

      if (labelPoint != null) {
        final rotation = resolvedTitleDirection == ChartTitleDirection.vertical
            ? -pi / 2.0
            : 0.0;

        context.canvas.drawChartText(
          offset,
          _subtitleTextElement!,
          labelPoint.dx,
          labelPoint.dy,
          rotation: rotation,
        );
      }
    }
  }
}

/// Direction of the title text on the chart.
enum ChartTitleDirection {
  /// Automatically assign a direction based on the [RangeAnnotationAxisType].
  ///
  /// [horizontal] for measure axes, or [vertical] for domain axes.
  auto,

  /// Text flows parallel to the x axis.
  horizontal,

  /// Text flows parallel to the y axis.
  vertical,
}
