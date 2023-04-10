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
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../data/tree.dart';
import '../base_chart.dart' show BaseChart;
import 'base_treemap_renderer.dart';
import 'treemap_renderer_config.dart';

/// A treemap renderer that renders a squarified treemap.
class SquarifiedTreeMapRenderer<D, S extends BaseChart<D>>
    extends BaseTreeMapRenderer<D, S> {
  SquarifiedTreeMapRenderer({
    String? rendererId,
    TreeMapRendererConfig<D>? config,
    required super.chartState,
    required super.seriesList,
  }) : super(
          config: config ??
              TreeMapRendererConfig(
                tileType: TreeMapTileType.squarified,
              ),
          rendererId: rendererId ?? BaseTreeMapRenderer.defaultRendererId,
        );

  /// Golden ratio.
  final _ratio = 0.5 * (1.0 + math.sqrt(5.0));

  /// Uses squarification as the tiling algorithm for this tree map.
  ///
  /// The idea is to present treemap layouts in which the rectangles approximate
  /// squares.
  ///
  /// For more information about squarify technique, see:
  /// Squarified Treemaps:
  /// https://www.win.tue.nl/~vanwijk/stm.pdf
  /// Squarify algorithm from Charted:
  /// https://github.com/google/charted/blob/948ba890fc75e985b80ad0fc826cfc13ff55b633/lib/layout/src/treemap_layout.dart#L156
  @override
  void tile(TreeNode<Object> node) {
    final children = node.children;
    if (children.isNotEmpty) {
      final remainingNodes = Queue.of(children);
      Rect rect = availableLayoutBoundingRect(node);
      final analyzer = _SquarifyRatioAnalyzer(_ratio, areaForTreeNode);

      double bestScore = double.infinity;
      double width = math.min(rect.width, rect.height);
      final measure = measureForTreeNode(node);
      final scaleFactor =
          measure == 0.0 ? 0.0 : areaForRectangle(rect) / measure;
      scaleArea(children, scaleFactor);

      while (remainingNodes.isNotEmpty) {
        final child = remainingNodes.first;
        analyzer.addNode(child);
        final score = analyzer.worst(width).toDouble();

        // Adding a child rectangle improves score for the aspect ratio .
        if (score <= bestScore) {
          remainingNodes.removeFirst();
          bestScore = score;
        } else {
          analyzer.removeLast();
          rect = position(analyzer.nodes, rect, width, analyzer.layoutArea);
          width = math.min(rect.width, rect.height);
          analyzer.reset();
          bestScore = double.infinity;
        }
      }
      if (analyzer.nodes.isNotEmpty) {
        position(analyzer.nodes, rect, width, analyzer.layoutArea);
        analyzer.reset();
      }
    }
  }
}

/// An analyzer that computes whether adding a node to a layout can improve the
/// aspect ratio of the layout.
class _SquarifyRatioAnalyzer {
  _SquarifyRatioAnalyzer(this._ratio, this._areaFn);

  /// A accessor function that returns area of a [TreeNode].
  final AreaFn _areaFn;

  /// Target aspect ratio.
  final double _ratio;

  /// List of processing nodes.
  final nodes = <TreeNode<Object>>[];

  double _layoutArea = 0.0;

  /// Adds a node for processing.
  void addNode(TreeNode<Object> node) {
    nodes.add(node);
    _layoutArea += _areaFn(node);
  }

  /// Removes the last node added for processing.
  void removeLast() {
    _layoutArea -= _areaFn(nodes.removeLast());
  }

  /// Allocated area for laying out processing [nodes].
  double get layoutArea => _layoutArea;

  /// Aspect-ratio score for the list of processing [nodes] in a given [width].
  ///
  /// [width] is defined as the smallest side of a rectangle.
  ///
  /// Underlying equation:
  ///   max(w^2 * r_max * ratio / (r_layout^2),
  ///     r_layout^2 / (w^2 * r_min * ratio)).
  double worst(double width) {
    double rMin = double.infinity;
    double rMax = 0.0;

    // Finds rMin (i.e minimum area) and rMax (i.e maximum area) in [nodes].
    for (final node in nodes) {
      final area = _areaFn(node).toDouble();
      if (area <= 0.0) {
        continue;
      }
      if (area < rMin) {
        rMin = area;
      }
      if (area > rMax) {
        rMax = area;
      }
    }
    final sqWidth = _square(width);
    final sqArea = _square(_layoutArea);
    return sqArea > 0.0
        ? math.max(sqWidth * rMax * _ratio / sqArea,
            sqArea / (sqWidth * rMin * _ratio))
        : double.infinity;
  }

  void reset() {
    nodes.clear();
    _layoutArea = 0.0;
  }

  /// Calculates the square of a number [n].
  double _square(double n) => n * n;
}

/// A function type that returns area for a tree [node].
typedef AreaFn = double Function(TreeNode<Object> node);
