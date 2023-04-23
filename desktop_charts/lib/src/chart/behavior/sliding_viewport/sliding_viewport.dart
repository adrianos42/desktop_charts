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

import '../../base_chart.dart' show BaseChartState;
import '../../base_chart.dart' show BaseChart;
import '../../cartesian/cartesian_chart.dart'
    show CartesianChartState, CartesianChart;
import '../../selection_model.dart' show SelectionModel, SelectionModelType;
import '../chart_behavior.dart' show ChartBehavior, ChartBehaviorState;

/// Chart behavior that centers the viewport on the selected domain.
///
/// It is used in combination with SelectNearest to update the selection model
/// and notify this behavior to update the viewport on selection change.
///
/// This behavior can only be used on [CartesianChart].
@immutable
class SlidingViewport<D> extends ChartBehavior<D> {
  const SlidingViewport({this.selectionModelType = SelectionModelType.info});

  final SelectionModelType selectionModelType;

  @override
  String get role => 'slidingViewport-$selectionModelType';

  @override
  ChartBehaviorState<D, S, SlidingViewport<D>> build<S extends BaseChart<D>>({
    required BaseChartState<D, S> chartState,
  }) {
    return _SlidingViewportState<D, S>(
      behavior: this,
      chartState: chartState,
    );
  }
}

class _SlidingViewportState<D, S extends BaseChart<D>>
    extends ChartBehaviorState<D, S, SlidingViewport<D>> {
  _SlidingViewportState({
    required super.behavior,
    required super.chartState,
  }) {
    chartState
        .getSelectionModel(behavior.selectionModelType)
        .addSelectionChangedListener(_selectionChanged);
  }

  CartesianChartState<D, CartesianChart<D>> get _chartState =>
      chartState as CartesianChartState<D, CartesianChart<D>>;

  void _selectionChanged(SelectionModel<D> selectionModel) {
    if (selectionModel.hasAnySelection == false) {
      return;
    }

    // Calculate current viewport center and determine the translate pixels
    // needed based on the selected domain value's location and existing amount
    // of translate pixels.
    final domainAxis = _chartState.domainAxis!;
    final selectedDatum = selectionModel.selectedDatum.first;
    final domainLocation = domainAxis
        .getLocation(selectedDatum.series.domainFn(selectedDatum.index))!;
    final viewportCenter =
        domainAxis.range!.start + (domainAxis.range!.width / 2);
    final translate =
        domainAxis.viewportTranslate + (viewportCenter - domainLocation);
    domainAxis.setViewportSettings(domainAxis.viewportScalingFactor, translate);

    _chartState.redraw();
  }

  @override
  void dispose() {
    _chartState
        .getSelectionModel(behavior.selectionModelType)
        .removeSelectionChangedListener(_selectionChanged);

    super.dispose();
  }
}
