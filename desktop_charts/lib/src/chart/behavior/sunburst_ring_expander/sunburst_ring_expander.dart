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

import '../../base_chart.dart' show BaseChartState, BaseChart;
import '../../selection_model.dart' show SelectionModel, SelectionModelType;
import '../chart_behavior.dart' show ChartBehavior, ChartBehaviorState;

/// Expands the initially displayed outer ring to show subset of data in one
/// final ring.
class SunburstRingExpander<D> extends ChartBehavior<D> {
  SunburstRingExpander([this.selectionModelType = SelectionModelType.action]);

  final SelectionModelType selectionModelType;

  //late SunburstChartState<D> _chartState;

  void _selectionChanged(SelectionModel<D> selectionModel) {
    if (selectionModel.selectedDatum.isNotEmpty) {
      // _chartState.expandNode(selectionModel.selectedDatum.first.datum);
      // _chartState.redraw(skipLayout: true, skipAnimation: true);
    }
  }

  @override
  void attachTo<S extends BaseChart<D>>(BaseChartState<D, S> chartState) {
    // _chartState = chartState as SunburstChartState<D>;

    // _chartState
    //     .getSelectionModel(selectionModelType)
    //     .addSelectionChangedListener(_selectionChanged);
  }

  @override
  void dispose() {
    // _chartState
    //     .getSelectionModel(selectionModelType)
    //     .addSelectionUpdatedListener(_selectionChanged);
  }

  @override
  Widget buildBehavior2(BuildContext context) {
    return const SizedBox();
  }

  @override
  String get role => 'sunburstRingExpander-$selectionModelType';

  @override
  ChartBehaviorState<D, S, ChartBehavior<D>> build<S extends BaseChart<D>>({
    required BaseChartState<D, S> chartState,
  }) {
    // TODO: implement build
    throw UnimplementedError();
  }
}
