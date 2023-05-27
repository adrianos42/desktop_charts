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

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../base_chart.dart' show BaseChart, BaseChartState;
import '../../cartesian/axis/axis.dart' show CartesianAxis;
import '../../cartesian/cartesian_chart.dart'
    show CartesianChart, CartesianChartState;
import '../chart_behavior.dart' show ChartBehavior, ChartBehaviorState;
import 'panning_tick_provider.dart';

/// Adds domain axis panning support to a chart.
///
/// Panning is supported by clicking and dragging the mouse for web, or tapping
/// and dragging on the chart for mobile devices.
@immutable
class PanBehavior<D> extends ChartBehavior<D> {
  const PanBehavior();

  @override
  String get role => 'Pan';

  @override
  ChartBehaviorState<D, S, ChartBehavior<D>> build<S extends BaseChart<D>>({
    required BaseChartState<D, S> chartState,
  }) {
    return _PanAndZoomState<D, S, PanBehavior<D>>(
      behavior: this,
      chartState: chartState,
    );
  }
}

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
    return _PanAndZoomState<D, S, PanAndZoomBehavior<D>>(
      behavior: this,
      chartState: chartState,
      hasZoomBehavior: true,
    );
  }
}

class _PanAndZoomState<D, S extends BaseChart<D>, R extends PanBehavior<D>>
    extends ChartBehaviorState<D, S, R> {
  _PanAndZoomState({
    required super.behavior,
    required super.chartState,
    this.hasZoomBehavior = false,
  }) {
    if (chartState is! CartesianChartState<D, CartesianChart<D>>) {
      throw ArgumentError(
          'PanBehavior can only be attached to a CartesianChart<D>');
    }
  }

  final bool hasZoomBehavior;

  @override
  Widget buildBehaviorWidget(BuildContext context) {
    return _Pan<D, S, R>(
      behavior: behavior,
      chartState: chartState,
      hasZoomBehavior: hasZoomBehavior,
    );
  }
}

class _Pan<D, S extends BaseChart<D>, R extends PanBehavior<D>>
    extends StatefulWidget {
  const _Pan({
    required this.chartState,
    required this.behavior,
    required this.hasZoomBehavior,
    super.key,
  });

  final BaseChartState<D, S> chartState;

  final bool hasZoomBehavior;

  final R behavior;

  @override
  State<_Pan<D, S, R>> createState() => _PanState<D, S, R>();
}

class _PanState<D, S extends BaseChart<D>, R extends PanBehavior<D>>
    extends State<_Pan<D, S, R>> {
  /// Wrapped domain tick provider for pan and zoom behavior.
  late PanningTickProvider<D> _domainAxisTickProvider;

  @protected
  PanningTickProvider<D> get domainAxisTickProvider => _domainAxisTickProvider;

  CartesianChartState<D, CartesianChart<D>> get _chartState =>
      widget.chartState as CartesianChartState<D, CartesianChart<D>>;

  /// Current zoom scaling factor for the behavior.
  double _initialScalingFactor = 0.0;
  double _scalingFactor = 1.0;
  double _viewportTranslate = 0.0;

  /// Minimum scalingFactor to prevent zooming out beyond the data range.
  static double _minScalingFactor = 1.0;

  /// Maximum scalingFactor to prevent zooming in so far that no data is
  /// visible.
  ///
  /// TODO: Dynamic max based on data range?
  static const double _maxScalingFactor = 15.0;

  /// Flag which is enabled to indicate that the user is "panning" the chart.
  bool _isPanning = false;

  /// Last position of the mouse/tap that was used to adjust the scale translate
  /// factor.
  Offset? _lastPosition;

  /// Flag which is enabled to indicate that the user is "zooming" the chart.
  bool _isZooming = false;

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
        instance.onStart = (details) => onDragStart(details.focalPoint);
        instance.onUpdate = (details) => onDragUpdate(
              details.focalPoint,
              details.scale,
              details.localFocalPoint,
            );
        instance.onEnd =
            (details) => onDragEnd(details.velocity.pixelsPerSecond.dy);
      },
    );

    return gestures;
  }

  @protected
  bool onDragStart(Offset globalPosition) {
    _lastPosition = globalPosition;

    // When panning starts, measure tick provider should not update ticks.
    // This is still needed because axis internally updates the tick location
    // after the tick provider generates the ticks. If we do not tell the axis
    // not to update the location of the measure axes, we get a jittery effect
    // as the measure axes location changes ever so slightly during pan/zoom.
    _chartState.getMeasureAxis().lockAxis = true;
    _chartState
        .getMeasureAxis(axisId: CartesianAxis.secondaryMeasureAxisId)
        .lockAxis = true;
    _scalingFactor = _chartState.domainAxis!.viewportScalingFactor;
    _initialScalingFactor = _scalingFactor;
    _viewportTranslate = _chartState.domainAxis!.viewportTranslate;

    return true;
  }

  @protected
  bool onDragUpdate(
    Offset globalPosition,
    double scale,
    Offset focalLocalPoint,
  ) {
    if (scale != 1.0) {
      return onZoomUpdate(
        globalPosition,
        scale * _initialScalingFactor,
        focalLocalPoint,
      );
    } else {
      return onPanUpdate(globalPosition);
    }
  }

  @protected
  void onDragEnd(
    double velocity,
  ) {
    _domainAxisTickProvider.mode = PanningTickProviderMode.passThrough;

    _chartState.getMeasureAxis().lockAxis = false;
    _chartState
        .getMeasureAxis(axisId: CartesianAxis.secondaryMeasureAxisId)
        .lockAxis = false;
    _chartState.redraw();

    _panningCompletedCallback?.call();

    _isPanning = false;
    _isZooming = false;
  }

  bool onPanUpdate(Offset globalPosition, [bool skipAnimation = true]) {
    // Update the domain axis's viewport translate to pan the chart.
    final domainAxis = _chartState.domainAxis;

    if (domainAxis == null) {
      return false;
    }

    _domainAxisTickProvider.mode = PanningTickProviderMode.stepSizeLocked;

    final domainScalingFactor = domainAxis.viewportScalingFactor;

    if (domainAxis.isVertical) {
      _viewportTranslate =
          _viewportTranslate + globalPosition.dy - _lastPosition!.dy;
    } else {
      _viewportTranslate =
          _viewportTranslate + globalPosition.dx - _lastPosition!.dx;
    }

    domainAxis.setViewportSettings(
      domainScalingFactor,
      _viewportTranslate,
      drawAreaWidth: _chartState.drawArea.width,
      drawAreaHeight: _chartState.drawArea.height,
    );

    _lastPosition = globalPosition;

    _chartState.redraw(skipAnimation: true);

    return true;
  }

  bool onZoomUpdate(
    Offset globalPosition,
    double scale,
    Offset focalLocalPoint,
  ) {
    // Update the domain axis's viewport scale factor to zoom the chart.
    final domainAxis = _chartState.domainAxis;

    if (domainAxis == null) {
      return false;
    }

    domainAxisTickProvider.mode = PanningTickProviderMode.stepSizeLocked;

    final positionTranslate = domainAxis.isVertical
        ? focalLocalPoint.dy / _chartState.drawArea.height
        : focalLocalPoint.dx / _chartState.drawArea.width;

    final extent = domainAxis.scale.rangeWidth;
    final viewportTranslate = domainAxis.viewportTranslate;

    final viewportPosition = positionTranslate * extent - viewportTranslate;

    final viewportTranslateBefore =
        viewportPosition / (extent * _scalingFactor);

    // Clamp the scale to prevent zooming out beyond the range of the data, or
    // zooming in so far that we show nothing useful.
    _scalingFactor = min(
      max(scale, _minScalingFactor),
      _maxScalingFactor,
    );

    final translate =
        viewportPosition - viewportTranslateBefore * extent * _scalingFactor;

    domainAxis.setViewportSettings(
      _scalingFactor,
      viewportTranslate + translate,
      drawAreaWidth: _chartState.drawArea.width,
      drawAreaHeight: _chartState.drawArea.height,
    );

    _chartState.redraw(skipAnimation: true);

    return true;
  }

  final FocusNode _focusNode = FocusNode();

  bool _controlDown = false;
  Offset _mousePosition = Offset.zero;
  Offset _mouseLocalPosition = Offset.zero;

  @override
  void initState() {
    super.initState();

    // Disable the autoViewport feature to enable panning.
    _chartState.domainAxis!.autoViewport = false;

    // Wrap domain axis tick provider with the panning behavior one.
    _domainAxisTickProvider =
        PanningTickProvider<D>(_chartState.domainAxis!.tickProvider!);
    _chartState.domainAxis!.tickProvider = _domainAxisTickProvider;
  }

  @override
  void dispose() {
    // Restore the default autoViewport state.
    _chartState.domainAxis!.autoViewport = true;

    // Restore the original tick providers
    _chartState.domainAxis!.tickProvider = _domainAxisTickProvider.tickProvider;

    _focusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget result = Listener(
      onPointerSignal: (event) {
        if (event is PointerScrollEvent) {
          if (_controlDown) {
            if (_isZooming) {
              final delta = event.scrollDelta.dy;
              final double zoomScale = -1.0 / delta;
              onZoomUpdate(
                event.position,
                (1.0 + zoomScale) * _scalingFactor,
                _mouseLocalPosition,
              );
            }
          } else {
            if (onDragStart(event.position)) {
              _isPanning = true;
              onPanUpdate(
                !_chartState.domainAxis!.isVertical
                    ? event.position -
                        Offset(
                          event.scrollDelta.dy,
                          event.scrollDelta.dx,
                        )
                    : event.position - event.scrollDelta,
                false,
              );
              onDragEnd(0.0);
            }
          }
        }
      },
      behavior: HitTestBehavior.translucent,
      child: const Center(
        child: SizedBox(),
      ),
    );

    if (widget.hasZoomBehavior) {
      result = MouseRegion(
        onHover: (event) {
          setState(() {
            _mousePosition = event.position;
            _mouseLocalPosition = event.localPosition;
            _focusNode.requestFocus();
          });
        },
        hitTestBehavior: HitTestBehavior.translucent,
        child: RawGestureDetector(
          gestures: _gestures,
          behavior: HitTestBehavior.translucent,
          child: KeyboardListener(
            onKeyEvent: (event) {
              setState(() {
                if (event.logicalKey == LogicalKeyboardKey.controlLeft ||
                    event.logicalKey == LogicalKeyboardKey.controlRight) {
                  if (event is KeyDownEvent) {
                    if (!_controlDown) {
                      if (_isPanning) {
                        onDragEnd(0.0);
                      }

                      _isZooming = true;
                      _controlDown = true;
                      onDragStart(_mousePosition);
                    }
                  } else if (event is KeyUpEvent) {
                    if (_controlDown && _isZooming) {
                      onDragEnd(0.0);
                    }
                    _controlDown = false;
                  }
                }
              });
            },
            focusNode: _focusNode,
            autofocus: true,
            child: result,
          ),
        ),
      );
    }

    return result;
  }
}

/// Callback for when panning is completed.
typedef PanningCompletedCallback = void Function();
