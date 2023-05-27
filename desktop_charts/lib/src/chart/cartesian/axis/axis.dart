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

import 'package:collection/collection.dart' show IterableExtension;
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import '../../../data/series.dart' show AttributeKey;
import '../../../text_element.dart' show TextElement;
import '../../base_chart.dart';
import '../../chart_context.dart' show ChartContext;
import 'axis_tick.dart' show AxisTicks;
import 'draw_strategy/small_tick_draw_strategy.dart' show SmallTickDrawStrategy;
import 'draw_strategy/tick_draw_strategy.dart' show TickDrawStrategy;
import 'linear/linear_scale.dart' show LinearScale;
import 'numeric_extents.dart' show NumericExtents;
import 'numeric_scale.dart' show NumericScale;
import 'numeric_tick_provider.dart' show NumericTickProvider;
import 'ordinal_scale.dart' show OrdinalScale;
import 'ordinal_tick_provider.dart' show OrdinalTickProvider;
import 'range_axis_tick.dart' show RangeAxisTicks;
import 'range_tick.dart' show RangeTick;
import 'scale.dart'
    show MutableScale, RangeBandConfig, RangeBandType, ScaleOutputExtent, Scale;
import 'simple_ordinal_scale.dart' show SimpleOrdinalScale;
import 'spec/axis_spec.dart' show AxisSpec;
import 'spec/numeric_axis_spec.dart' show NumericAxisSpec;
import 'spec/ordinal_axis_spec.dart' show OrdinalAxisSpec;
import 'tick.dart' show Tick;
import 'tick_formatter.dart'
    show TickFormatter, OrdinalTickFormatter, NumericTickFormatter;
import 'tick_provider.dart' show TickProvider;

const measureAxisIdKey = AttributeKey<String>('Axis.measureAxisId');
//const measureAxisKey = AttributeKey<CartesianAxis<dynamic>>('Axis.measureAxis');
//const domainAxisKey = AttributeKey<CartesianAxis<dynamic>>('Axis.domainAxis');

abstract class ImmutableAxis<D> {
  /// Compare domain to the viewport.
  ///
  /// 0 if the domain is in the viewport.
  /// 1 if the domain is to the right of the viewport.
  /// -1 if the domain is to the left of the viewport.
  int compareDomainValueToViewport(D domain);

  /// Get location for the domain.
  double? getLocation(D? domain);

  D getDomain(double location);

  /// Range band for this axis.
  double get rangeBand;

  /// Step size for this axis.
  double get stepSize;

  /// Output range for this axis.
  ScaleOutputExtent? get range;
}

abstract class CartesianAxis<D> extends ChangeNotifier
    implements ImmutableAxis<D> {
  CartesianAxis({
    TickFormatter<D>? tickFormatter,
    required TickDrawStrategy<D> tickDrawStrategy,
    this.tickProvider,
    required this.scale,
    required this.chartContext,
    required AxisSpec<D> axisSpec,
    required AxisDirection axisDirection,
    required bool reverseOutputRange,
  })  : _defaultScale = scale,
        _defaultTickProvider = tickProvider,
        _defaultTickFormatter = tickFormatter,
        _tickFormatter = tickFormatter,
        _tickDrawStrategy = tickDrawStrategy,
        _axisDirection = axisDirection,
        _reverseOutputRange = reverseOutputRange {
    updateAxisSpec(axisSpec);
  }

  static const primaryMeasureAxisId = 'primaryMeasureAxisId';
  static const secondaryMeasureAxisId = 'secondaryMeasureAxisId';
  static const _autoViewportDefault = true;

  // final RenderBox parent;

  final ChartContext chartContext;

  @protected
  @mustCallSuper
  void updateAxisSpec(AxisSpec<D> value) {
    resetDefaultConfiguration();

    if (value.showAxisLine != null) {
      forceDrawAxisLine = value.showAxisLine;
    }

    if (value.renderSpec != null) {
      tickDrawStrategy = value.renderSpec!.createDrawStrategy(chartContext);
    }

    if (value.tickProviderSpec != null) {
      tickProvider = value.tickProviderSpec!.createTickProvider(chartContext);
    }

    if (value.tickFormatterSpec != null) {
      tickFormatter =
          value.tickFormatterSpec!.createTickFormatter(chartContext);
    }

    if (value.scaleSpec != null) {
      scale = value.scaleSpec!.createScale(chartContext.themeData)
          as MutableScale<D>;
    }
  }

  set axisSpec(AxisSpec<D> value) {
    updateAxisSpec(value);
    notifyListeners();
  }

  final MutableScale<D> _defaultScale;

  /// [Scale] of this axis.
  MutableScale<D> scale;

  /// Previous [Scale] of this axis, used to calculate tick animation.
  MutableScale<D>? _previousScale;

  final TickProvider<D>? _defaultTickProvider;

  /// [TickProvider] for this axis.
  TickProvider<D>? tickProvider;

  final TickFormatter<D>? _defaultTickFormatter;

  TickFormatter<D>? _tickFormatter;

  set tickFormatter(TickFormatter<D>? formatter) {
    if (_tickFormatter != formatter) {
      _tickFormatter = formatter;
      _formatterValueCache.clear();
    }
  }

  /// [TickFormatter] for this axis.
  TickFormatter<D>? get tickFormatter => _tickFormatter;

  final _formatterValueCache = <D, String>{};

  TickDrawStrategy<D> _tickDrawStrategy;
  TickDrawStrategy<D> get tickDrawStrategy => _tickDrawStrategy;
  set tickDrawStrategy(TickDrawStrategy<D> value) {
    if (_tickDrawStrategy != value) {
      _tickDrawStrategy = value;
      notifyListeners();
    }
  }

  AxisDirection _axisDirection;

  /// [AxisDirection] for this axis.
  AxisDirection get axisDirection => _axisDirection;

  set axisDirection(AxisDirection value) {
    if (value != _axisDirection) {
      _axisDirection = value;
      notifyListeners();
    }
  }

  /// If the output range should be reversed.
  bool _reverseOutputRange;

  bool get reverseOutputRange => _reverseOutputRange;

  set reverseOutputRange(bool value) {
    if (value != _reverseOutputRange) {
      _reverseOutputRange = value;
      notifyListeners();
    }
  }

  /// Configures whether the viewport should be reset back to default values
  /// when the domain is reset.
  ///
  /// This should generally be disabled when the viewport will be managed
  /// externally, e.g. from pan and zoom behaviors.
  bool autoViewport = _autoViewportDefault;

  /// If the axis line should always be drawn.
  bool? forceDrawAxisLine;

  /// If true, do not allow axis to be modified.
  ///
  /// Ticks (including their location) are not updated.
  /// Viewport changes not allowed.
  bool lockAxis = false;

  /// Ticks provided by the tick provider.
  List<Tick<D>>? _providedTicks;

  /// Ticks used by the axis for drawing.
  final _axisTicks = <AxisTicks<D>>[];

  late Rect _componentBounds;
  late Size _axisSize;

  /// If true, a collision has occurred between ticks on this axis.
  bool hasTickCollision = false;

  @protected
  MutableScale<D>? get mutableScale => scale;

  /// Range band for this axis.
  @override
  double get rangeBand => scale.rangeBand;

  @override
  double get stepSize => scale.stepSize;

  @override
  ScaleOutputExtent? get range => scale.range;

  void setRangeBandConfig(RangeBandConfig rangeBandConfig) {
    mutableScale!.rangeBandConfig = rangeBandConfig;
  }

  /// For bars to be renderer properly the RangeBandConfig must be set and
  /// type must not be RangeBandType.none.
  bool get hasValidBarChartRangeBandConfig =>
      (mutableScale?.rangeBandConfig.type ?? RangeBandType.none) !=
      RangeBandType.none;

  void addDomainValue(D domain) {
    if (lockAxis) {
      return;
    }

    scale.addDomain(domain);
  }

  void resetDefaultConfiguration() {
    forceDrawAxisLine = null;
    autoViewport = _autoViewportDefault;
    scale = _defaultScale;
    _tickFormatter = _defaultTickFormatter;
    tickProvider = _defaultTickProvider;
  }

  void resetDomains() {
    if (lockAxis) {
      return;
    }

    notifyListeners();

    // If the series list changes, clear the cache.
    //
    // There are cases where tick formatter has not "changed", but if measure
    // formatter provided to the tick formatter uses a closure value, the
    // formatter cache needs to be cleared.
    //
    // This type of use case for the measure formatter surfaced where the series
    // list also changes. So this is a round about way to also clear the
    // tick formatter cache.
    //
    // TODO: Measure formatter should be changed from a typedef to
    // a concrete class to force users to create a tick formatter when
    // formatting is different, so we can recognize when the tick formatter is
    // changed and then clear cache accordingly.
    //
    // Remove this when bug above is fixed, and verify it did not cause
    // regression for b/110371453.
    _formatterValueCache.clear();

    scale.resetDomain();
    reverseOutputRange = false;

    if (autoViewport) {
      scale.resetViewportSettings();
    }

    // TODO: Reset rangeband and step size when we port over config
    //scale.rangeBandConfig = get range band config
    //scale.stepSizeConfig = get step size config
  }

  @override
  double? getLocation(D? domain) {
    const epsilon = 2e-10;

    if (domain != null) {
      final range = scale.range!;

      final domainLocation = scale[domain]!.toDouble();

      // If domain location is outside of scale range but only outside by less
      // than epsilon, correct the potential dislocation caused by floating
      // point computation by moving it inside of scale range.
      if (domainLocation > range.max && domainLocation - epsilon < range.max) {
        return domainLocation - epsilon;
      } else if (domainLocation < range.min &&
          domainLocation + epsilon > range.min) {
        return domainLocation + epsilon;
      }
      return domainLocation;
    }

    return null;
  }

  @override
  D getDomain(double location) => scale.reverse(location);

  @override
  int compareDomainValueToViewport(D domain) {
    return scale.compareDomainValueToViewport(domain);
  }

  void setOutputRange(double start, double end) {
    scale.range = ScaleOutputExtent(start, end);
  }

  /// Request ticks from tick provider.
  void _updateProvidedTicks() {
    if (lockAxis) {
      return;
    }

    // TODO: Ensure that tick providers take manually configured
    // viewport settings into account, so that we still get the right number.
    _providedTicks = tickProvider!.getTicks(
      context: chartContext, // TODO
      scale: scale,
      formatter: tickFormatter!,
      formatterValueCache: _formatterValueCache,
      tickDrawStrategy: tickDrawStrategy,
      orientation: axisDirection,
      viewportExtensionEnabled: autoViewport,
    );

    hasTickCollision =
        tickDrawStrategy.collides(_providedTicks, axisDirection).ticksCollide;
  }

  /// Updates the current provided tick labels with a max width.
  void _updateProvidedTickWidth(double maxWidth, double maxHeight) {
    tickDrawStrategy.updateTickWidth(
      _providedTicks!,
      maxWidth,
      maxHeight,
      _axisDirection,
      collision: hasTickCollision,
    );
  }

  /// Updates the ticks that are actually used for drawing.
  void _updateAxisTicks() {
    if (lockAxis) {
      return;
    }

    final providedTicks = List.of(_providedTicks ?? <Tick<D>>[]);

    for (final animatedTick in _axisTicks) {
      final tick =
          providedTicks.firstWhereOrNull((t) => t.value == animatedTick.value);

      if (tick != null) {
        // Swap out the text element only if the settings are different.
        // This prevents a costly TextPainter in Flutter.
        if (!TextElement.elementSettingsSame(
            animatedTick.textElement!, tick.textElement!)) {
          animatedTick.textElement = tick.textElement;
        }
        final newTarget = scale[tick.value]?.toDouble();
        if (scale.isRangeValueWithinViewport(newTarget!)) {
          // Update target for all existing ticks
          animatedTick.setNewTarget(newTarget);
        } else {
          // Animate out ticks that are outside the viewport.
          animatedTick.animateOut(animatedTick.location);
        }

        providedTicks.remove(tick);
      } else {
        // Animate out ticks that do not exist any more.
        animatedTick.animateOut(scale[animatedTick.value]!.toDouble());
      }
    }

    // Add ticks
    for (final tick in providedTicks) {
      AxisTicks<D> animatedTick;
      if (tick is RangeTick<D>) {
        animatedTick = RangeAxisTicks<D>(tick);
      } else {
        animatedTick = AxisTicks<D>(tick);
      }
      if (scale.isRangeValueWithinViewport(animatedTick.location!)) {
        if (_previousScale != null) {
          animatedTick.animateInFrom(_previousScale![tick.value]!.toDouble());
        }
        _axisTicks.add(animatedTick);
      }
    }

    _axisTicks.sort();

    // Save a copy of the current scale to be used as the previous scale when
    // ticks are updated.
    _previousScale = scale.copy();
  }

  /// Configures the zoom and translate.
  ///
  /// [viewportScale] is the zoom factor to use, likely >= 1.0 where 1.0 maps
  /// the complete data extents to the output range, and 2.0 only maps half the
  /// data to the output range.
  ///
  /// [viewportTranslate] is the translate/pan,
  /// likely <= 0 which shifts the start of the data before the edge of the
  /// chart giving us a pan.
  ///
  /// [drawAreaWidth] is the width of the draw area for the series data,
  /// at minimum viewport scale level (1.0). When provided,
  /// [drawAreaHeight] is the height of the draw area for the series data,
  /// at minimum viewport scale level (1.0). When provided,
  /// [viewportTranslate] will be clamped such that the axis cannot be panned
  /// beyond the bounds of the data.
  void setViewportSettings(
    double viewportScale,
    double viewportTranslate, {
    double? drawAreaWidth,
    double? drawAreaHeight,
  }) {
    // Don't let the viewport be panned beyond the bounds of the data.
    viewportTranslate = _clampTranslate(
      viewportScale,
      viewportTranslate,
      drawAreaWidth: drawAreaWidth,
      drawAreaHeight: drawAreaHeight,
    );

    scale.setViewportSettings(viewportScale, viewportTranslate);
  }

  /// Returns the current viewport scale.
  ///
  /// A scale of 1.0 would map the data directly to the output range, while a
  /// value of 2.0 would map the data to an output of double the range so you
  /// only see half the data in the viewport.  This is the equivalent to
  /// zooming.  Its value is likely >= 1.0.
  double get viewportScalingFactor => scale.viewportScalingFactor;

  /// Returns the current viewport offset
  ///
  /// The translate is used by the scale function when it applies the scale.
  /// This is the equivalent to panning.  Its value is likely <= 0 to pan the
  /// data to the left.
  double get viewportTranslate => scale.viewportTranslate;

  /// Clamps a possible change in domain translation to fit within the range of
  /// the data.
  double _clampTranslate(
    double viewportScalingFactor,
    double viewportTranslate, {
    double? drawAreaWidth,
    double? drawAreaHeight,
  }) {
    if (isVertical) {
      if (drawAreaHeight == null) {
        return viewportTranslate;
      }
      // Bound the viewport translate to the range of the data.
      final maxPositiveTranslate =
          (drawAreaHeight * viewportScalingFactor) - drawAreaHeight;

      viewportTranslate =
          max(min(viewportTranslate, maxPositiveTranslate), 0.0);
    } else {
      if (drawAreaWidth == null) {
        return viewportTranslate;
      }
      // Bound the viewport translate to the range of the data.
      final maxNegativeTranslate =
          -1.0 * ((drawAreaWidth * viewportScalingFactor) - drawAreaWidth);

      viewportTranslate =
          min(max(viewportTranslate, maxNegativeTranslate), 0.0);
    }
    return viewportTranslate;
  }

  /// The axis is rendered vertically.
  bool get isVertical =>
      _axisDirection == AxisDirection.left ||
      _axisDirection == AxisDirection.right;

  double _measureVerticalAxis(double maxWidth, double maxHeight) {
    setOutputRange(maxHeight, 0.0);
    _updateProvidedTicks();

    return tickDrawStrategy.measureVerticallyDrawnTicks(
      _providedTicks!,
      maxWidth,
      maxHeight,
      collision: hasTickCollision,
    );
  }

  double _measureHorizontalAxis(double maxWidth, double maxHeight) {
    setOutputRange(0.0, maxWidth);
    _updateProvidedTicks();

    return tickDrawStrategy.measureHorizontallyDrawnTicks(
      _providedTicks!,
      maxWidth,
      maxHeight,
      collision: hasTickCollision,
    );
  }

  @mustCallSuper
  void update() {
    const Offset offset = Offset.zero;

    switch (_axisDirection) {
      case AxisDirection.left:
      case AxisDirection.up:
        _componentBounds = offset & _axisSize;
        break;
      case AxisDirection.right:
        _componentBounds = Rect.fromLTRB(
          offset.dx + size.width - _axisSize.width,
          offset.dy,
          offset.dx + size.width,
          offset.dy + _axisSize.height,
        );
        break;
      case AxisDirection.down:
        _componentBounds = Rect.fromLTRB(
          offset.dx,
          offset.dy + size.height - _axisSize.height,
          offset.dx + _axisSize.width,
          offset.dy + size.height,
        );
        break;
    }

    final outputStart =
        isVertical ? _componentBounds.bottom : _componentBounds.left;
    final outputEnd =
        isVertical ? _componentBounds.top : _componentBounds.right;

    final outputRange = reverseOutputRange
        ? ScaleOutputExtent(outputEnd, outputStart)
        : ScaleOutputExtent(outputStart, outputEnd);

    if (scale.range != outputRange) {
      scale.range = outputRange;
    }

    if (_hasValidSize) {
      _updateProvidedTicks();
      _updateProvidedTickWidth(_componentBounds.width, _componentBounds.height);
      _updateAxisTicks();
    }
  }

  bool get drawAxisLine {
    if (forceDrawAxisLine != null) {
      return forceDrawAxisLine!;
    }

    return tickDrawStrategy is SmallTickDrawStrategy;
  }

  late Size size;

  bool get _hasValidSize => _axisSize.width > 0.0 && _axisSize.height > 0.0;

  void measure(BoxConstraints constraints, [Size? axisSize]) {
    size = constraints.biggest;

    _axisSize = axisSize ??
        (isVertical
            ? Size(measureWidth(constraints), size.height)
            : Size(size.width, measureHeight(constraints)));
  }

  double measureHeight(BoxConstraints constraints) {
    double result =
        _measureHorizontalAxis(constraints.maxWidth, constraints.maxHeight);

    if (drawAxisLine) {
      result += tickDrawStrategy.axisLineWidth;
    }

    return result;
  }

  double measureWidth(BoxConstraints constraints) {
    double result =
        _measureVerticalAxis(constraints.maxWidth, constraints.maxHeight);

    if (drawAxisLine) {
      result += tickDrawStrategy.axisLineWidth;
    }

    return result;
  }

  @mustCallSuper
  void paint(PaintingContext context, Offset offset) {
    final animationPercent = chartContext.animationPosition.value;

    if (animationPercent == 1.0) {
      _axisTicks.removeWhere((t) => t.markedForRemoval);
    }

    if (!_hasValidSize) {
      return;
    }

    context.canvas
      ..save()
      ..clipRect((offset & size).inflate(20.0));

    final Rect tickAxisBound;

    if (drawAxisLine) {
      tickDrawStrategy.drawAxisLine(
        context.canvas,
        offset,
        _axisDirection,
        _componentBounds,
      );

      switch (axisDirection) {
        case AxisDirection.up:
          tickAxisBound = _componentBounds.shift(
            Offset(
              0.0,
              -tickDrawStrategy.axisLineWidth,
            ),
          );
          break;
        case AxisDirection.down:
          tickAxisBound = _componentBounds.shift(
            Offset(
              0.0,
              tickDrawStrategy.axisLineWidth,
            ),
          );
          break;
        case AxisDirection.right:
          tickAxisBound = _componentBounds.shift(
            Offset(
              tickDrawStrategy.axisLineWidth,
              0.0,
            ),
          );
          break;
        case AxisDirection.left:
          tickAxisBound = _componentBounds.shift(
            Offset(
              -tickDrawStrategy.axisLineWidth,
              0.0,
            ),
          );
          break;
      }
    } else {
      tickAxisBound = _componentBounds;
    }

    for (int i = 0; i < _axisTicks.length; i += 1) {
      final animatedTick = _axisTicks[i];

      tickDrawStrategy.draw(
        context.canvas,
        offset,
        animatedTick..setCurrentTick(animationPercent),
        orientation: _axisDirection,
        axisBounds: tickAxisBound,
        collision: hasTickCollision,
        drawAreaBounds: Offset.zero & size,
        isFirst: i == 0,
        isLast: i == _axisTicks.length - 1,
      );
    }

    context.canvas.restore();
  }
}

class NumericAxis extends CartesianAxis<num> {
  NumericAxis({
    TickProvider<num>? tickProvider,
    required AxisSpec<num> axisSpec,
    required super.chartContext,
    required super.tickDrawStrategy,
    required super.axisDirection,
    required super.reverseOutputRange,
  }) : super(
          tickProvider: tickProvider ?? NumericTickProvider(),
          tickFormatter: NumericTickFormatter(),
          scale: LinearScale(),
          axisSpec: axisSpec,
        );

  @override
  void updateAxisSpec(AxisSpec<num> value) {
    super.updateAxisSpec(value);

    if (value is NumericAxisSpec && value.viewport != null) {
      setScaleViewport(value.viewport!);
    }
  }

  void setScaleViewport(NumericExtents viewport) {
    autoViewport = false;
    (scale as NumericScale?)!.viewportDomain = viewport;
  }
}

class OrdinalAxis extends CartesianAxis<String> {
  OrdinalAxis({
    TickProvider<String>? tickProvider,
    TickFormatter<String>? tickFormatter,
    required AxisSpec<String> axisSpec,
    required super.chartContext,
    required super.tickDrawStrategy,
    required super.axisDirection,
    required super.reverseOutputRange,
  }) : super(
          tickProvider: tickProvider ?? const OrdinalTickProvider(),
          tickFormatter: tickFormatter ?? const OrdinalTickFormatter(),
          scale: SimpleOrdinalScale(chartContext.themeData),
          axisSpec: axisSpec,
        );

  @override
  void updateAxisSpec(AxisSpec<String> value) {
    super.updateAxisSpec(value);

    if (value is OrdinalAxisSpec && value.viewport != null) {
      setScaleViewport(value.viewport!);
    }
  }

  void setScaleViewport(OrdinalViewport viewport) {
    autoViewport = false;
    (scale as OrdinalScale?)!
        .setViewport(viewport.dataSize, viewport.startingDomain);
  }

  @override
  void update() {
    super.update();

    // We are purposely clearing the viewport starting domain and data size
    // post layout.
    //
    // Originally we set a flag in [setScaleViewport] to recalculate viewport
    // settings on next scale update and then reset the flag. This doesn't work
    // because chart's measure cycle provides different ranges to the scale,
    // causing the scale to update multiple times before it is finalized after
    // layout.
    //
    // By resetting the viewport after layout, we guarantee the correct range
    // was used to apply the viewport and behaviors that update the viewport
    // based on translate and scale changes will not be affected (pan/zoom).
    (scale as OrdinalScale?)!.setViewport(null, null);
  }
}

/// Viewport to cover [dataSize] data points starting at [startingDomain] value.
@immutable
class OrdinalViewport {
  const OrdinalViewport(this.startingDomain, this.dataSize);

  final String startingDomain;
  final int dataSize;

  @override
  bool operator ==(Object other) {
    return other is OrdinalViewport &&
        startingDomain == other.startingDomain &&
        dataSize == other.dataSize;
  }

  @override
  int get hashCode => Object.hash(startingDomain, dataSize);
}

@visibleForTesting
class AxisTester<D, S extends BaseChart<D>> {
  const AxisTester(this._axis);

  final CartesianAxis<D> _axis;

  List<AxisTicks<D>> get axisTicks => _axis._axisTicks;

  MutableScale<D>? get scale => _axis.scale;

  List<D> get axisValues => axisTicks.map((t) => t.value).toList();
}
