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
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../../symbol_renderer.dart' show RectSymbolRenderer, SymbolRenderer;
import '../../base_chart.dart'
    show BaseChartState, LifecycleListener, BaseChart;
import '../../cartesian/cartesian_chart.dart'
    show CartesianChartState, CartesianChart;
import '../../chart_canvas.dart' show ChartCanvas, getAnimatedColor;
import '../../processed_series.dart' show MutableSeries;
import '../chart_behavior.dart' show ChartBehavior, ChartBehaviorState;
import '../selection/selection_trigger.dart' show SelectionTrigger;

/// Chart behavior that adds a slider widget to a chart. When the slider is
/// dropped after drag, it will report its domain position and nearest datum
/// value. This behavior only supports charts that use continuous scales.
///
/// Input event types:
///   tapAndDrag - Mouse/Touch on the handle and drag across the chart.
///   pressHold - Mouse/Touch on the handle and drag across the chart instead of
///       panning.
///   longPressHold - Mouse/Touch for a while on the handle, then drag across
///       the data.
@immutable
class SliderBehavior<D> extends ChartBehavior<D> {
  /// Constructs a [SliderBehavior].
  ///
  /// [eventTrigger] sets the type of gesture handled by the slider.
  ///
  /// [handleRenderer] draws a handle for the slider. Defaults to a rectangle.
  ///
  /// [initialDomainValue] sets the initial position of the slider in domain
  /// units. The default is the center of the chart.
  ///
  /// [onChangeCallback] will be called when the position of the slider
  /// changes during a drag event.
  ///
  /// [roleId] optional custom role ID for the slider. This can be used to allow
  /// multiple [SliderBehavior] behaviors on the same chart. Normally, there can only be
  /// one slider (per event trigger type) on a chart. This setting allows for
  /// configuring multiple independent sliders.
  ///
  /// [snapToDatum] configures the slider to snap snap onto the nearest datum
  /// (by domain distance) when dragged. By default, the slider can be
  /// positioned anywhere along the domain axis.
  ///
  /// [style] configures the color and sizing of the slider line and handle.
  ///
  /// [layoutPaintOrder] configures the order in which the behavior should be
  /// painted. This value should be relative to LayoutPaintViewOrder.slider.
  /// (e.g. LayoutViewPaintOrder.slider + 1).
  const SliderBehavior({
    this.eventTrigger = SelectionTrigger.tapAndDrag,
    this.handleRenderer = const RectSymbolRenderer(),
    this.initialDomainValue,
    this.onChangeCallback,
    this.roleId = '',
    this.snapToDatum = false,
    this.style = const SliderStyle(),
  });

  /// Type of input event for the slider.
  ///
  /// Input event types:
  ///   tapAndDrag - Mouse/Touch on the handle and drag across the chart.
  ///   pressHold - Mouse/Touch on the handle and drag across the chart instead
  ///       of panning.
  ///   longPressHold - Mouse/Touch for a while on the handle, then drag across
  ///       the data.
  final SelectionTrigger eventTrigger;

  /// Renderer for the handle. Defaults to a rectangle.
  final SymbolRenderer handleRenderer;

  /// Custom role ID for this slider
  final String roleId;

  /// Whether or not the slider will snap onto the nearest datum (by domain
  /// distance) when dragged.
  final bool snapToDatum;

  /// Color and size styles for the slider.
  final SliderStyle style;

  /// Domain value of the current slider position.
  ///
  /// This is saved in terms of domain instead of chart position so that we can
  /// adjust the slider automatically when the chart is resized.
  final D? initialDomainValue;

  final SliderListenerCallback<D>? onChangeCallback;

  @override
  String get role => 'Slider-$eventTrigger-$roleId';

  @override
  ChartBehaviorState<D, S, SliderBehavior<D>> build<S extends BaseChart<D>>({
    required BaseChartState<D, S> chartState,
  }) {
    return _SliderBehaviorState<D, S>(
      behavior: this,
      chartState: chartState,
    );
  }
}

@immutable
class _SliderBehaviorState<D, S extends BaseChart<D>>
    extends ChartBehaviorState<D, S, SliderBehavior<D>> {
  _SliderBehaviorState({
    required super.behavior,
    required super.chartState,
  }) {
    if (chartState is! CartesianChartState<D, CartesianChart<D>>) {
      throw ArgumentError('Slider can only be attached to a cartesian chart.');
    }
  }

  @override
  Widget buildBehaviorWidget(BuildContext context) {
    return _RangeAnnotationLayoutRenderObjectWidget(
      chartState: chartState as CartesianChartState<D, CartesianChart<D>>,
      behavior: behavior,
    );
  }

  @override
  void dispose() {
    //chartState.removeLifecycleListener(_lifecycleListener);
    super.dispose();
  }
}

class _RangeAnnotationLayoutRenderObjectWidget<D, S extends CartesianChart<D>>
    extends LeafRenderObjectWidget {
  const _RangeAnnotationLayoutRenderObjectWidget({
    super.key,
    required this.chartState,
    required this.behavior,
  });

  final CartesianChartState<D, CartesianChart<D>> chartState;
  final SliderBehavior<D> behavior;

  @override
  _SliderLayoutRender<D> createRenderObject(BuildContext context) =>
      _SliderLayoutRender<D>(
        chartState: chartState,
        behavior: behavior,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    _SliderLayoutRender<D> renderObject,
  ) {
    renderObject.behavior = behavior;
  }
}

/// Layout view component for [SliderBehavior].
class _SliderLayoutRender<D> extends RenderBox
    implements MouseTrackerAnnotation {
  _SliderLayoutRender({
    required this.chartState,
    required SliderBehavior<D> behavior,
  }) : _behavior = behavior;

  final CartesianChartState<D, CartesianChart<D>> chartState;

  SliderBehavior<D> _behavior;
  SliderBehavior<D> get behavior => _behavior;
  set behavior(SliderBehavior<D> value) {
    if (_behavior != value) {
      _behavior = value;
      _markNeedsUpdate();
    }
  }

  /// Rendering data for the slider line and handle.
  _AnimatedSlider<D>? _sliderHandle;

  late LifecycleListener<D> _lifecycleListener;

  late SliderEventListener<D> _sliderEventListener;

  bool _delaySelect = false;

  bool _handleDrag = false;

  /// Current location of the slider line.
  Offset? _domainCenterPoint;

  /// Previous location of the slider line.
  ///
  /// This is used to track changes in the position of the slider caused by new
  /// data being drawn on the chart.
  Offset? _previousDomainCenterPoint;

  /// Bounding box for the slider drag handle.
  Rect? _handleBounds;

  D? _domainValue;

  bool _needsUpdate = true;

  Offset? _lastDragPoint;

  /// Event to fire during the chart's [onPostRender] event.
  ///
  /// This should be set any time the state of the slider has changed.
  SliderListenerDragState? _dragStateToFireOnPostRender;

  late HorizontalDragGestureRecognizer _dragGesture;

  late AnimationController _animationHoverController;
  late AnimationController _animationDragController;

  bool _onSelect(Offset globalPosition) {
    // Skip events that occur outside the drawArea for any series renderer.
    // If the selection is delayed (waiting for long press), then quit early.
    if (!_handleDrag || _delaySelect) {
      //return false;
    }

    // Move the slider line along the domain axis, without adjusting the measure
    // position.
    final positionChanged = _moveSliderToPoint(globalToLocal(globalPosition));

    if (positionChanged) {
      _dragStateToFireOnPostRender = SliderListenerDragState.drag;

      chartState.redraw(skipAnimation: true);
    }

    markNeedsPaint();

    return true;
  }

  bool _onDragEnd(Offset globalPosition) {
    // If the selection is delayed (waiting for long press), then quit early.
    if (_delaySelect) {
      return false;
    }

    _handleDrag = false;

    // If snapToDatum is enabled, use the x position of the nearest datum
    // instead of the mouse point.
    if (behavior.snapToDatum) {
      final details =
          chartState.getNearestDatumDetailPerSeries(globalPosition, true);
      if (details.isNotEmpty && details[0].chartPosition!.dx != null) {
        // Only trigger an animating draw cycle if we need to move the slider.
        if (_domainValue != details[0].domain) {
          _moveSliderToDomain(details[0].domain);

          // Always fire the end event to notify listeners that the gesture is
          // over.
          _dragStateToFireOnPostRender = SliderListenerDragState.end;

          chartState.redraw(skipAnimation: false);
        }
      }
    } else {
      // Move the slider line along the domain axis, without adjusting the
      // measure position.
      _moveSliderToPoint(globalToLocal(globalPosition));

      // Always fire the end event to notify listeners that the gesture is
      // over.
      _dragStateToFireOnPostRender = SliderListenerDragState.end;

      chartState.redraw(skipAnimation: true);
    }

    return false;
  }

  bool _sliderContainsPoint(Offset chartPoint) {
    return _handleBounds!.contains(chartPoint);
  }

  /// Sets the drag state to "initial" when data is drawn on the chart.
  void _setInitialDragState(List<MutableSeries<D>> _) {
    _dragStateToFireOnPostRender = SliderListenerDragState.initial;
  }

  /// Fires a [SliderListenerDragState] change event if needed.
  void _fireChangeEvent() {
    if (_sliderEventListener.onChange == null) {
      return;
    }

    SliderListenerDragState? dragState = _dragStateToFireOnPostRender;

    // Initial drag state event should only be fired if the slider has moved
    // since the last draw. We always set the initial drag state event when new
    // data was drawn on the chart, since we might need to move the slider if
    // the axis range changed.
    if (dragState == SliderListenerDragState.initial &&
        _previousDomainCenterPoint == _domainCenterPoint) {
      dragState = null;
    }

    // Reset state.
    _dragStateToFireOnPostRender = null;
    _previousDomainCenterPoint = _domainCenterPoint;

    // Bail out if the event was cancelled.
    if (dragState == null) {
      return;
    }

    // Fire the event.
    _sliderEventListener.onChange!(
      Offset(_domainCenterPoint!.dx, _domainCenterPoint!.dy),
      _domainValue,
      behavior.roleId,
      dragState,
    );
  }

  /// Moves the slider along the domain axis (and primary measure axis if
  /// [_style.handlePosition] is set to [SliderHandlePosition.manual]) to [point
  /// ].
  ///
  /// If [point] exists beyond either edge of the draw area, it will be bound to
  /// the nearest edge.
  ///
  /// Updates [_domainValue] with the domain value located at [point]. For
  /// ordinal axes, this might technically result in a domain value whose center
  /// point lies slightly outside the draw area.
  ///
  /// Updates [_domainCenterPoint] and [_handleBounds] with the position of
  /// the slider.
  ///
  /// Returns whether or not the position actually changed. This will generally
  /// be false if the mouse was dragged outside of the domain axis viewport.
  bool _moveSliderToPoint(Offset point) {
    bool positionChanged = false;

    final viewBounds = Offset.zero & size;

    // Clamp the position to the edge of the viewport.
    final positionX = point.dx.clamp(viewBounds.left, viewBounds.right);

    final previousYPosition = _handleBounds == null
        ? 0.0
        : _handleBounds!.top +
            behavior.style.handleSize.height / 2 -
            behavior.style.handleOffset.dy;

    double positionY = point.dy;
    if (point.dy == 0.0) {
      if (_handleBounds == null) {
        positionY = viewBounds.bottom.toDouble();
      } else {
        positionY = previousYPosition;
      }
    }

    // Clamp the position to the edge of the viewport.
    positionY = positionY.clamp(viewBounds.top, viewBounds.bottom).toDouble();

    final positionXChanged = _previousDomainCenterPoint != null &&
        positionX != _previousDomainCenterPoint!.dx;

    final positionYChanged =
        behavior.style.handlePosition == SliderHandlePosition.manual &&
            _handleBounds != null &&
            positionY != previousYPosition;

    positionChanged = positionXChanged || positionYChanged;

    // Reset the domain value if the position was outside of the chart.
    _domainValue = chartState.domainAxis!.getDomain(positionX.toDouble());

    if (_domainCenterPoint != null) {
      _domainCenterPoint = Offset(
        positionX.roundToDouble(),
        _domainCenterPoint!.dy,
      );
    } else {
      _domainCenterPoint = Offset(positionX.roundToDouble(),
          (viewBounds.top + viewBounds.height / 2.0).roundToDouble());
    }

    double handleReferenceY;
    switch (behavior.style.handlePosition) {
      case SliderHandlePosition.middle:
        handleReferenceY = _domainCenterPoint!.dy;
        break;
      case SliderHandlePosition.top:
        handleReferenceY = viewBounds.top;
        break;
      case SliderHandlePosition.manual:
        handleReferenceY = positionY;
        break;
      default:
        throw ArgumentError('Slider does not support the handle position '
            '"${behavior.style.handlePosition}"');
    }

    // Move the slider handle along the domain axis.
    _handleBounds = Rect.fromLTWH(
      (_domainCenterPoint!.dx -
              behavior.style.handleSize.width / 2.0 +
              behavior.style.handleOffset.dx)
          .roundToDouble(),
      (handleReferenceY -
              behavior.style.handleSize.height / 2.0 +
              behavior.style.handleOffset.dy)
          .roundToDouble(),
      behavior.style.handleSize.width,
      behavior.style.handleSize.height,
    );

    return positionChanged;
  }

  /// Moves the slider along the domain axis to the location of [domain] and iff
  /// [measure] is set moves it also to location of [measure] along the primary
  /// measure axis.
  ///
  /// If [domain] or [measure] exists beyond either edge of the draw area, the position will
  /// be bound to the nearest edge.
  ///
  /// Updates [_domainValue] with the location of [domain]. For ordinal axes,
  /// this might result in a different domain value if the range band of
  /// [domain] is completely outside of the viewport.
  ///
  /// Updates [_domainCenterPoint] and [_handleBounds] with the position of
  /// the slider.
  ///
  /// Returns whether or not the position actually changed. This will generally
  /// be false if the mouse was dragged outside of the domain axis viewport.
  bool _moveSliderToDomain(D? domain, {double? measure}) {
    final x = chartState.domainAxis!.getLocation(domain)!;
    final y = measure != null
        ? chartState.getMeasureAxis().getLocation(measure)!
        : 0.0;

    return _moveSliderToPoint(Offset(x, y));
  }

  /// Programmatically moves the slider to the location of [domain] on the
  /// domain axis and iff [measure] is set moves it also to its position along
  /// the primary measure axis.
  ///
  /// If [domain] exists beyond either edge of the draw area, the position will
  /// be bound to the nearest edge of the chart. The slider's current domain
  /// value state will reflect the domain value at the edge of the chart. For
  /// ordinal axes, this might result in a domain value whose range band is
  /// partially located beyond the edge of the chart.
  ///
  /// This does nothing if the domain matches the current domain location.
  ///
  /// [SliderEventListener] callbacks will be fired to indicate that the slider
  /// has moved.
  ///
  /// [skipAnimation] controls whether or not the slider will animate. Animation
  /// is disabled by default.
  ///
  /// [measure] controls the vertical position of the handle on the measure
  /// axis, can only be set if the SliderHandlePosition is set to 'manual'. If
  /// measure exists beyond the edges of the draw area, the position will be
  /// bound to the nearest edge of the chart.
  void moveSliderToDomain(
    D domain, {
    double? measure,
    bool skipAnimation = true,
  }) {
    // Nothing to do if we are unattached to a chart or asked to move to the
    // current location.
    if (domain == _domainValue) {
      return;
    }

    final positionChanged = _moveSliderToDomain(domain, measure: measure);

    if (positionChanged) {
      _dragStateToFireOnPostRender = SliderListenerDragState.end;

      chartState.redraw(skipAnimation: skipAnimation);
    }
  }

  void _markNeedsUpdate() {
    _needsUpdate = true;
    markNeedsPaint();
  }

  void _handleMouseEnter(PointerEnterEvent event) {
    _animationHoverController.forward();
  }

  void _handleMouseExit(PointerExitEvent event) {
    _animationHoverController.reverse();
  }

  void _handleDragStart(DragStartDetails details) {
    _lastDragPoint = details.globalPosition;
    _onSelect(details.globalPosition);
    _animationDragController.forward();
  }

  void _handleDragDown(DragDownDetails details) {}

  void _handleDragUpdate(DragUpdateDetails details) {
    _lastDragPoint = details.globalPosition;
    _onSelect(details.globalPosition);
  }

  void _handleDragEnd(DragEndDetails details) {
    _onDragEnd(_lastDragPoint!);
    _animationDragController.reverse();
    _lastDragPoint = null;
  }

  void _handleDragCancel() {
    _animationDragController.reverse();
    _lastDragPoint = null;
  }

  void update() {
    _sliderHandle ??= _AnimatedSlider<D>();

    // If not set in the constructor, initial position for the handle is the
    // center of the draw area.
    if (_domainValue == null) {
      final newDomainValue = chartState.domainAxis!.getDomain(size.width / 2);
      _domainValue = (newDomainValue is double)
          ? (newDomainValue.round().toDouble() as D)
          : newDomainValue;
    }

    // Possibly move the slider, if the axis values have changed since the last
    // chart draw.
    _moveSliderToDomain(_domainValue);

    final themeData = chartState.themeData;

    // Move the handle to the current event position.
    final element = _SliderElement<D>(
      domainCenterPoint: Offset(_domainCenterPoint!.dx, _domainCenterPoint!.dy),
      buttonBounds: _handleBounds!,
      fill: behavior.style.fillColor ?? themeData.sliderFillColor,
      stroke: behavior.style.strokeColor ?? themeData.tickColor,
      strokeWidth: behavior.style.strokeWidth,
    );

    _sliderHandle!.setNewTarget(element);
  }

  set sliderHandle(_AnimatedSlider<D> value) {
    _sliderHandle = value;
  }

  @override
  bool hitTestSelf(Offset position) {
    _delaySelect = behavior.eventTrigger == SelectionTrigger.longPressHold;
    return _sliderContainsPoint(position);
  }

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    assert(debugHandleEvent(event, entry));
    if (event is PointerDownEvent) {
      _dragGesture.addPointer(event);
    }
  }

  @override
  MouseCursor get cursor => SystemMouseCursors.resizeColumn;

  @override
  PointerEnterEventListener? get onEnter => _handleMouseEnter;

  @override
  PointerExitEventListener? get onExit => _handleMouseExit;

  @override
  bool get validForMouseTracker => true;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    chartState.animationPosition.addListener(markNeedsPaint);

    if (behavior.initialDomainValue != null) {
      _dragStateToFireOnPostRender = SliderListenerDragState.initial;
    }

    _animationHoverController = AnimationController(
      vsync: chartState,
      duration: const Duration(milliseconds: 100),
    );

    _animationHoverController.addListener(markNeedsPaint);

    _animationDragController = AnimationController(
      vsync: chartState,
      duration: const Duration(milliseconds: 100),
    );

    _animationDragController.addListener(markNeedsPaint);

    _lifecycleListener = LifecycleListener<D>(
      onData: _setInitialDragState,
      onAxisConfigured: () {
        markNeedsPaint();
        update();
      },
    );

    // Set up slider event listeners.
    _sliderEventListener =
        SliderEventListener<D>(onChange: behavior.onChangeCallback);

    _domainValue = behavior.initialDomainValue;

    chartState.addLifecycleListener(_lifecycleListener);

    _dragGesture = HorizontalDragGestureRecognizer(debugOwner: this)
      ..dragStartBehavior = DragStartBehavior.down
      ..onStart = _handleDragStart
      ..onDown = _handleDragDown
      ..onUpdate = _handleDragUpdate
      ..onCancel = _handleDragCancel
      ..onEnd = _handleDragEnd;
  }

  @override
  void detach() {
    _animationHoverController.removeListener(markNeedsPaint);
    _animationDragController.removeListener(markNeedsPaint);
    _dragGesture.dispose();
    chartState.animationPosition.removeListener(markNeedsPaint);
    chartState.removeLifecycleListener(_lifecycleListener);
    super.detach();
  }

  @override
  void performLayout() {
    size = constraints.biggest;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_needsUpdate) {
      update();
    }

    final drawAreaBounds = Offset.zero & size;

    final animationPercent = chartState.animationPosition.value;

    final sliderElement = _sliderHandle!.getCurrentSlider(animationPercent);

    final draggingColor = chartState.themeData.noDataColor;
    final hoverColor = chartState.themeData.foreground;

    Color color = Color.lerp(
      sliderElement.stroke,
      hoverColor,
      _animationHoverController.value,
    )!;

    color = Color.lerp(color, draggingColor, _animationDragController.value)!;

    Color fillColor = Color.lerp(
      sliderElement.fill,
      hoverColor,
      _animationHoverController.value,
    )!;

    fillColor = Color.lerp(
      fillColor,
      draggingColor,
      _animationDragController.value,
    )!;

    context.canvas.drawChartLine(
      offset,
      points: [
        Offset(sliderElement.domainCenterPoint.dx, drawAreaBounds.top),
        Offset(sliderElement.domainCenterPoint.dx, drawAreaBounds.bottom),
      ],
      stroke: color,
      strokeWidth: sliderElement.strokeWidth,
    );

    behavior.handleRenderer.draw(
      context.canvas,
      offset,
      sliderElement.buttonBounds,
      fillColor: fillColor,
      strokeColor: color,
      strokeWidth: sliderElement.strokeWidth,
    );

    _fireChangeEvent(); // TODO(as): Use correct event.
  }
}

/// Style configuration for a [SliderBehavior] behavior.
@immutable
class SliderStyle {
  const SliderStyle({
    this.fillColor,
    this.handleOffset = const Offset(0.0, 0.0),
    this.handleSize = const Rect.fromLTWH(0.0, 0.0, 10.0, 20.0),
    this.strokeColor,
    this.handlePosition = SliderHandlePosition.middle,
    this.strokeWidth = 2.0,
  });

  /// Fill color of the handle of the slider.
  final Color? fillColor;

  /// Allows users to specify both x-position and y-position offset values that
  /// determines where the slider handle will be rendered. The offset will be
  /// calculated relative to its default position at the vertical and horizontal
  /// center of the slider line.
  final Offset handleOffset;

  /// The vertical position for the slider handle.
  final SliderHandlePosition handlePosition;

  /// Specifies the size of the slider handle.
  final Rect handleSize;

  /// Stroke width of the slider line and the slider handle.
  final double strokeWidth;

  /// Stroke color of the slider line and hte slider handle
  final Color? strokeColor;

  @override
  bool operator ==(covariant SliderStyle other) {
    return fillColor == other.fillColor &&
        handleOffset == other.handleOffset &&
        handleSize == other.handleSize &&
        strokeWidth == other.strokeWidth &&
        strokeColor == other.strokeColor;
  }

  @override
  int get hashCode => Object.hash(
        handleOffset,
        handleSize,
        strokeWidth,
        strokeColor,
        handlePosition,
      );
}

/// Describes the vertical position of the slider handle on the slider.
///
/// [middle] indicates the handle should be half-way between the top and bottom
/// of the chart in the middle of the slider line.
///
/// [top] indicates the slider should be rendered relative to the top of the
/// chart.
///
/// [manual] indicates that the slider vertical position can be set every
/// time the slider moves by calling moveSliderToDomain.
enum SliderHandlePosition { middle, top, manual }

/// Rendering information for a slider control element.
class _SliderElement<D> {
  _SliderElement({
    required this.domainCenterPoint,
    required this.buttonBounds,
    required this.fill,
    required this.stroke,
    required this.strokeWidth,
  });

  Offset domainCenterPoint;
  Rect buttonBounds;
  Color fill;
  Color stroke;
  double strokeWidth;

  _SliderElement<D> clone() {
    return _SliderElement<D>(
      domainCenterPoint: domainCenterPoint,
      buttonBounds: buttonBounds,
      fill: fill,
      stroke: stroke,
      strokeWidth: strokeWidth,
    );
  }

  void updateAnimationPercent(
    _SliderElement<D> previous,
    _SliderElement<D> target,
    double animationPercent,
  ) {
    final previousPoint = previous.domainCenterPoint;
    final targetPoint = target.domainCenterPoint;

    final x = ((targetPoint.dx - previousPoint.dx) * animationPercent) +
        previousPoint.dx;

    final y = ((targetPoint.dy - previousPoint.dy) * animationPercent) +
        previousPoint.dy;

    domainCenterPoint = Offset(x.roundToDouble(), y.roundToDouble());

    final previousBounds = previous.buttonBounds;
    final targetBounds = target.buttonBounds;

    final top = ((targetBounds.top - previousBounds.top) * animationPercent) +
        previousBounds.top;
    final right =
        ((targetBounds.right - previousBounds.right) * animationPercent) +
            previousBounds.right;
    final bottom =
        ((targetBounds.bottom - previousBounds.bottom) * animationPercent) +
            previousBounds.bottom;
    final left =
        ((targetBounds.left - previousBounds.left) * animationPercent) +
            previousBounds.left;

    buttonBounds = Rect.fromLTWH(left.roundToDouble(), top.roundToDouble(),
        (right - left).roundToDouble(), (bottom - top).roundToDouble());

    fill = getAnimatedColor(previous.fill, target.fill, animationPercent);

    stroke = getAnimatedColor(previous.stroke, target.stroke, animationPercent);

    strokeWidth =
        ((target.strokeWidth - previous.strokeWidth) * animationPercent) +
            previous.strokeWidth;
  }
}

/// Animates the slider control element of the behavior between different
/// states.
class _AnimatedSlider<D> {
  _AnimatedSlider();

  _SliderElement<D>? _previousSlider;
  late _SliderElement<D> _targetSlider;
  _SliderElement<D>? _currentSlider;

  // Flag indicating whether this point is being animated out of the chart.
  bool animatingOut = false;

  /// Animates a point that was removed from the series out of the view.
  ///
  /// This should be called in place of "setNewTarget" for points that represent
  /// data that has been removed from the series.
  ///
  /// Animates the width of the slider down to 0.
  void animateOut() {
    final newTarget = _currentSlider!.clone();

    // Animate the button bounds inwards horizontally towards a 0 width box.
    final targetBounds = newTarget.buttonBounds;
    final top = targetBounds.top;
    final right = targetBounds.left + targetBounds.width / 2;
    final bottom = targetBounds.bottom;
    final left = right;

    newTarget.buttonBounds = Rect.fromLTWH(
      left.roundToDouble(),
      top.roundToDouble(),
      (right - left).roundToDouble(),
      (bottom - top).roundToDouble(),
    );

    // Animate the stroke width to 0 so that we don't get a lingering line after
    // animation is done.
    newTarget.strokeWidth = 0.0;

    setNewTarget(newTarget);
    animatingOut = true;
  }

  void setNewTarget(_SliderElement<D> newTarget) {
    animatingOut = false;
    _currentSlider ??= newTarget.clone();
    _previousSlider = _currentSlider!.clone();
    _targetSlider = newTarget;
  }

  _SliderElement<D> getCurrentSlider(double animationPercent) {
    if (animationPercent == 1.0 || _previousSlider == null) {
      _currentSlider = _targetSlider;
      _previousSlider = _targetSlider;
      return _currentSlider!;
    }

    _currentSlider!.updateAnimationPercent(
        _previousSlider!, _targetSlider, animationPercent);

    return _currentSlider!;
  }
}

/// Event handler for slider events.
class SliderEventListener<D> {
  const SliderEventListener({this.onChange});

  /// Called when the position of the slider has changed during a drag event.
  final SliderListenerCallback<D>? onChange;
}

/// Callback function for [SliderBehavior] drag events.
///
/// [point] is the current position of the slider line. [point.x] is the domain
/// position, and [point.y] is the position of the center of the line on the
/// measure axis.
///
/// [domain] is the domain value at the slider position.
///
/// [dragState] indicates the current state of a drag event.
typedef SliderListenerCallback<D> = void Function(
  Offset point,
  D? domain,
  String roleId,
  SliderListenerDragState dragState,
);

/// Describes the current state of a slider change as a result of a drag event.
///
/// [initial] indicates that the slider was set to an initial position when new
/// data was drawn on a chart. This will be fired if an initialDomainValue is
/// passed to [SliderBehavior]. It will also be fired if the position of the slider
/// changes as a result of data being drawn on the chart.
///
/// [drag] indicates that the slider is being moved as a result of drag events.
/// When this is passed, the drag event is still active. Once the drag event is
/// completed, an [end] event will be fired.
///
/// [end] indicates that a drag event has been completed. This usually occurs
/// after one or more [drag] events. An [end] event will also be fired if
/// [SliderBehavior.moveSliderToDomain] is called, but there will be no preceding [drag]
/// events in this case.
enum SliderListenerDragState { initial, drag, end }

/// Helper class that exposes fewer private internal properties for unit tests.
@visibleForTesting
class SliderTester<D> {
  const SliderTester(this.behavior);

  final SliderBehavior<D> behavior;

  // Offset? get domainCenterPoint => behavior._domainCenterPoint;

  // D? get domainValue => behavior.initialDomainValue;

  // Rect? get handleBounds => behavior._handleBounds;

  // void layout(Rect componentBounds, Rect drawAreaBounds) {
  //   behavior._view.layout(componentBounds, drawAreaBounds);
  // }

  // _SliderLayoutRender<D> get view => behavior._view;
}
