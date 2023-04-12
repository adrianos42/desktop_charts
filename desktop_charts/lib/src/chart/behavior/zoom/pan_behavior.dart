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

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../base_chart.dart' show BaseChart, BaseChartState;
import '../../cartesian/axis/axis.dart' show CartesianAxis;
import '../../cartesian/cartesian_chart.dart'
    show CartesianChart, CartesianChartState;
import '../chart_behavior.dart' show ChartBehavior;
import 'panning_tick_provider.dart';

/// Adds domain axis panning support to a chart.
///
/// Panning is supported by clicking and dragging the mouse for web, or tapping
/// and dragging on the chart for mobile devices.
class PanBehavior<D> extends ChartBehavior<D> {
  /// Wrapped domain tick provider for pan and zoom behavior.
  late PanningTickProvider<D> _domainAxisTickProvider;

  @protected
  PanningTickProvider<D> get domainAxisTickProvider => _domainAxisTickProvider;

  /// The chart to which the behavior is attached.
  @protected
  late CartesianChartState<D, CartesianChart<D>> chartState;

  /// Flag which is enabled to indicate that the user is "panning" the chart.
  bool _isPanning = false;

  @protected
  bool get isPanning => _isPanning;

  /// Last position of the mouse/tap that was used to adjust the scale translate
  /// factor.
  Offset? _lastPosition;

  @protected
  Offset? get lastPosition => _lastPosition;

  /// Optional callback that is invoked at the end of panning ([onPanEnd]).
  PanningCompletedCallback? _panningCompletedCallback;

  set panningCompletedCallback(PanningCompletedCallback? callback) {
    _panningCompletedCallback = callback;
  }

  Map<Type, GestureRecognizerFactory> get _gestures {
    final Map<Type, GestureRecognizerFactory> gestures =
        <Type, GestureRecognizerFactory>{};

    gestures[ScaleGestureRecognizer] =
        GestureRecognizerFactoryWithHandlers<ScaleGestureRecognizer>(
      () => ScaleGestureRecognizer(debugOwner: this),
      (ScaleGestureRecognizer instance) {
        instance.onStart = (details) => onDragStart(details.localFocalPoint);
        instance.onUpdate =
            (details) => onDragUpdate(details.focalPoint, details.scale);
        instance.onEnd = (details) => onDragEnd(0.0);
      },
    );

    return gestures;
  }

  @protected
  bool onDragStart(Offset globalPosition) {
    onPanStart();

    _lastPosition = globalPosition;
    _isPanning = true;
    return true;
  }

  @protected
  bool onDragUpdate(Offset globalPosition, double scale) {
    if (!_isPanning || _lastPosition == null) {
      return false;
    }

    // Pinch gestures should be handled by the [PanAndZoomBehavior].
    if (scale != 1.0) {
      _isPanning = false;
      return false;
    }

    // Update the domain axis's viewport translate to pan the chart.
    final domainAxis = chartState.domainAxis;

    if (domainAxis == null) {
      return false;
    }

    // This is set during onDragUpdate and NOT onDragStart because we don't yet
    // know during onDragStart whether pan/zoom behavior is panning or zooming.
    // During panning, domain tick provider set to generate ticks with locked
    // steps.
    _domainAxisTickProvider.mode = PanningTickProviderMode.stepSizeLocked;

    final domainScalingFactor = domainAxis.viewportScalingFactor;

    var domainChange = 0.0;
    if (domainAxis.isVertical) {
      domainChange =
          domainAxis.viewportTranslate + globalPosition.dy - _lastPosition!.dy;
    } else {
      domainChange =
          domainAxis.viewportTranslate + globalPosition.dx - _lastPosition!.dx;
    }

    domainAxis.setViewportSettings(
      domainScalingFactor,
      domainChange,
      drawAreaWidth: chartState.drawArea.width,
      drawAreaHeight: chartState.drawArea.height,
    );

    _lastPosition = globalPosition;

    chartState.redraw(skipAnimation: true, skipLayout: true);
    return true;
  }

  @protected
  bool onDragEnd(
    double velocity,
  ) {
    onPanEnd();
    return true;
  }

  @protected
  void onPanStart() {
    // When panning starts, measure tick provider should not update ticks.
    // This is still needed because axis internally updates the tick location
    // after the tick provider generates the ticks. If we do not tell the axis
    // not to update the location of the measure axes, we get a jittery effect
    // as the measure axes location changes ever so slightly during pan/zoom.
    chartState.getMeasureAxis().lockAxis = true;
    chartState
        .getMeasureAxis(axisId: CartesianAxis.secondaryMeasureAxisId)
        .lockAxis = true;
  }

  @protected
  void onPanEnd() {
    cancelPanning();

    // When panning stops, allow tick provider to update ticks, and then
    // request redraw.
    _domainAxisTickProvider.mode = PanningTickProviderMode.passThrough;

    chartState.getMeasureAxis().lockAxis = false;
    chartState
        .getMeasureAxis(axisId: CartesianAxis.secondaryMeasureAxisId)
        .lockAxis = false;
    chartState.redraw();

    _panningCompletedCallback?.call();
  }

  /// Cancels the handling of any current panning event.
  void cancelPanning() {
    _isPanning = false;
  }

  final FocusNode _focusNode = FocusNode();

  bool _controlDown = false;

  @override
  void attachTo<S extends BaseChart<D>>(BaseChartState<D, S> chartState) {
    if (chartState is! CartesianChartState<D, CartesianChart<D>>) {
      throw ArgumentError(
          'PanBehavior can only be attached to a CartesianChart<D>');
    }

    this.chartState = chartState as CartesianChartState<D, CartesianChart<D>>;

  }

  /// Removes the behavior from a chart.
  @override
  void dispose() {
    // Restore the default autoViewport state.
    chartState.domainAxis!.autoViewport = true;

    // Restore the original tick providers
    chartState.domainAxis!.tickProvider = _domainAxisTickProvider.tickProvider;

    _focusNode.dispose();
  }

  @override
  String get role => 'Pan';

  @mustCallSuper
  @override
  Widget buildBehavior(BuildContext context) {
    // Disable the autoViewport feature to enable panning.
    this.chartState.domainAxis!.autoViewport = false;

    // Wrap domain axis tick provider with the panning behavior one.
    _domainAxisTickProvider =
        PanningTickProvider<D>(this.chartState.domainAxis!.tickProvider!);
    this.chartState.domainAxis!.tickProvider = _domainAxisTickProvider;
    
    return MouseRegion(
      onHover: null,
      hitTestBehavior: HitTestBehavior.translucent,
      child: RawGestureDetector(
        gestures: _gestures,
        behavior: HitTestBehavior.translucent,
        child: KeyboardListener(
          onKeyEvent: (event) {
            if (event.logicalKey == LogicalKeyboardKey.controlLeft ||
                event.logicalKey == LogicalKeyboardKey.controlRight) {
              if (event is KeyDownEvent) {
                _controlDown = true;
              } else if (event is KeyUpEvent) {
                _controlDown = false;
              }
            }
          },
          focusNode: _focusNode,
          autofocus: true,
          child: Listener(
            onPointerSignal: (event) {
              if (event is PointerScrollEvent) {
                onDragStart(event.position);

                if (_controlDown) {
                  final delta = event.scrollDelta.dy;
                  final double zoomScale = -1.0 / delta;
                  onDragUpdate(Offset.zero, 1.0 + zoomScale);
                } else {
                  onDragUpdate(
                    (!chartState.domainAxis!.isVertical
                        ? event.position -
                            Offset(
                              event.scrollDelta.dy,
                              event.scrollDelta.dx,
                            )
                        : event.position - event.scrollDelta),
                    1.0,
                  );
                }

                onDragEnd(0.0);
              }
            },
            behavior: HitTestBehavior.translucent,
            child: const Center(
              child: SizedBox(),
            ),
          ),
        ),
      ),
    );
  }
}

/// Callback for when panning is completed.
typedef PanningCompletedCallback = void Function();
