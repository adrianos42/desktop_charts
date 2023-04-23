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
import 'bar_label_decorator.dart' show BarLabelDecorator;
import 'bar_lane_renderer.dart' show BarLaneRenderer;
import 'bar_renderer_config.dart' show BarRendererConfig;
import 'base_bar_renderer_config.dart' show BarGroupingType;

/// Configuration for a bar lane renderer.
@immutable
class BarLaneRendererConfig extends BarRendererConfig<String> {
  const BarLaneRendererConfig({
    this.emptyLaneLabel = 'No data',
    this.mergeEmptyLanes = false,
    this.renderNegativeLanes = false,
    // TODO this.backgroundBarColor = themeData.noDataColor,
    this.backgroundBarColor = const Color(0xff000000),
    super.barRendererDecorator,
    super.customRendererId,
    super.groupingType = BarGroupingType.grouped,
    super.layoutPaintOrder = LayoutViewPaintOrder.bar,
    super.minBarLength = 0,
    super.fillPattern,
    super.stackedBarPadding = 1,
    super.strokeWidth = 0.0,
    super.symbolRenderer,
    super.weightPattern,
  });

  /// The color of background bars.
  final Color backgroundBarColor;

  /// Label text to draw on a merged empty lane.
  ///
  /// This will only be drawn if all of the measures for a domain are null, and
  /// [mergeEmptyLanes] is enabled.
  ///
  /// The renderer must be configured with a [BarLabelDecorator] for this label
  /// to be drawn.
  final String emptyLaneLabel;

  /// Whether or not all lanes for a given domain value should be merged into
  /// one wide lane if all measure values for said domain are null.
  final bool mergeEmptyLanes;

  /// Whether or not to render negative bar lanes on bars with negative values
  final bool renderNegativeLanes;

  @override
  SeriesRenderer<String, S> build<S extends BaseChart<String>>({
    required BaseChartState<String, S> chartState,
    String? rendererId,
  }) {
    return BarLaneRenderer<String, S>(
      rendererId: rendererId,
      config: this,
      chartState: chartState,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is BarLaneRendererConfig &&
        other.backgroundBarColor == backgroundBarColor &&
        other.emptyLaneLabel == emptyLaneLabel &&
        other.mergeEmptyLanes == mergeEmptyLanes &&
        other.renderNegativeLanes == renderNegativeLanes &&
        super == other;
  }

  @override
  int get hashCode => Object.hash(
        backgroundBarColor,
        emptyLaneLabel,
        mergeEmptyLanes,
        renderNegativeLanes,
      );
}
