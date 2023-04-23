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

import '../../../color.dart';
import '../../base_chart.dart'
    show BaseChartState, LifecycleListener, BaseChart;
import '../../processed_series.dart' show MutableSeries;
import '../../selection_model.dart' show SelectionModel, SelectionModelType;
import '../chart_behavior.dart'
    show ChartBehavior, BehaviorPosition, ChartBehaviorState;

/// Chart behavior that monitors the specified [SelectionModel] and darkens the
/// color for selected data.
///
/// This is typically used for bars and pies to highlight segments.
///
/// It is used in combination with SelectNearest to update the selection model
/// and expand selection out to the domain value.
@immutable
class DomainHighlighter<D> extends ChartBehavior<D> {
  const DomainHighlighter([
    this.selectionModelType = SelectionModelType.info,
  ]);

  final SelectionModelType selectionModelType;

  @override
  BehaviorPosition get position => BehaviorPosition.inside;

  @override
  String get role => 'domainHighlight-$selectionModelType';

  @override
  ChartBehaviorState<D, S, DomainHighlighter<D>> build<S extends BaseChart<D>>({
    required BaseChartState<D, S> chartState,
  }) {
    return _DomainHighlighterState<D, S>(
      behavior: this,
      chartState: chartState,
    );
  }
}

class _DomainHighlighterState<D, S extends BaseChart<D>>
    extends ChartBehaviorState<D, S, DomainHighlighter<D>> {
  _DomainHighlighterState({
    required super.behavior,
    required super.chartState,
  }) {
    chartState
        .getSelectionModel(behavior.selectionModelType)
        .addSelectionChangedListener(_selectionChanged);

    _lifecycleListener =
        LifecycleListener<D>(onPostprocess: _updateColorFunctions);

    chartState.addLifecycleListener(_lifecycleListener);
  }

  late LifecycleListener<D> _lifecycleListener;

  void _selectionChanged(SelectionModel<D> selectionModel) {
    chartState.redraw(skipAnimation: true);
  }

  void _updateColorFunctions(List<MutableSeries<D>> seriesList) {
    final SelectionModel<D> selectionModel =
        chartState.getSelectionModel(behavior.selectionModelType);

    for (final MutableSeries<D> series in seriesList) {
      final origColorFn = series.colorFn;

      if (origColorFn != null) {
        series.colorFn = (int? index) {
          final origColor = origColorFn(index);
          if (selectionModel.isDatumSelected(series, index)) {
            return origColor.darker;
          } else {
            return origColor;
          }
        };
      }
    }
  }

  @override
  void dispose() {
    chartState
        .getSelectionModel(behavior.selectionModelType)
        .removeSelectionChangedListener(_selectionChanged);
    chartState.removeLifecycleListener(_lifecycleListener);

    super.dispose();
  }
}
