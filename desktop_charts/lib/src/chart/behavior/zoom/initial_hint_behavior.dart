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

import 'dart:ui' show lerpDouble;

import 'package:flutter/widgets.dart';

import '../../base_chart.dart'
    show BaseChart, BaseChartState, LifecycleListener;
import '../../cartesian/axis/axis.dart' show CartesianAxis;
import '../../cartesian/cartesian_chart.dart'
    show CartesianChart, CartesianChartState;
import '../chart_behavior.dart' show ChartBehavior, ChartBehaviorState;

/// Adds initial hint behavior for [CartesianChart].
///
/// This behavior animates to the final viewport from an initial translate and
/// or scale factor.
@immutable
class InitialHintBehavior<D> extends ChartBehavior<D> {
  const InitialHintBehavior({
    this.hintDuration = const Duration(milliseconds: 3000),
    this.maxHintTranslate = 0.0,
    this.maxHintScaleFactor,
  }) : assert(maxHintScaleFactor == null || maxHintScaleFactor > 1.0);

  /// The amount of time to animate to the desired viewport.
  ///
  /// If no duration is passed in, the default of 3000 ms is used.
  final Duration hintDuration;

  // TODO: Translation animation only works for ordinal axis.
  /// The maximum amount ordinal values to shift the viewport for the the hint
  /// animation.
  ///
  /// Positive numbers shift the viewport to the right and negative to the left.
  /// The default is no translation.
  final double maxHintTranslate;

  /// The amount the domain axis will be scaled for the start of the hint.
  ///
  /// A value of 1.0 means the viewport is completely zoomed out (all domains
  /// are in the viewport). If a value is provided, it cannot be less than 1.0.
  ///
  /// By default maxHintScaleFactor is not set.
  final double? maxHintScaleFactor;

  @override
  String get role => 'InitialHint';

  @override
  ChartBehaviorState<D, S, ChartBehavior<D>> build<S extends BaseChart<D>>({
    required BaseChartState<D, S> chartState,
  }) {
    return InitialHintBehaviorState<D, S, InitialHintBehavior<D>>(
      behavior: this,
      chartState: chartState,
    );
  }
}

class InitialHintBehaviorState<D, S extends BaseChart<D>,
    R extends InitialHintBehavior<D>> extends ChartBehaviorState<D, S, R> {
  InitialHintBehaviorState({
    required super.behavior,
    required super.chartState,
  }) {
    if (chartState is! CartesianChartState<D, CartesianChart<D>>) {
      throw ArgumentError(
          'InitialHintBehavior can only be attached to a CartesianChart<D>');
    }

    _hintAnimation = AnimationController(vsync: _chartState);
    _hintAnimation!.addListener(onHintTick);

    _lifecycleListener = LifecycleListener<D>(
      onAxisConfigured: _onAxisConfigured,
      onAnimationComplete: _onAnimationComplete,
    );

    chartState.addLifecycleListener(_lifecycleListener);
  }

  late LifecycleListener<D> _lifecycleListener;
  CartesianChartState<D, CartesianChart<D>> get _chartState =>
      chartState as CartesianChartState<D, CartesianChart<D>>;

  /// Flag to indicate that hint animation controller has already been set up.
  ///
  /// This is to ensure that the hint is only set up on the first draw.
  bool _hintSetupCompleted = false;

  /// Flag to indicate that the first call to axis configured is completed.
  ///
  /// This is to ensure that the initial and target viewport translate and scale
  /// factor is only calculated on the first axis configuration.
  bool _firstAxisConfigured = false;

  double? _initialViewportTranslate;
  double? _initialViewportScalingFactor;
  late double _targetViewportTranslate;
  late double _targetViewportScalingFactor;
  AnimationController? _hintAnimation;

  /// Calculate the animation's initial and target viewport and scale factor
  /// and shift the viewport to the start.
  void _onAxisConfigured() {
    if (!_firstAxisConfigured) {
      _firstAxisConfigured = true;

      final domainAxis = _chartState.domainAxis!;

      // TODO: Translation animation only works for axis with a
      // range band type that returns a non zero step size. If two rows have
      // the same domain value, step size could also equal 0.
      //assert(domainAxis.stepSize != 0.0);

      // Save the target viewport and scale factor from axis, because the
      // viewport can be set by the user using AxisSpec.
      _targetViewportTranslate = domainAxis.viewportTranslate;
      _targetViewportScalingFactor = domainAxis.viewportScalingFactor;

      // Calculate the amount to translate from the target viewport.
      final translateAmount = domainAxis.stepSize * behavior.maxHintTranslate;

      _initialViewportTranslate = _targetViewportTranslate - translateAmount;

      _initialViewportScalingFactor =
          behavior.maxHintScaleFactor ?? _targetViewportScalingFactor;

      assert(_initialViewportScalingFactor != null);
      domainAxis.setViewportSettings(
        _initialViewportScalingFactor!,
        _initialViewportTranslate!,
      );
      _chartState.redraw(
        skipAnimation: true,
      );
    }
  }

  /// Start the hint animation, only start the animation on the very first draw.
  void _onAnimationComplete() {
    if (!_hintSetupCompleted) {
      _hintSetupCompleted = true;

      startHintAnimation();
    }
  }

  /// Setup and start the hint animation.
  ///
  /// Animation controller to be handled by the native platform.
  @protected
  void startHintAnimation() {
    // When panning starts, measure tick provider should not update ticks.
    // This is still needed because axis internally updates the tick location
    // after the tick provider generates the ticks. If we do not tell the axis
    // not to update the location of the measure axes, the measure axis will
    // change during the hint animation and make values jump back and forth.
    _chartState.getMeasureAxis().lockAxis = true;
    _chartState
        .getMeasureAxis(axisId: CartesianAxis.secondaryMeasureAxisId)
        .lockAxis = true;

    _hintAnimation!
      ..duration = behavior.hintDuration
      ..forward(from: 0.0);
  }

  /// Stop hint animation
  @protected
  void stopHintAnimation() {
    // When panning is completed, unlock the measure axis.
    _chartState.getMeasureAxis().lockAxis = false;
    _chartState
        .getMeasureAxis(axisId: CartesianAxis.secondaryMeasureAxisId)
        .lockAxis = false;

    _hintAnimation?.stop();
    _hintAnimation?.dispose();
    _hintAnimation = null;
  }

  /// Animation hint percent, to be returned by the native platform.
  @protected
  double get hintAnimationPercent => _hintAnimation!.value;

  /// Shift domain viewport on hint animation ticks.
  @protected
  void onHintTick() {
    final percent = hintAnimationPercent;

    final scaleFactor = lerpDouble(
      _initialViewportScalingFactor,
      _targetViewportScalingFactor,
      percent,
    )!;

    var translate = lerpDouble(
      _initialViewportTranslate,
      _targetViewportTranslate,
      percent,
    )!;

    // If there is a scale factor animation, need to scale the translatePx so
    // the animation appears to be zooming in on the viewport when there is no
    // [maxHintTranslate] provided.
    //
    // If there is a translate hint, the animation will still first zoom in
    // and then translate the [maxHintTranslate] amount.
    if (_initialViewportScalingFactor != _targetViewportScalingFactor) {
      translate = translate * percent;
    }

    final domainAxis = _chartState.domainAxis!;
    domainAxis.setViewportSettings(
      scaleFactor,
      translate,
      drawAreaWidth: _chartState.drawArea.width,
    );

    if (_hintAnimation!.isCompleted) {
      stopHintAnimation();
      _chartState.redraw();
    } else {
      _chartState.redraw(skipAnimation: true);
    }
  }

  @override
  void dispose() {
    stopHintAnimation();
    _hintAnimation?.dispose();
    _hintAnimation = null;
    _chartState.removeLifecycleListener(_lifecycleListener);

    super.dispose();
  }

  @override
  Widget buildBehaviorWidget(BuildContext context) {
    return GestureDetector(
      onTap: () => stopHintAnimation(),
      behavior: HitTestBehavior.translucent,
      child: const Center(
        child: SizedBox(),
      ),
    );
  }
}
