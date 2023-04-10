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

import 'package:flutter/widgets.dart';

import '../../symbol_renderer.dart' show LineSymbolRenderer;
import '../base_chart.dart' show BaseChart, BaseChartState;
import '../layout/layout_view.dart' show LayoutViewPaintOrder;
import '../processed_series.dart' show MutableSeries;
import 'base_bar_renderer_config.dart'
    show BarGroupingType, BaseBarRendererConfig;
import 'bar_target_line_renderer.dart';
import '../series_renderer_config.dart';

/// Configuration for a bar target line renderer.
@immutable
class BarTargetLineRendererConfig<D> extends BaseBarRendererConfig<D> {
  const BarTargetLineRendererConfig({
    this.overDrawOuter,
    this.overDraw = 0.0,
    super.barGroupInnerPadding = 2.0,
    super.customRendererId,
    super.dashPattern,
    super.groupingType = BarGroupingType.grouped,
    super.layoutPaintOrder = LayoutViewPaintOrder.barTargetLine,
    super.minBarLength = 0.0,
    super.strokeWidth = 2.0,
    super.symbolRenderer = const LineSymbolRenderer(),
    super.weightPattern,
  });

  /// The width that the line will extend beyond the bandwidth at the
  /// edges of the bar group.
  ///
  /// If set, this overrides overDraw for the beginning side of the first bar
  /// target line in the group, and the ending side of the last bar target line.
  /// overDraw will be used for overdrawing the target lines for interior
  /// sides of the bars.
  final double? overDrawOuter;

  /// The number of pixels that the line will extend beyond the bandwidth for
  /// every bar in a group.
  final double overDraw;

  @override
  Widget build<S extends BaseChart<D>>(
    BuildContext context, {
    required Key key,
    required BaseChartState<D, S> chartState,
    required List<MutableSeries<D>> seriesList,
    String? rendererId,
  }) {
    return _BarTargetLineRenderObjectWidget(
      chartState: chartState,
      config: this,
      key: key,
      seriesList: seriesList,
      rendererId: rendererId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is BarTargetLineRendererConfig &&
        other.overDrawOuter == overDrawOuter &&
        other.overDraw == overDraw &&
        super == other;
  }

  @override
  int get hashCode => Object.hash(overDrawOuter, overDraw);
}

class _BarTargetLineRenderObjectWidget<D, S extends BaseChart<D>>
    extends BaseSeriesRenderObjectWidget<D, S, BarTargetLineRenderer<D, S>,
        BarTargetLineRendererConfig<D>> {
  const _BarTargetLineRenderObjectWidget({
    required super.chartState,
    required super.config,
    required super.key,
    required super.rendererId,
    required super.seriesList,
  });

  @override
  BarTargetLineRenderer<D, S> createRenderObject(BuildContext context) =>
      BarTargetLineRenderer<D, S>(
        rendererId: rendererId,
        config: config,
        chartState: chartState,
        seriesList: seriesList,
      );
}
