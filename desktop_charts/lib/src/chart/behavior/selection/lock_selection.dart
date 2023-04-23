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
import '../../selection_model.dart' show SelectionModelType;
import '../chart_behavior.dart' show ChartBehavior, ChartBehaviorState;
import 'selection_trigger.dart' show SelectionTrigger;

/// Chart behavior that listens to tap event triggers and locks the specified
/// [SelectionModel]. This is used to prevent further updates to the selection
/// model, until it is unlocked again.
///
/// SelectionModels that can be updated:
///   info - To view the details of the selected items (ie: hover for web).
///   action - To select an item as an input, drill, or other selection.
///
/// You can add one LockSelection for each model type that you are updating.
/// Any previous LockSelection behavior for that selection model will be
/// removed.
class LockSelection<D> extends ChartBehavior<D> {
  const LockSelection({
    this.selectionModelType = SelectionModelType.info,
  });

  /// Type of selection model that should be updated by input events.
  final SelectionModelType selectionModelType;

  /// Type of input event that should trigger selection.
  SelectionTrigger get eventTrigger => SelectionTrigger.tap;

  @override
  String get role => 'LockSelection-$selectionModelType';

  @override
  ChartBehaviorState<D, S, LockSelection<D>> build<S extends BaseChart<D>>({
    required BaseChartState<D, S> chartState,
  }) {
    return _LockSelectionState<D, S>(
      behavior: this,
      chartState: chartState,
    );
  }
}

class _LockSelectionState<D, S extends BaseChart<D>>
    extends ChartBehaviorState<D, S, LockSelection<D>> {
  const _LockSelectionState({
    required super.behavior,
    required super.chartState,
  });

  bool _onSelect(Offset chartPoint) {
    final selectionModel =
        chartState.getSelectionModel(behavior.selectionModelType);

    // Do not lock the selection model if there is no selection. Locking nothing
    // would result in a very confusing user interface as the user tries to
    // interact with content on the chart.
    if (!selectionModel.locked && !selectionModel.hasAnySelection) {
      return false;
    }

    // Toggle the lock state.
    selectionModel.locked = !selectionModel.locked;

    // If the model was just unlocked, clear the selection to dismiss any stale
    // behavior elements. A hover card/etc. will appear after the user
    // triggers a gesture.
    if (!selectionModel.locked) {
      selectionModel.clearSelection();
    }

    return false;
  }

  @override
  Widget buildBehaviorWidget(BuildContext context) {
    // Setup the appropriate gesture listening.
    switch (behavior.eventTrigger) {
      case SelectionTrigger.tap:
        return GestureDetector(
          onTapUp: (event) => _onSelect(event.globalPosition),
        );
      default:
        throw ArgumentError('LockSelection does not support the event '
            'trigger "${behavior.eventTrigger}"');
    }
  }
}
