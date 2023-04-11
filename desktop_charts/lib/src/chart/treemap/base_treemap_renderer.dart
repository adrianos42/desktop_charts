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

import 'dart:collection' show Queue;
import 'dart:math' show min;

import 'package:flutter/widgets.dart';

import '../../data/series.dart';
import '../../data/tree.dart';
import '../../math.dart' show NullablePoint;
import '../base_chart.dart';
import '../chart_canvas.dart';
import '../datum_details.dart';
import '../processed_series.dart';
import '../series_datum.dart';
import '../series_renderer.dart';
import 'treemap_label_decorator.dart';
import 'treemap_renderer_config.dart';
import 'treemap_renderer_element.dart';

/// Key for storing a list of treemap renderer elements.
///
/// Each element contains a bounding rectangle for rendering.
const treeMapElementsKey =
    AttributeKey<Iterable<TreeMapRendererElement<Object>>>(
        'TreeMapRenderer.elements');

abstract class BaseTreeMapRenderer<D, S extends BaseChart<D>>
    extends BaseSeriesRenderer<D, S> {
  BaseTreeMapRenderer({
    required this.config,
    required super.seriesList,
    required super.chartState,
    String? rendererId,
  })  : labelDecorator = config.labelDecorator,
        super(
          rendererId: rendererId ?? defaultRendererId,
          symbolRenderer: config.symbolRenderer,
        );

  /// Default renderer ID for treemap.
  static const defaultRendererId = 'treemap';

  /// Renderer configuration.
  final TreeMapRendererConfig<D> config;

  /// Decorator for rendering treemap node label.
  final TreeMapLabelDecorator<D>? labelDecorator;

  /// A hash map that allows accessing the renderer element drawn on the chart
  /// from a treemap node.
  final _treeNodeToRendererElement =
      <TreeNode<Object>, TreeMapRendererElement<D>>{};

  /// An ordered map of [_AnimatedTreeMapRect] that will get drawn on the
  /// canvas.
  final _animatedTreeMapRects = <D, _AnimatedTreeMapRect<D>>{};

  BaseChartState<D, S>? _chart;

  /// Rtl direction setting from chart context.
  bool get isRtl => _chart?.isRTL ?? false;

  @override
  void configureSeries() {
    assignMissingColors(
      seriesList,
      emptyCategoryUsesSinglePalette: true,
    );
    assignMissingStrokeWidths(seriesList);
  }

  @override
  void preprocessSeries() {
    _ensureSingleTree(seriesList);

    // Clears [_treeNodeToRendererElement] map when a seriesList is passed
    // in for preprocessing. The order in this map matters because the first
    // entry is expected to be the root.
    _treeNodeToRendererElement.clear();

    for (final series in seriesList) {
      final count = series.data.length;

      // Populates [treeNodeToRendererElement] map entries.
      for (int i = 0; i < count; i += 1) {
        final node = series.data[i] as TreeNode<Object>;
        _treeNodeToRendererElement[node] =
            _createRendererElement(series, i, isLeaf: !node.hasChildren);
      }
      series.setAttr(treeMapElementsKey, _treeNodeToRendererElement.values);
    }
  }

  /// Tiling algorithm for dividing a region into subregions of specified areas.
  void tile(TreeNode<Object> node);

  @override
  void update(Offset offset) {
    super.update(offset);
    // _visibleTreeMapRectKeys is used to remove any [_AnimatedTreeMapRect]s
    // that were rendered in the previous draw cycles, but no longer have a
    // corresponding datum in the series data.
    final visibleTreeMapRectKeys = <D>{};

    for (final series in seriesList) {
      if (series.data.isNotEmpty) {
        final root = series.data.first as TreeNode<Object>;
        // Configures the renderer element for root node.
        _configureRootRendererElement(root);

        // Applies tiling algorithm to each node.
        for (final datum in series.data) {
          final node = datum as TreeNode<Object>;
          tile(node);
          final element = _getRendererElement(node)..refreshPaintProperties();
          final rect = _createAnimatedTreeMapRect(element);
          visibleTreeMapRectKeys.add(rect.key);
        }
      }
    }

    _animatedTreeMapRects.forEach((_, rect) {
      if (!visibleTreeMapRectKeys.contains(rect.key)) {
        rect.animateOut();
      }
    });
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    super.paint(context, offset);

    final bounds = Rect.fromLTWH(offset.dx, offset.dy, size.width, size.height);

    if (chartState.animationPosition.value == 1.0) {
      _animatedTreeMapRects.removeWhere((_, rect) => rect.animatingOut);
    }

    _animatedTreeMapRects.forEach((_, animatedRect) {
      final element =
          animatedRect.getCurrentRect(chartState.animationPosition.value);
      final rect = element.boundingRect;

      // canvas.drawRRect is used instead of canvas.drawRect because drawRRect
      // supports FillPatternType.forwardHatch.
      context.canvas.drawChartRRect(
        rect,
        fill: element.fillColor!,
        fillPattern: element.fillPattern,
        patternStrokeWidth: config.patternStrokeWidth,
        patternColor: element.patternColor,
        stroke: element.strokeColor,
        strokeWidth: element.strokeWidth!.toDouble(),
        radius: 0,
        roundTopLeft: false,
        roundTopRight: false,
        roundBottomLeft: false,
        roundBottomRight: false,
      );

      // Paint label.
      labelDecorator?.decorate(
        element, context.canvas,
        drawBounds: bounds,
        animationPercent: chartState.animationPosition.value,
        rtl: isRtl,
        // only leaf node could possibly render label vertically.
        renderVertically: element.isLeaf && rect.width < rect.height,
        renderMultiline: element.isLeaf,
      );
    });
  }

  /// Datum details of nearest rectangles in the treemap.
  @override
  List<DatumDetails<D>> getNearestDatumDetailPerSeries(
    Offset chartPoint,
    bool byDomain,
    Rect? boundsOverride, {
    bool selectOverlappingPoints = false,
    bool selectExactEventLocation = false,
  }) {
    final nearest = <DatumDetails<D>>[];

    // Checks if the [chartPoint] is within bounds.
    if (!isPointWithinBounds(chartPoint, boundsOverride!)) {
      return nearest;
    }

    final root = _treeNodeToRendererElement.entries.first.key;
    final queue = Queue<TreeNode<Object>>()..add(root);

    while (queue.isNotEmpty) {
      final node = queue.removeFirst();
      final element = _getRendererElement(node);

      if (element.boundingRect.contains(chartPoint)) {
        nearest.add(DatumDetails<D>(
          index: element.index,
          series: element.series,
          datum: node,
          domain: element.domain,
          measure: element.measure,
          domainDistance: 0.0,
          measureDistance: 0.0,
        ));
        // No need to verify remaining siblings.
        queue.clear();

        // Only processes nodes whose parents contain the [chartPoint].
        // This reduces the number of nodes to verify.
        queue.addAll(node.children);
      }
    }

    // Prioritizes nodes with larger depth;
    nearest.sort((a, b) {
      final nodeA = a.datum as TreeNode<Object>;
      final nodeB = b.datum as TreeNode<Object>;
      return nodeB.depth.compareTo(nodeA.depth);
    });
    return nearest;
  }

  @override
  DatumDetails<D> addPositionToDetailsForSeriesDatum(
    DatumDetails<D> details,
    SeriesDatum<D> seriesDatum,
  ) {
    final bounds =
        _getRendererElement(seriesDatum.datum as TreeNode<Object>).boundingRect;
    final chartPosition = Offset(
        (isRtl ? bounds.left : bounds.right).toDouble(),
        (bounds.top + (bounds.height / 2)).toDouble());
    return DatumDetails.from(
      details,
      chartPosition: NullablePoint.from(chartPosition),
    );
  }

  /// Assigns missing colors in case when color accessor functions are not set.
  ///
  /// Assigned color is based on the depth of each node.
  @override
  void assignMissingColors(
    Iterable<MutableSeries<D>> seriesList, {
    required bool emptyCategoryUsesSinglePalette,
  }) {
    for (final series in seriesList) {
      final colorPalettes =
          chartState.themeData.getOrderedPalettes(series.data.length);
      final count = colorPalettes.length;

      series.fillColorFn ??= (int? index) {
        final node = series.data[index!] as TreeNode<Object>;
        return colorPalettes[node.depth % count].shadeDefault;
      };

      // Pattern color and stroke color defaults to the default config stroke
      // color if no accessor is provided.
      series.colorFn ??= (index) => config.strokeColor;
      series.patternColorFn ??= (index) => config.strokeColor;
    }
  }

  /// Assigns missing stroke widths in case when strokeWidth accessor
  /// functions are not set.
  @protected
  void assignMissingStrokeWidths(Iterable<MutableSeries<D>> seriesList) {
    for (final series in seriesList) {
      series.strokeWidthFn ??= (_) => config.strokeWidth;
    }
  }

  /// Available bounding rectangle that can be used to lay out the child
  /// renderer elements.
  ///
  /// Available bounding rectangle is computed after padding is applied.
  @protected
  Rect availableLayoutBoundingRect(TreeNode<Object> node) {
    final element = _getRendererElement(node);
    final rect = element.boundingRect;
    final padding = config.rectPadding;

    double top = rect.top + padding.top;
    double left = rect.left + padding.left;
    double width = rect.width - padding.left - padding.right;
    double height = rect.height - padding.top - padding.bottom;

    // Handles an edge case when width or height is negative.
    if (width < 0) {
      left += width / 2;
      width = 0;
    }
    if (height < 0) {
      top += height / 2;
      height = 0;
    }

    return Rect.fromLTWH(left, top, width, height);
  }

  /// Scales the area of each renderer element in [children] by a [scaleFactor].
  ///
  /// [scaleFactor] should be calculated based on the available layout area and
  /// the measure which the available layout area represents.
  @protected
  void scaleArea(Iterable<TreeNode<Object>> children, double scaleFactor) {
    for (final child in children) {
      final element = _getRendererElement(child);
      final area =
          element.measure.toDouble() * (scaleFactor < 0 ? 0 : scaleFactor);
      element.area = area <= 0 ? 0 : area;
    }
  }

  /// Gets the measure for a tree [node].
  @protected
  double measureForTreeNode(TreeNode<Object> node) =>
      _getRendererElement(node).measure.toDouble();

  /// Gets the area of a [Rect].
  @protected
  double areaForRectangle(Rect rect) => rect.height * rect.width;

  /// Gets the area for a tree [node].
  @protected
  double areaForTreeNode(TreeNode<Object> node) =>
      _getRendererElement(node).area;

  /// Positions each renderer element in [nodes] within the [boundingRect].
  ///
  /// [side] is defined as the smallest side of the [layoutArea].
  ///
  /// Consider the following boundingRect:
  /// ```
  /// boundingRect:
  ///          ------------------
  ///         |************|     |
  ///  (side) |*layoutArea*|     | height
  ///         |************|     |
  ///          ------------------
  ///                 width
  /// ```
  @protected
  Rect position(
    Iterable<TreeNode<Object>> nodes,
    Rect boundingRect,
    double side,
    double layoutArea,
  ) {
    double top = boundingRect.top;
    double left = boundingRect.left;
    double length = side > 0 ? (layoutArea / side) : 0.0;

    Rect bounding = boundingRect;

    // [side] is equal to the height of the boundingRect, so stacks rectangles
    // vertically. [length] is the width of the stacking rectangles.
    if (side == boundingRect.height) {
      // Truncates the length since it is out of bounds.
      if (length > boundingRect.width) {
        length = boundingRect.width.truncateToDouble();
      }

      for (final node in nodes) {
        final element = _getRendererElement(node);
        final height = min(
          boundingRect.top + boundingRect.height - top,
          length > 0 ? (element.area / length) : 0.0,
        );
        element.boundingRect = Rect.fromLTWH(left, top, length, height);
        top += height;
      }

      bounding = Rect.fromLTWH(
        bounding.left + length,
        bounding.top,
        bounding.width - length,
        bounding.height,
      );
    } else {
      // Positions rectangles horizontally.
      if (length > boundingRect.height) {
        length = boundingRect.height.truncateToDouble();
      }

      for (final node in nodes) {
        final element = _getRendererElement(node);
        final width = min(boundingRect.left + boundingRect.width - left,
            length > 0 ? (element.area / length) : 0.0);
        element.boundingRect = Rect.fromLTWH(left, top, width, length);
        left += width;
      }

      bounding = Rect.fromLTWH(
        bounding.left,
        bounding.top + length,
        bounding.width,
        bounding.height - length,
      );
    }

    return bounding;
  }

  void _configureRootRendererElement(TreeNode<Object> root) {
    // Root should take up the entire [drawBounds] area.
    // TODO final drawBounds = this.drawBounds!;
    // TODO _getRendererElement(root)
    // TODO   ..boundingRect = drawBounds
    // TODO   ..area = areaForRectangle(drawBounds);
  }

  /// Creates an [_AnimatedTreeMapRect].
  ///
  /// This object contains previous, current, and target animation state of
  /// treemap renderer [element].
  _AnimatedTreeMapRect<D> _createAnimatedTreeMapRect(
      TreeMapRendererElement<D> element) {
    final key = element.domain;
    // Creates a _AnimatedTreeMapRect if not exists. Otherwise, moves the
    // existing one to the end of the list so that the iteration order of
    // _AnimatedTreeMapRects is preserved. This is important because the order
    // of rects in _animatedTreeMapRects determines the painting order.
    final rect = _animatedTreeMapRects.containsKey(key)
        ? _animatedTreeMapRects.remove(key)!
        : _AnimatedTreeMapRect<D>(key: key);

    _animatedTreeMapRects[key] = rect;
    return rect..setNewTarget(element);
  }

  /// Creates a basic [TreeMapRendererElement].
  ///
  /// `boundingRect` and `area` are set after tile function is applied.
  TreeMapRendererElement<D> _createRendererElement(
    MutableSeries<D> series,
    int index, {
    required bool isLeaf,
  }) =>
      TreeMapRendererElement<D>(
        domain: series.domainFn(index),
        measure: series.measureFn(index)!,
        isLeaf: isLeaf,
        index: index,
        series: series,
      );

  TreeMapRendererElement<D> _getRendererElement(TreeNode<Object> node) {
    final element = _treeNodeToRendererElement[node];
    assert(
        element != null, 'There is no associated renderer element for $node.');
    return element!;
  }

  void _ensureSingleTree(List<ImmutableSeries<D>> seriesList) {
    assert(seriesList.length <= 1,
        'TreeMapRenderer only supports a single series at most.');
  }
}

/// A representation of the animation state of [TreeMapRendererElement].
class _AnimatedTreeMapRect<D> {
  _AnimatedTreeMapRect({required this.key});

  final D key;

  /// A previous [TreeMapRendererElement] before animation.
  TreeMapRendererElement<D>? _previousRect;

  /// A target [TreeMapRendererElement] after animation is performed.
  late TreeMapRendererElement<D> _targetRect;

  /// Current [TreeMapRendererElement] at a given animation percent time.
  TreeMapRendererElement<D>? _currentRect;

  // Flag indicating whether this rect is being animated out of the chart.
  bool animatingOut = false;

  /// Animates a rect that was removed from the tree out of the view.
  ///
  /// Animates the height and width of the rect down to zero, centered in the
  /// middle of the original rect.
  void animateOut() {
    final newTarget = _currentRect!.clone();
    final rect = newTarget.boundingRect;
    newTarget.boundingRect = Rect.fromLTWH(rect.left + (rect.width / 2.0),
        rect.top + (rect.height / 2.0), 0.0, 0.0);
    newTarget.strokeWidth = 0.0;

    setNewTarget(newTarget);
    animatingOut = true;
  }

  void setNewTarget(TreeMapRendererElement<D> newTarget) {
    animatingOut = false;
    // Only when [currentRect] is null, [currentRect] should be [newTarget].
    _currentRect ??= newTarget.clone();
    _previousRect = _currentRect!.clone();
    _targetRect = newTarget;
  }

  /// Current [TreeMapRendererElement] at a given animation percent time.
  TreeMapRendererElement<D> getCurrentRect(double animationPercent) {
    if (animationPercent == 1.0 || _previousRect == null) {
      _currentRect = _targetRect;
      _previousRect = _targetRect;
      return _currentRect!;
    }

    _currentRect!
        .updateAnimationPercent(_previousRect!, _targetRect, animationPercent);
    return _currentRect!;
  }
}
