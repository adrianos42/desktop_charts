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
import '../chart_behavior.dart' show ChartBehavior;
import 'selection_trigger.dart' show SelectionTrigger;

/// Chart behavior that listens to tap event trigges and locks the specified
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
  LockSelection({this.selectionModelType = SelectionModelType.info}) {
    // Setup the appropriate gesture listening.
    switch (eventTrigger) {
      case SelectionTrigger.tap:
        //  _listener = GestureListener(onTapTest: _onTapTest, onTap: _onSelect);
        break;
      default:
        throw ArgumentError('LockSelection does not support the event '
            'trigger "$eventTrigger"');
    }
  }

  /// Type of selection model that should be updated by input events.
  final SelectionModelType selectionModelType;

  /// Type of input event that should trigger selection.
  final SelectionTrigger eventTrigger = SelectionTrigger.tap;

  late BaseChartState<D, BaseChart<D>> _chartState;

  bool _onSelect(Offset chartPoint) {
    final selectionModel = _chartState.getSelectionModel(selectionModelType);

    // Do not lock the selection model if there is no selection. Locking nothing
    // would result in a very confusing user interface as the user tries to
    // interact with content on the chart.
    if (!selectionModel.locked && !selectionModel.hasAnySelection) {
      return false;
    }

    // Toggle the lock state.
    selectionModel.locked = !selectionModel.locked;

    // If the model was just unlocked, clear the selection to dismiss any stale
    // behavior elements. A hovercard/etc. will appear after the user
    // triggers a gesture.
    if (!selectionModel.locked) {
      selectionModel.clearSelection();
    }

    return false;
  }

  @override
  void dispose() {}

  @override
  String get role => 'LockSelection-$selectionModelType';

  @override
  void attachTo<S extends BaseChart<D>>(BaseChartState<D, S> chartState) {
    _chartState = chartState;
  }

  @override
  Widget buildBehavior(BuildContext context) {
    return const SizedBox();
  }
}
