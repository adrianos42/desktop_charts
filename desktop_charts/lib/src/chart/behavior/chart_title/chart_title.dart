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

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../../../text_element.dart' show MaxWidthStrategy, TextElement;
import '../../../theme.dart';
import '../../base_chart.dart'
    show BaseChartState, LifecycleListener, BaseChart;
import '../../chart_canvas.dart' show ChartCanvas;
import '../../layout/layout_view.dart'
    show LayoutPosition, LayoutViewPaintOrder;
import '../chart_behavior.dart'
    show BehaviorPosition, ChartBehavior, OutsideJustification;

/// Chart behavior that adds title text to a chart. An optional second line of
/// text may be rendered as a sub-title.
///
/// Titles will by default be rendered as the outermost component in the chart
/// margin.
class ChartTitle<D> extends ChartBehavior<D> {
  /// Constructs a [ChartTitle].
  ///
  /// [title] contains the text for the chart title.
  ChartTitle(
    String title, {
    BehaviorPosition? behaviorPosition,
    double? innerPadding,
    double? layoutMinSize,
    double? layoutPreferredSize,
    double? outerPadding,
    MaxWidthStrategy? maxWidthStrategy,
    ChartTitleDirection? titleDirection,
    OutsideJustification? titleOutsideJustification,
    double? titlePadding,
    TextStyle? titleStyleSpec,
    String? subTitle,
    TextStyle? subTitleStyleSpec,
  }) : _config = _ChartTitleConfig(
          behaviorPosition: behaviorPosition ?? _defaultBehaviorPosition,
          innerPadding: innerPadding ?? _defaultInnerPadding,
          layoutMinSize: layoutMinSize,
          layoutPreferredSize: layoutPreferredSize,
          outerPadding: outerPadding ?? _defaultOuterPadding,
          maxWidthStrategy: maxWidthStrategy ?? _defaultMaxWidthStrategy,
          title: title,
          titleDirection: titleDirection ?? _defaultTitleDirection,
          titleOutsideJustification:
              titleOutsideJustification ?? _defaultTitleOutsideJustification,
          titlePadding: titlePadding ?? _defaultTitlePadding,
          titleStyleSpec: titleStyleSpec ??
              TextStyle(
                  fontSize: 18,
                  color: const ChartsThemeData.fallbackw().tickColor),
          subTitle: subTitle,
          subTitleStyleSpec: subTitleStyleSpec ??
              TextStyle(
                  fontSize: 14,
                  color: const ChartsThemeData.fallbackw().tickColor),
        ) {
    _lifecycleListener =
        LifecycleListener<D>(onAxisConfigured: _updateViewData);
  }

  static const _defaultBehaviorPosition = BehaviorPosition.top;
  static const _defaultMaxWidthStrategy = MaxWidthStrategy.ellipsize;
  static const _defaultTitleDirection = ChartTitleDirection.auto;
  static const _defaultTitleOutsideJustification = OutsideJustification.middle;
  static const _defaultInnerPadding = 10.0;
  static const _defaultTitlePadding = 18.0;
  static const _defaultOuterPadding = 10.0;

  /// Stores all of the configured properties of the behavior.
  final _ChartTitleConfig _config;

  late BaseChartState<D, BaseChart<D>> _chartState;

  _ChartTitleLayoutView<D>? _view;

  late final LifecycleListener<D> _lifecycleListener;

  /// Layout position for the title.
  BehaviorPosition get behaviorPosition => _config.behaviorPosition;

  set behaviorPosition(BehaviorPosition behaviorPosition) {
    _config.behaviorPosition = behaviorPosition;
  }

  /// Minimum size of the legend component. Optional.
  ///
  /// If the legend is positioned in the top or bottom margin, then this
  /// configures the legend's height. If positioned in the start or end
  /// position, this configures the legend's width.
  double? get layoutMinSize => _config.layoutMinSize;

  set layoutMinSize(double? layoutMinSize) {
    _config.layoutMinSize = layoutMinSize;
  }

  /// Preferred size of the legend component. Defaults to 0.
  ///
  /// If the legend is positioned in the top or bottom margin, then this
  /// configures the legend's height. If positioned in the start or end
  /// position, this configures the legend's width.
  double? get layoutPreferredSize => _config.layoutPreferredSize;

  set layoutPreferredSize(double? layoutPreferredSize) {
    _config.layoutPreferredSize = layoutPreferredSize;
  }

  /// Strategy for handling title text that is too large to fit. Defaults to
  /// truncating the text with ellipses.
  MaxWidthStrategy get maxWidthStrategy => _config.maxWidthStrategy;

  set maxWidthStrategy(MaxWidthStrategy maxWidthStrategy) {
    _config.maxWidthStrategy = maxWidthStrategy;
  }

  /// Primary text for the title.
  String get title => _config.title;

  set title(String title) {
    _config.title = title;
  }

  /// Direction of the chart title text.
  ///
  /// This defaults to horizontal for a title in the top or bottom
  /// [behaviorPosition], or vertical for start or end [behaviorPosition].
  ChartTitleDirection get titleDirection => _config.titleDirection;

  set titleDirection(ChartTitleDirection titleDirection) {
    _config.titleDirection = titleDirection;
  }

  /// Justification of the title text if it is positioned outside of the draw
  /// area.
  OutsideJustification get titleOutsideJustification =>
      _config.titleOutsideJustification;

  set titleOutsideJustification(
      OutsideJustification titleOutsideJustification) {
    _config.titleOutsideJustification = titleOutsideJustification;
  }

  /// Space between the title and sub-title text, if defined.
  ///
  /// This padding is not used if no sub-title is provided.
  double get titlePadding => _config.titlePadding;

  set titlePadding(double titlePadding) {
    _config.titlePadding = titlePadding;
  }

  /// Style of the [title] text.
  TextStyle get titleStyleSpec => _config.titleStyleSpec;

  set titleStyleSpec(TextStyle titleStyleSpec) {
    _config.titleStyleSpec = titleStyleSpec;
  }

  /// Secondary text for the sub-title.
  ///
  /// [subTitle] is rendered on a second line below the [title], and may be
  /// styled differently.
  String? get subTitle => _config.subTitle;

  set subTitle(String? subTitle) {
    _config.subTitle = subTitle;
  }

  /// Style of the [subTitle] text.
  TextStyle get subTitleStyleSpec => _config.subTitleStyleSpec;

  set subTitleStyleSpec(TextStyle subTitleStyleSpec) {
    _config.subTitleStyleSpec = subTitleStyleSpec;
  }

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
  double get innerPadding => _config.innerPadding;

  set innerPadding(double innerPadding) {
    _config.innerPadding = innerPadding;
  }

  /// Space between the "outside" of the chart, and the title behavior itself.
  ///
  /// This padding is applied to all 3 edges of the title that are not in the
  /// direction of the draw area. For a top positioned title, this is applied
  /// to the top, left, and right edges. [innerPadding] is applied to the
  /// bottom edge.
  double get outerPadding => _config.outerPadding;

  set outerPadding(double outerPadding) {
    _config.outerPadding = outerPadding;
  }

  @override
  void attachTo<S extends BaseChart<D>>(BaseChartState<D, S> chartState) {
    _chartState = chartState;
    _chartState.addLifecycleListener(_lifecycleListener);
  }

  @override
  Widget buildBehavior(BuildContext context) {
    return const SizedBox();
  }

  @override
  void dispose() {
    _chartState.removeLifecycleListener(_lifecycleListener);
  }

  void _updateViewData() {
    _view!.config = _config;
  }

  @override
  String get role => 'ChartTitle-${_config.behaviorPosition}';
}

/// Layout view component for [ChartTitle].
class _ChartTitleLayoutView<D> {
  _ChartTitleLayoutView({
    required int layoutPaintOrder,
    required _ChartTitleConfig config,
    required this.chart,
  }) : _config = config {
    // Set inside body to resolve [_layoutPosition].
    //   _layoutConfig = LayoutViewConfig(
    //     paintOrder: layoutPaintOrder,
    //     position: _layoutPosition,
    //     positionOrder: LayoutViewPositionOrder.chartTitle,
    //   );
  }

  /// Stores all of the configured properties of the behavior.
  _ChartTitleConfig _config;

  BaseChartState<D, BaseChart<D>>? chart;

  bool get isRtl => chart?.isRTL ?? false;

  late Rect _componentBounds;
  late Rect _drawAreaBounds;

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
  TextElement? _subTitleTextElement;

  /// Sets the configuration for the title behavior.
  set config(_ChartTitleConfig config) {
    _config = config;
    // TODO layoutConfig.position = _layoutPosition;
  }

  @override
  Size measure(double maxWidth, double maxHeight) {
    double? minWidth;
    double? minHeight;
    double preferredWidth = 0.0;
    double preferredHeight = 0.0;

    // Always assume that we need outer padding and title padding, but only add
    // in the sub-title padding if we have one. Title is required, but sub-title
    // is optional.
    final totalPadding = _config.outerPadding +
        _config.innerPadding +
        (_config.subTitle != null ? _config.titlePadding : 0.0);

    // Create [TextStyle] from [TextStyle] to be used by all the elements.
    final textStyle = _getTextStyle(_config.titleStyleSpec);

    final textElement = TextElement(_config.title)
      ..maxWidthStrategy = _config.maxWidthStrategy
      ..textStyle = textStyle;

    final subTitleTextStyle = _getTextStyle(_config.subTitleStyleSpec);

    final TextElement? subTitleTextElement = _config.subTitle == null
        ? null
        : (TextElement(_config.subTitle!)
          ..maxWidthStrategy = _config.maxWidthStrategy
          ..textStyle = subTitleTextStyle);

    final resolvedTitleDirection = _resolvedTitleDirection;

    switch (_config.behaviorPosition) {
      case BehaviorPosition.bottom:
      case BehaviorPosition.top:
        final textHeight =
            (resolvedTitleDirection == ChartTitleDirection.vertical
                    ? textElement.measurement.horizontalSliceWidth
                    : textElement.measurement.verticalSliceWidth)
                .roundToDouble();

        final subTitleTextHeight = subTitleTextElement != null
            ? (resolvedTitleDirection == ChartTitleDirection.vertical
                    ? subTitleTextElement.measurement.horizontalSliceWidth
                    : subTitleTextElement.measurement.verticalSliceWidth)
                .roundToDouble()
            : 0.0;

        final measuredHeight =
            (textHeight + subTitleTextHeight + totalPadding).roundToDouble();
        minHeight = _config.layoutMinSize != null
            ? min(_config.layoutMinSize!, measuredHeight)
            : measuredHeight;

        preferredWidth = maxWidth;

        preferredHeight = _config.layoutPreferredSize != null
            ? min(_config.layoutPreferredSize!, maxHeight)
            : measuredHeight;
        break;

      case BehaviorPosition.end:
      case BehaviorPosition.start:
        final textWidth =
            (resolvedTitleDirection == ChartTitleDirection.vertical
                    ? textElement.measurement.verticalSliceWidth
                    : textElement.measurement.horizontalSliceWidth)
                .roundToDouble();

        final subTitleTextWidth = subTitleTextElement != null
            ? (resolvedTitleDirection == ChartTitleDirection.vertical
                    ? subTitleTextElement.measurement.verticalSliceWidth
                    : subTitleTextElement.measurement.horizontalSliceWidth)
                .roundToDouble()
            : 0.0;

        final measuredWidth =
            (textWidth + subTitleTextWidth + totalPadding).roundToDouble();
        minWidth = _config.layoutMinSize != null
            ? min(_config.layoutMinSize!, measuredWidth)
            : measuredWidth;

        preferredWidth = _config.layoutPreferredSize != null
            ? min(_config.layoutPreferredSize!, maxWidth)
            : measuredWidth;

        preferredHeight = maxHeight;
        break;

      case BehaviorPosition.inside:
      case BehaviorPosition.insideBelowAxis:
        preferredWidth = min(_drawAreaBounds.width, maxWidth);
        preferredHeight = min(_drawAreaBounds.height, maxHeight);
        break;
    }

    // Reset the cached text elements used during the paint step.
    _resetTextElementCache();

    // return ViewMeasuredSizes(
    //     minWidth: minWidth,
    //     minHeight: minHeight,
    //     preferredWidth: preferredWidth,
    //     preferredHeight: preferredHeight);
    return Size.zero;
  }

  @override
  void layout(Rect componentBounds, Rect drawAreaBounds) {
    _componentBounds = componentBounds;
    _drawAreaBounds = drawAreaBounds;

    // Reset the cached text elements used during the paint step.
    _resetTextElementCache();
  }

  @override
  void paint(Canvas canvas, Offset offset, double animationPercent) {
    final resolvedTitleDirection = _resolvedTitleDirection;

    double titleHeight = 0.0;
    double subTitleHeight = 0.0;

    // First, measure the height of the title and sub-title.
    // Chart titles do not animate. As an optimization for Flutter, cache the
    // [TextElement] to avoid an expensive painter layout operation on
    // subsequent animation frames.
    if (_titleTextElement == null) {
      // Create [TextStyle] from [TextStyle] to be used by all the
      // elements.
      final textStyle = _getTextStyle(_config.titleStyleSpec);

      _titleTextElement = TextElement(_config.title)
        ..maxWidthStrategy = _config.maxWidthStrategy
        ..textStyle = textStyle;

      _titleTextElement!.maxWidth =
          resolvedTitleDirection == ChartTitleDirection.horizontal
              ? _componentBounds.width
              : _componentBounds.height;

      // Get the height of the title so that we can off-set both text elements.
      titleHeight = _titleTextElement!.measurement.verticalSliceWidth;
    }

    if (_config.subTitle != null) {
      // Chart titles do not animate. As an optimization for Flutter, cache the
      // [TextElement] to avoid an expensive painter layout operation on
      // subsequent animation frames.
      if (_subTitleTextElement == null) {
        // Create [TextStyle] from [TextStyle] to be used by all the
        // elements.
        final textStyle = _getTextStyle(_config.subTitleStyleSpec);

        _subTitleTextElement = TextElement(_config.subTitle!)
          ..maxWidthStrategy = _config.maxWidthStrategy
          ..textStyle = textStyle;

        _subTitleTextElement!.maxWidth =
            resolvedTitleDirection == ChartTitleDirection.horizontal
                ? _componentBounds.width
                : _componentBounds.height;
      }

      // Get the height of the sub-title so that we can off-set both text
      // elements.
      subTitleHeight = _subTitleTextElement!.measurement.verticalSliceWidth;
    }

    // Draw a title if the text is not empty.
    final labelPoint = _getLabelPosition(
      true,
      _componentBounds,
      resolvedTitleDirection,
      _titleTextElement!,
      titleHeight,
      subTitleHeight,
    );

    if (labelPoint != null) {
      final rotation = resolvedTitleDirection == ChartTitleDirection.vertical
          ? -pi / 2.0
          : 0.0;

      canvas.drawChartText(
        offset,
        _titleTextElement!,
        labelPoint.dx,
        labelPoint.dy,
        rotation: rotation,
      );
    }

    // Draw a sub-title if the text is not empty.
    if (_config.subTitle != null) {
      final labelPoint = _getLabelPosition(
        false,
        _componentBounds,
        resolvedTitleDirection,
        _subTitleTextElement!,
        titleHeight,
        subTitleHeight,
      );

      if (labelPoint != null) {
        final rotation = resolvedTitleDirection == ChartTitleDirection.vertical
            ? -pi / 2.0
            : 0.0;

        canvas.drawChartText(
          offset,
          _subTitleTextElement!,
          labelPoint.dx,
          labelPoint.dy,
          rotation: rotation,
        );
      }
    }
  }

  /// Resets the cached text elements used during the paint step.
  void _resetTextElementCache() {
    _titleTextElement = null;
    _subTitleTextElement = null;
  }

  /// Get the direction of the title, resolving "auto" position into the
  /// appropriate direction for the position of the behavior.
  ChartTitleDirection get _resolvedTitleDirection {
    ChartTitleDirection resolvedTitleDirection = _config.titleDirection;

    if (resolvedTitleDirection == ChartTitleDirection.auto) {
      switch (_config.behaviorPosition) {
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

  LayoutPosition get _layoutPosition {
    return LayoutPosition.bottom;
//    return layoutPosition(
//        _config.behaviorPosition, _config.titleOutsideJustification, isRtl);
  }

  /// Gets the resolved location for a label element.
  Offset? _getLabelPosition(
      bool isPrimaryTitle,
      Rect bounds,
      ChartTitleDirection titleDirection,
      TextElement textElement,
      double titleHeight,
      double subTitleHeight) {
    switch (_config.behaviorPosition) {
      case BehaviorPosition.bottom:
      case BehaviorPosition.top:
        return _getHorizontalLabelPosition(isPrimaryTitle, bounds,
            titleDirection, textElement, titleHeight, subTitleHeight);

      case BehaviorPosition.start:
      case BehaviorPosition.end:
        return _getVerticalLabelPosition(isPrimaryTitle, bounds, titleDirection,
            textElement, titleHeight, subTitleHeight);

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
      double subTitleHeight) {
    double labelX = 0.0;
    double labelY = 0.0;

    switch (_config.titleOutsideJustification) {
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
            ? (_config.titleOutsideJustification == OutsideJustification.end ||
                _config.titleOutsideJustification ==
                    OutsideJustification.endDrawArea)
            : (_config.titleOutsideJustification ==
                    OutsideJustification.start ||
                _config.titleOutsideJustification ==
                    OutsideJustification.startDrawArea);

        // Don't apply outer padding if we are aligned to the draw area.
        final padding = (_config.titleOutsideJustification ==
                    OutsideJustification.endDrawArea ||
                _config.titleOutsideJustification ==
                    OutsideJustification.startDrawArea)
            ? 0.0
            : _config.outerPadding;

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
    if (_config.behaviorPosition == BehaviorPosition.bottom) {
      final padding = _config.innerPadding +
          (isPrimaryTitle ? 0.0 : _config.titlePadding + titleHeight);

      labelY = (bounds.top + padding).roundToDouble();
    } else {
      double padding = 0.0 + _config.innerPadding;
      if (isPrimaryTitle) {
        padding += (subTitleHeight > 0.0
                ? _config.titlePadding + subTitleHeight
                : 0.0) +
            titleHeight;
      } else {
        padding += subTitleHeight;
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
      double subTitleHeight) {
    double labelX = 0.0;
    double labelY = 0.0;

    switch (_config.titleOutsideJustification) {
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
            ? (_config.titleOutsideJustification == OutsideJustification.end ||
                _config.titleOutsideJustification ==
                    OutsideJustification.endDrawArea)
            : (_config.titleOutsideJustification ==
                    OutsideJustification.start ||
                _config.titleOutsideJustification ==
                    OutsideJustification.startDrawArea);

        // Don't apply outer padding if we are aligned to the draw area.
        final padding = (_config.titleOutsideJustification ==
                    OutsideJustification.endDrawArea ||
                _config.titleOutsideJustification ==
                    OutsideJustification.startDrawArea)
            ? 0.0
            : _config.outerPadding;

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
    if (_layoutPosition == LayoutPosition.right ||
        _layoutPosition == LayoutPosition.fullRight) {
      final padding = _config.outerPadding +
          (isPrimaryTitle ? 0 : _config.titlePadding + titleHeight);

      labelX = (bounds.left + padding).roundToDouble();
    } else {
      final padding = _config.outerPadding +
          titleHeight +
          (isPrimaryTitle
              ? (subTitleHeight > 0 ? _config.titlePadding + subTitleHeight : 0)
              : 0.0);

      labelX = (bounds.right - padding).roundToDouble();
    }

    return Offset(labelX, labelY);
  }

  // Helper function that converts [TextStyle] to [TextStyle].
  TextStyle _getTextStyle(TextStyle labelSpec) {
    return TextStyle(
      color: labelSpec.color ?? const ChartsThemeData.fallbackw().tickColor,
      fontFamily: labelSpec.fontFamily,
      fontSize: labelSpec.fontSize ?? 18.0,
      height: labelSpec.height,
    );
  }
}

/// Configuration object for [ChartTitle].
class _ChartTitleConfig {
  _ChartTitleConfig({
    required this.behaviorPosition,
    required this.layoutMinSize,
    required this.layoutPreferredSize,
    required this.maxWidthStrategy,
    required this.title,
    required this.titleDirection,
    required this.titleOutsideJustification,
    required this.titleStyleSpec,
    required this.subTitle,
    required this.subTitleStyleSpec,
    required this.innerPadding,
    required this.titlePadding,
    required this.outerPadding,
  });

  BehaviorPosition behaviorPosition;

  double? layoutMinSize;
  double? layoutPreferredSize;

  MaxWidthStrategy maxWidthStrategy;

  String title;
  ChartTitleDirection titleDirection;
  OutsideJustification titleOutsideJustification;
  TextStyle titleStyleSpec;

  String? subTitle;
  TextStyle subTitleStyleSpec;

  double innerPadding;
  double titlePadding;
  double outerPadding;
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
