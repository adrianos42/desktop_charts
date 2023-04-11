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

import 'package:flutter/widgets.dart';

import '../../symbol_renderer.dart';
import '../../theme.dart';
import '../base_chart.dart' show BaseChart, BaseChartState;
import '../layout/layout_view.dart';
import '../processed_series.dart' show MutableSeries;
import '../series_renderer_config.dart';
import 'base_treemap_renderer.dart';
import 'dice_treemap_renderer.dart';
import 'slice_dice_treemap_renderer.dart';
import 'slice_treemap_renderer.dart';
import 'squarified_treemap_renderer.dart';
import 'treemap_label_decorator.dart';

/// Configuration for a [BaseTreeMapRenderer].
class TreeMapRendererConfig<D> implements SeriesRendererConfig<D> {
  TreeMapRendererConfig({
    this.customRendererId,
    this.patternStrokeWidth = 1.0,
    this.strokeWidth = 1.0,
    this.layoutPaintOrder = LayoutViewPaintOrder.treeMap,
    this.rectPadding = _defaultRectPadding,
    this.tileType = TreeMapTileType.squarified,
    this.labelDecorator,
    Color? strokeColor,
    SymbolRenderer? symbolRenderer,
  })  : strokeColor =
            strokeColor ?? const ChartsThemeData.fallbackw().foreground,
        symbolRenderer = symbolRenderer ?? const RectSymbolRenderer();

  /// Default padding of a treemap rectangle.
  static const _defaultRectPadding = EdgeInsets.only(
    top: 26.0,
    left: 4.0,
    right: 4.0,
    bottom: 4.0,
  );

  @override
  final String? customRendererId;

  @override
  final SymbolRenderer symbolRenderer;

  @override
  final rendererAttributes = RendererAttributes();

  /// Tiling algorithm, which is the way to divide a region into sub-regions of
  /// specified areas, in the treemap.
  final TreeMapTileType tileType;

  /// The order to paint this renderer on the canvas.
  final int layoutPaintOrder;

  /// Padding of the treemap rectangle.
  final EdgeInsets rectPadding;

  /// Stroke width of the border of the treemap rectangle.
  final double strokeWidth;

  /// Stroke color of the border of the treemap rectangle.
  final Color strokeColor;

  /// Pattern stroke width of the treemap rectangle.
  final double patternStrokeWidth;

  /// Decorator for optionally decorating treemap rectangle label.
  final TreeMapLabelDecorator<D>? labelDecorator;

  @override
  Widget build<S extends BaseChart<D>>(
    BuildContext context, {
    required Key key,
    required BaseChartState<D, S> chartState,
    required List<MutableSeries<D>> seriesList,
    String? rendererId,
  }) {
    switch (tileType) {
      case TreeMapTileType.dice:
        return _DiceTreeMapRenderObjectWidget<D, S>(
          config: this,
          rendererId: rendererId ?? customRendererId,
          chartState: chartState,
          seriesList: seriesList,
          key: key,
        );
      case TreeMapTileType.slice:
        return _SliceTreeMapRenderObjectWidget<D, S>(
          config: this,
          rendererId: rendererId ?? customRendererId,
          chartState: chartState,
          seriesList: seriesList,
          key: key,
        );
      case TreeMapTileType.sliceDice:
        return _SliceDiceMapRenderObjectWidget<D, S>(
          config: this,
          rendererId: customRendererId,
          chartState: chartState,
          seriesList: seriesList,
          key: key,
        );
      default:
        return _SquarifiedTreeMapRenderObjectWidget<D, S>(
          config: this,
          rendererId: customRendererId,
          chartState: chartState,
          seriesList: seriesList,
          key: key,
        );
    }
  }
}

/// Tiling algorithm, which is the way to divide a region into subregions of
/// specified areas, in a treemap.
///
/// * [dice] - Renders rectangles in dice layout.
/// * [slice] - Renders rectangles in slice layout.
/// * [sliceDice] - Renders rectangles in slice-and-dice layout.
/// * [squarified] - Renders rectangles such that their aspect-ratios approach
/// one as close as possible.
enum TreeMapTileType { dice, slice, sliceDice, squarified }

class _DiceTreeMapRenderObjectWidget<D, S extends BaseChart<D>>
    extends BaseSeriesRenderObjectWidget<D, S, DiceTreeMapRenderer<D, S>,
        TreeMapRendererConfig<D>> {
  const _DiceTreeMapRenderObjectWidget({
    required super.chartState,
    required super.config,
    required super.key,
    required super.rendererId,
    required super.seriesList,
  });

  @override
  DiceTreeMapRenderer<D, S> createRenderObject(BuildContext context) =>
      DiceTreeMapRenderer<D, S>(
        rendererId: rendererId,
        config: config,
        chartState: chartState,
        seriesList: seriesList,
      );
}

class _SliceTreeMapRenderObjectWidget<D, S extends BaseChart<D>>
    extends BaseSeriesRenderObjectWidget<D, S, SliceTreeMapRenderer<D, S>,
        TreeMapRendererConfig<D>> {
  const _SliceTreeMapRenderObjectWidget({
    required super.chartState,
    required super.config,
    required super.key,
    required super.rendererId,
    required super.seriesList,
  });

  @override
  SliceTreeMapRenderer<D, S> createRenderObject(BuildContext context) =>
      SliceTreeMapRenderer<D, S>(
        rendererId: rendererId,
        config: config,
        chartState: chartState,
        seriesList: seriesList,
      );
}

class _SliceDiceMapRenderObjectWidget<D, S extends BaseChart<D>>
    extends BaseSeriesRenderObjectWidget<D, S, SliceDiceTreeMapRenderer<D, S>,
        TreeMapRendererConfig<D>> {
  const _SliceDiceMapRenderObjectWidget({
    required super.chartState,
    required super.config,
    required super.key,
    required super.rendererId,
    required super.seriesList,
  });

  @override
  SliceDiceTreeMapRenderer<D, S> createRenderObject(BuildContext context) =>
      SliceDiceTreeMapRenderer<D, S>(
        rendererId: rendererId,
        config: config,
        chartState: chartState,
        seriesList: seriesList,
      );
}

class _SquarifiedTreeMapRenderObjectWidget<D, S extends BaseChart<D>>
    extends BaseSeriesRenderObjectWidget<D, S, SquarifiedTreeMapRenderer<D, S>,
        TreeMapRendererConfig<D>> {
  const _SquarifiedTreeMapRenderObjectWidget({
    required super.chartState,
    required super.config,
    required super.key,
    required super.rendererId,
    required super.seriesList,
  });

  @override
  SquarifiedTreeMapRenderer<D, S> createRenderObject(BuildContext context) =>
      SquarifiedTreeMapRenderer<D, S>(
        rendererId: rendererId,
        config: config,
        chartState: chartState,
        seriesList: seriesList,
      );
}
