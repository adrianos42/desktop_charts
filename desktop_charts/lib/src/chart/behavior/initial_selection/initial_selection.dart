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

import '../../base_chart.dart'
    show BaseChartState, LifecycleListener, BaseChart;
import '../../processed_series.dart' show MutableSeries;
import '../../selection_model.dart' show SelectionModel, SelectionModelType;
import '../../series_datum.dart' show SeriesDatumConfig;
import '../chart_behavior.dart' show ChartBehavior;

/// Behavior that sets initial selection.
class InitialSelection<D> extends ChartBehavior<D> {
  // TODO : When the series changes, if the user does not also
  // change the index the wrong item could be highlighted.
  InitialSelection({
    this.selectionModelType = SelectionModelType.info,
    this.selectedDataConfig,
    this.selectedSeriesConfig,
    this.shouldPreserveSelectionOnDraw = false,
  }) {
    _lifecycleListener = LifecycleListener<D>(onData: _setInitialSelection);
  }

  final SelectionModelType selectionModelType;

  /// List of series id of initially selected series.
  final List<String>? selectedSeriesConfig;

  /// List of [SeriesDatumConfig] that represents the initially selected datums.
  final List<SeriesDatumConfig<D>>? selectedDataConfig;

  /// Preserve selection on every draw. False by default and only preserves
  /// selection until the fist draw or redraw call.
  final bool shouldPreserveSelectionOnDraw;

  late BaseChartState<D, BaseChart<D>> _chartState;
  late LifecycleListener<D> _lifecycleListener;
  bool _firstDraw = true;

  void _setInitialSelection(List<MutableSeries<D>> seriesList) {
    if (!_firstDraw && !shouldPreserveSelectionOnDraw) {
      return;
    }

    _firstDraw = false;

    final immutableModel = SelectionModel<D>.fromConfig(
      selectedDataConfig,
      selectedSeriesConfig,
      seriesList,
    );

    _chartState.getSelectionModel(selectionModelType).updateSelection(
          immutableModel.selectedDatum,
          immutableModel.selectedSeries,
          notifyListeners: false,
        );
  }

  @override
  void attachTo<S extends BaseChart<D>>(BaseChartState<D, S> chartState) {
    _chartState = chartState;
    _chartState.addLifecycleListener(_lifecycleListener);
  }

  @override
  void dispose() {
    _chartState.removeLifecycleListener(_lifecycleListener);
  }

  @override
  String get role => 'InitialSelection-$selectionModelType';

  @override
  Widget buildBehavior(BuildContext context) {
    return const SizedBox();
  }
}
