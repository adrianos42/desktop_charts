// Copyright (C) 2023 Adriano Souza (adriano.souza113@gmail.com)

// Copyright 2021 the Charts project authors. Please see the AUTHORS file
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
import '../base_chart.dart' show BaseChart, BaseChartState;
import '../layout/layout_view.dart';
import '../processed_series.dart' show MutableSeries;
import '../series_renderer_config.dart';
import 'link_renderer.dart' show LinkRenderer;

/// Configuration for a [SankeyRenderer].
class LinkRendererConfig<D> extends LayoutViewConfig
    implements SeriesRendererConfig<D> {
  LinkRendererConfig({
    this.customRendererId,
    this.layoutPaintOrder = LayoutViewPaintOrder.bar,
    SymbolRenderer? symbolRenderer,
  }) : symbolRenderer = symbolRenderer ?? const RectSymbolRenderer();

  @override
  final String? customRendererId;

  @override
  final SymbolRenderer symbolRenderer;

  @override
  final RendererAttributes rendererAttributes = RendererAttributes();

  /// The order to paint this renderer on the canvas.
  final int layoutPaintOrder;

  @override
  Widget build<S extends BaseChart<D>>(
    BuildContext context, {
    required Key key,
    required BaseChartState<D, S> chartState,
    required List<MutableSeries<D>> seriesList,
    String? rendererId,
  }) {
    return _LinkRenderObjectWidget(
      chartState: chartState,
      config: this,
      key: key,
      rendererId: rendererId,
      seriesList: seriesList,
    );
  }
}

class _LinkRenderObjectWidget<D, S extends BaseChart<D>>
    extends BaseSeriesRenderObjectWidget<D, S, LinkRenderer<D, S>,
        LinkRendererConfig<D>> {
  const _LinkRenderObjectWidget({
    required super.chartState,
    required super.config,
    required super.key,
    required super.rendererId,
    required super.seriesList,
  });

  @override
  LinkRenderer<D, S> createRenderObject(BuildContext context) =>
      LinkRenderer<D, S>(
        rendererId: rendererId,
        config: config,
        chartState: chartState,
        seriesList: seriesList,
      );
}
