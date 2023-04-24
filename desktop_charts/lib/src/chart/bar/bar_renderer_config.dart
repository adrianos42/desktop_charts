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

import '../base_chart.dart' show BaseChart, BaseChartState;
import '../layout/layout_view.dart' show LayoutViewPaintOrder;
import '../series_renderer.dart';
import 'bar_renderer.dart';
import 'bar_renderer_decorator.dart' show BarRendererDecorator;
import 'base_bar_renderer_config.dart'
    show BarGroupingType, BaseBarRendererConfig;

/// Configuration for a bar renderer.
@immutable
class BarRendererConfig<D> extends BaseBarRendererConfig<D> {
  const BarRendererConfig({
    BarGroupingType? groupingType,
    this.barRendererDecorator,
    super.barGroupInnerPadding = 2.0,
    super.customRendererId,
    super.layoutPaintOrder = LayoutViewPaintOrder.bar,
    super.minBarLength = 0.0,
    super.maxBarWidth,
    super.fillPattern,
    super.stackedBarPadding = 1.0,
    super.strokeWidth = 0.0,
    super.symbolRenderer,
    super.weightPattern,
  }) : super(groupingType: groupingType ?? BarGroupingType.grouped);

  /// Decorator for optionally decorating painted bars.
  final BarRendererDecorator<D>? barRendererDecorator;

  @override
  SeriesRenderer<D, S> build<S extends BaseChart<D>>({
    required BaseChartState<D, S> chartState,
    String? rendererId,
  }) {
    return BarRenderer<D, S>(
      chartState: chartState,
      config: this,
      rendererId: rendererId,
    );
  }

  @override
  bool operator ==(covariant BarRendererConfig<D> other) {
    return identical(this, other) ||
        barRendererDecorator == other.barRendererDecorator;
  }

  @override
  int get hashCode => barRendererDecorator.hashCode;
}
