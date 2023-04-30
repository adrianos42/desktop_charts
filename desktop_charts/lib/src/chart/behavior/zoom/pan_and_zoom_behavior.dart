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

import 'dart:math' show min, max;

import 'package:flutter/widgets.dart';

import '../../base_chart.dart';
import '../../cartesian/cartesian_chart.dart'
    show CartesianChart, CartesianChartState;
import '../chart_behavior.dart' show ChartBehavior, ChartBehaviorState;
import 'pan_behavior.dart';
import 'panning_tick_provider.dart' show PanningTickProviderMode;

/// Adds domain axis panning and zooming support to the chart.
///
/// Zooming is supported for the web by mouse wheel events. Scrolling up zooms
/// the chart in, and scrolling down zooms the chart out. The chart can never be
/// zoomed out past the domain axis range.
///
/// Zooming is supported by pinch gestures for mobile devices.
///
/// Panning is supported by clicking and dragging the mouse for web, or tapping
/// and dragging on the chart for mobile devices.
@immutable
class PanAndZoomBehavior<D> extends PanBehavior<D> {
  const PanAndZoomBehavior();

  @override
  String get role => 'PanAndZoom';

  @override
  ChartBehaviorState<D, S, ChartBehavior<D>> build<S extends BaseChart<D>>({
    required BaseChartState<D, S> chartState,
  }) {
    return PanAndZoomBehaviorState<D, S, PanAndZoomBehavior<D>>(
      behavior: this,
      chartState: chartState,
    );
  }
}

class PanAndZoomBehaviorState<D, S extends BaseChart<D>,
    R extends PanAndZoomBehavior<D>> extends PanBehaviorState<D, S, R> {
  PanAndZoomBehaviorState({
    required super.behavior,
    required super.chartState,
  });

  CartesianChartState<D, CartesianChart<D>> get _chartState =>
      chartState as CartesianChartState<D, CartesianChart<D>>;

  /// Flag which is enabled to indicate that the user is "zooming" the chart.
  bool _isZooming = false;

  @protected
  bool get isZooming => _isZooming;

  /// Current zoom scaling factor for the behavior.
  double _scalingFactor = 1.0;

  /// Minimum scalingFactor to prevent zooming out beyond the data range.
  final _minScalingFactor = 1.0;

  /// Maximum scalingFactor to prevent zooming in so far that no data is
  /// visible.
  ///
  /// TODO: Dynamic max based on data range?
  final _maxScalingFactor = 5.0;

  @override
  bool onDragStart(Offset globalPosition) {
    super.onDragStart(globalPosition);

    // Save the current scaling factor to make zoom events relative.
    _scalingFactor = _chartState.domainAxis!.viewportScalingFactor;
    _isZooming = true;

    return true;
  }

  @override
  bool onDragUpdate(Offset globalPosition, double scale) {
    // Swipe gestures should be handled by the [PanBehavior].
    if (scale == 1.0) {
      _isZooming = false;
      return super.onDragUpdate(globalPosition, scale);
    }

    // No further events in this chain should be handled by [PanBehavior].
    cancelPanning();

    if (!_isZooming || lastPosition == null) {
      return false;
    }

    // Update the domain axis's viewport scale factor to zoom the chart.
    final domainAxis = _chartState.domainAxis;

    if (domainAxis == null) {
      return false;
    }

    // This is set during onDragUpdate and NOT onDragStart because we don't yet
    // know during onDragStart whether pan/zoom behavior is panning or zooming.
    // During zoom in / zoom out, domain tick provider set to return existing
    // cached ticks.
    domainAxisTickProvider.mode = PanningTickProviderMode.useCachedTicks;

    // Clamp the scale to prevent zooming out beyond the range of the data, or
    // zooming in so far that we show nothing useful.
    final newScalingFactor = min(
      max(_scalingFactor * scale, _minScalingFactor),
      _maxScalingFactor,
    );

    domainAxis.setViewportSettings(
      newScalingFactor,
      domainAxis.viewportTranslate,
      drawAreaWidth: _chartState.drawArea.width,
      drawAreaHeight: _chartState.drawArea.height,
    );

    _chartState.redraw(skipAnimation: true);

    return true;
  }

  @override
  bool onDragEnd(double velocity) {
    _isZooming = false;

    return super.onDragEnd(velocity);
  }
}
