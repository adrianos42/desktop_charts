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

import '../../../color.dart';
import '../../base_chart.dart';
import '../../processed_series.dart';
import '../../selection_model.dart';
import '../chart_behavior.dart' show ChartBehavior, ChartBehaviorState;

/// Chart behavior that monitors the specified [SelectionModel] and outlines the
/// selected data.
///
/// This is typically used for treemap charts to highlight nodes.
/// For bars and pies, prefers to use [DomainHighlighter] for UX consistency.
@immutable
class DomainOutliner<D> extends ChartBehavior<D> {
  const DomainOutliner({
    this.selectionType = SelectionModelType.info,
    this.defaultStroke = 2.0,
    this.strokePadding = 1.0,
  });

  final SelectionModelType selectionType;

  /// Default stroke width of the outline if the series has no stroke width
  /// function.
  ///
  /// When no stroke width function is provided, this value will be used as
  /// is. [strokePadding] will not be added to [defaultStroke].
  final double defaultStroke;

  /// Additional stroke width added to the outline of the selected data.
  ///
  /// This value is only used when the series has a stroke width function
  /// defined.
  final double strokePadding;

  @override
  String get role => 'domainOutliner-$selectionType';

  @override
  ChartBehaviorState<D, S, ChartBehavior<D>> build<S extends BaseChart<D>>({
    required BaseChartState<D, S> chartState,
  }) {
    return _DomainHighlighterState<D, S>(
      behavior: this,
      chartState: chartState,
    );
  }
}

class _DomainHighlighterState<D, S extends BaseChart<D>>
    extends ChartBehaviorState<D, S, DomainOutliner<D>> {
  _DomainHighlighterState({
    required super.behavior,
    required super.chartState,
  }) {
    _lifecycleListener = LifecycleListener<D>(onPostprocess: _outline);

    chartState.addLifecycleListener(_lifecycleListener);
    chartState
        .getSelectionModel(behavior.selectionType)
        .addSelectionChangedListener(_selectionChange);
  }

  late LifecycleListener<D> _lifecycleListener;

  void _selectionChange(SelectionModel<D> selectionModel) {
    chartState.redraw(skipAnimation: true);
  }

  void _outline(List<MutableSeries<D>> seriesList) {
    final selectionModel = chartState.getSelectionModel(behavior.selectionType);

    for (final series in seriesList) {
      final strokeWidthFn = series.strokeWidthFn;
      final colorFn = series.colorFn;

      if (colorFn != null) {
        series.colorFn = (int? index) {
          final color = colorFn(index);
          return selectionModel.isDatumSelected(series, index)
              ? color.darker
              : color;
        };
      }

      if (strokeWidthFn != null) {
        series.strokeWidthFn = (int? index) {
          final strokeWidth = strokeWidthFn(index);
          if (!selectionModel.isDatumSelected(series, index)) {
            return strokeWidth;
          }
          return strokeWidth == null
              ? behavior.defaultStroke
              : strokeWidth + behavior.strokePadding;
        };
      }
    }
  }

  @override
  void dispose() {
    chartState
        .getSelectionModel(behavior.selectionType)
        .removeSelectionChangedListener(_selectionChange);
    chartState.removeLifecycleListener(_lifecycleListener);

    super.dispose();
  }
}
