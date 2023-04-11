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

import 'package:collection/collection.dart' show ListEquality;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../../data/series.dart' show Series;
import '../base_chart.dart' show BaseChart, BaseChartState;
import '../datum_details.dart' show DatumDetails;
import '../processed_series.dart' show MutableSeries;
import '../selection_model.dart' show SelectionModelType;
import '../series_renderer.dart' show rendererIdKey;
import 'axis/axis.dart'
    show CartesianAxis, NumericAxis, OrdinalAxis, measureAxisIdKey;
import 'axis/draw_strategy/gridline_draw_strategy.dart'
    show GridlineRendererSpec;
import 'axis/draw_strategy/small_tick_draw_strategy.dart'
    show SmallTickRendererSpec;
import 'axis/spec/axis_spec.dart' show AxisSpec;
import 'axis/spec/numeric_axis_spec.dart' show NumericAxisSpec;
import 'axis/spec/ordinal_axis_spec.dart' show OrdinalAxisSpec;

@immutable
class NumericCartesianChart extends CartesianChart<num> {
  const NumericCartesianChart(
    super.seriesList, {
    super.isVertical,
    super.primaryMeasureAxis,
    super.secondaryMeasureAxis,
    super.disjointMeasureAxes,
    super.key,
    super.animate,
    super.animationDuration,
    super.behaviors,
    super.customSeriesRenderers,
    super.defaultInteractions,
    super.defaultRenderer,
    super.domainAxis,
    super.rtlSpec,
    super.selectionModels,
    super.userManagedState,
    super.flipVerticalAxis,
  });

  @override
  NumericCartesianChartState createState() => NumericCartesianChartState();
}

class NumericCartesianChartState
    extends CartesianChartState<num, NumericCartesianChart> {
  @override
  NumericAxis buildDomainAxis({
    required AxisDirection axisDirection,
    required bool reverseOutputRange,
  }) =>
      createDomainAxisFromSpec(
        widget.domainAxis ?? const NumericAxisSpec(),
        axisDirection: axisDirection,
        reverseOutputRange: reverseOutputRange,
      );

  @override
  NumericAxis createDomainAxisFromSpec(
    AxisSpec<num> axisSpec, {
    required AxisDirection axisDirection,
    required bool reverseOutputRange,
  }) {
    return (axisSpec as NumericAxisSpec).createAxis(
      chartContext: this,
      tickDrawStrategy: const SmallTickRendererSpec<num>().createDrawStrategy(
        this,
      ),
      axisDirection: axisDirection,
      reverseOutputRange: reverseOutputRange,
    );
  }
}

@immutable
class OrdinalCartesianChart extends CartesianChart<String> {
  const OrdinalCartesianChart(
    super.seriesList, {
    super.isVertical,
    super.primaryMeasureAxis,
    super.secondaryMeasureAxis,
    super.disjointMeasureAxes,
    super.key,
    super.animate,
    super.animationDuration,
    super.behaviors,
    super.customSeriesRenderers,
    super.defaultInteractions,
    super.defaultRenderer,
    super.rtlSpec,
    super.selectionModels,
    super.userManagedState,
    super.domainAxis,
    super.flipVerticalAxis,
  });

  @override
  OrdinalCartesianChartState createState() => OrdinalCartesianChartState();
}

class OrdinalCartesianChartState
    extends CartesianChartState<String, OrdinalCartesianChart> {
  @override
  OrdinalAxis buildDomainAxis({
    required AxisDirection axisDirection,
    required bool reverseOutputRange,
  }) =>
      createDomainAxisFromSpec(
        widget.domainAxis ?? const OrdinalAxisSpec(),
        axisDirection: axisDirection,
        reverseOutputRange: reverseOutputRange,
      );

  @override
  OrdinalAxis createDomainAxisFromSpec(
    AxisSpec<String> axisSpec, {
    required AxisDirection axisDirection,
    required bool reverseOutputRange,
  }) {
    return (axisSpec as OrdinalAxisSpec).createAxis(
      chartContext: this,
      tickDrawStrategy:
          const SmallTickRendererSpec<String>().createDrawStrategy(this),
      axisDirection: axisDirection,
      reverseOutputRange: reverseOutputRange,
    );
  }
}

@immutable
abstract class CartesianChart<D> extends BaseChart<D> {
  const CartesianChart(
    super.seriesList, {
    this.isVertical = true,
    this.primaryMeasureAxis = const NumericAxisSpec(),
    this.secondaryMeasureAxis = const NumericAxisSpec(),
    this.domainAxis,
    this.disjointMeasureAxes,
    this.flipVerticalAxis,
    super.animate,
    super.animationDuration,
    super.defaultRenderer,
    super.customSeriesRenderers,
    super.behaviors,
    super.selectionModels,
    super.rtlSpec,
    super.defaultInteractions,
    super.userManagedState,
    super.key,
  });

  final bool? flipVerticalAxis;

  /// Temporarily stores the domain axis that is passed in the constructor
  /// and the domain axis created when [domainAxisSpec] is set to a new
  /// spec.
  ///
  /// This step is necessary because the axis cannot be fully configured until
  /// [context] is available. [configurationChanged] is called after [context]
  /// is available and [_newDomainAxis] will be set to [_domainAxis] and then
  /// reset back to null.
  final AxisSpec<D>? domainAxis;

  /// Sets the primary measure axis for the chart, rendered on the start side of
  /// the domain axis.
  final NumericAxisSpec primaryMeasureAxis;

  /// Sets the secondary measure axis for the chart, rendered on the end side of
  /// the domain axis.
  final NumericAxisSpec secondaryMeasureAxis;

  /// Sets a map of disjoint measure axes for the chart.
  ///
  /// Disjoint measure axes can be used to scale a sub-set of series on the
  /// chart independently from the primary and secondary axes. The general use
  /// case for this type of chart is to show differences in the trends of the
  /// data, without comparing their absolute values.
  ///
  /// Disjoint axes will not render any tick or gridline elements. With
  /// independent scales, there would be a lot of collision in labels were they
  /// to do so.
  ///
  /// If any series is rendered with a disjoint axis, it is highly recommended
  /// to render all series with disjoint axes. Otherwise, the chart may be
  /// visually misleading.
  ///
  /// A [Map] is used to ensure consistent ordering when painting the
  /// axes.
  final Map<String, NumericAxisSpec>? disjointMeasureAxes;

  final bool isVertical;
}

abstract class CartesianChartState<D, S extends CartesianChart<D>>
    extends BaseChartState<D, S> {
  /// The current domain axis for this chart.
  CartesianAxis<D>? domainAxis;
  NumericAxis? _primaryMeasureAxis;
  NumericAxis? _secondaryMeasureAxis;
  Map<String, NumericAxis> _disjointMeasureAxes = {};

  /// If set to true, the vertical axis will render the opposite of the default
  /// direction.
  bool get flipVerticalAxisOutput => widget.flipVerticalAxis ?? false;

  bool _usePrimaryMeasureAxis = false;
  bool _useSecondaryMeasureAxis = false;

  @override
  bool get isVertical => widget.isVertical;

  /// Creates the domain axis from a provided axis spec.
  @protected
  CartesianAxis<D>? createDomainAxisFromSpec(
    AxisSpec<D> axisSpec, {
    required AxisDirection axisDirection,
    required bool reverseOutputRange,
  });

  @protected
  CartesianAxis<D> buildDomainAxis({
    required AxisDirection axisDirection,
    required bool reverseOutputRange,
  });

  /// Gets the measure axis matching the provided id.
  ///
  /// If none is provided, this returns the primary measure axis.
  NumericAxis getMeasureAxis({String? axisId}) {
    NumericAxis? axis;
    if (axisId == CartesianAxis.secondaryMeasureAxisId) {
      axis = _secondaryMeasureAxis;
    } else if (axisId == CartesianAxis.primaryMeasureAxisId) {
      axis = _primaryMeasureAxis;
    } else if (axisId != null && _disjointMeasureAxes[axisId] != null) {
      axis = _disjointMeasureAxes[axisId];
    }

    // If no valid axisId was provided, fall back to primary axis.
    axis ??= _primaryMeasureAxis;

    return axis!;
  }

  @override
  MutableSeries<D> makeSeries(Series<dynamic, D> series) {
    final s = super.makeSeries(series);

    s.measureOffsetFn ??= (_) => 0;

    return s;
  }

  @override
  void preprocessSeries(List<MutableSeries<D>> seriesList) {
    _usePrimaryMeasureAxis = false;
    _useSecondaryMeasureAxis = false;

    // Check if primary or secondary measure axis is being used.
    for (final series in seriesList) {
      final measureAxisId = series.getAttr(measureAxisIdKey);
      _usePrimaryMeasureAxis = _usePrimaryMeasureAxis ||
          (measureAxisId == null ||
              measureAxisId == CartesianAxis.primaryMeasureAxisId);
      _useSecondaryMeasureAxis = _useSecondaryMeasureAxis ||
          (measureAxisId == CartesianAxis.secondaryMeasureAxisId);
    }

    final bool reverseAxisDirection = isRTL;

    final AxisDirection domainAxisDirection;
    final bool domainReverseAxisDirection;

    final AxisDirection primaryMeasureAxisDirection;
    final bool primaryMeasureReverseAxisDirection;

    final AxisDirection secondaryMeasureAxisDirection;
    final bool secondaryMeasureReverseAxisDirection;

    final AxisDirection disjointMeasureAxisDirection;
    final bool disjointMeasureReverseAxisDirection;

    if (widget.isVertical) {
      domainAxisDirection = AxisDirection.down;
      domainReverseAxisDirection = reverseAxisDirection;

      primaryMeasureAxisDirection =
          reverseAxisDirection ? AxisDirection.right : AxisDirection.left;
      primaryMeasureReverseAxisDirection = flipVerticalAxisOutput;

      secondaryMeasureAxisDirection =
          reverseAxisDirection ? AxisDirection.left : AxisDirection.right;
      secondaryMeasureReverseAxisDirection = flipVerticalAxisOutput;

      disjointMeasureAxisDirection =
          reverseAxisDirection ? AxisDirection.left : AxisDirection.right;
      disjointMeasureReverseAxisDirection = flipVerticalAxisOutput;
    } else {
      domainAxisDirection =
          reverseAxisDirection ? AxisDirection.right : AxisDirection.left;
      domainReverseAxisDirection = flipVerticalAxisOutput;

      primaryMeasureAxisDirection = AxisDirection.down;
      primaryMeasureReverseAxisDirection = reverseAxisDirection;

      secondaryMeasureAxisDirection = AxisDirection.up;
      secondaryMeasureReverseAxisDirection = reverseAxisDirection;

      disjointMeasureAxisDirection = AxisDirection.up;
      disjointMeasureReverseAxisDirection = reverseAxisDirection;
    }

    // Reset stale values from previous draw cycles.
    domainAxis?.resetDomains();
    domainAxis?.axisDirection = domainAxisDirection;
    domainAxis?.reverseOutputRange = domainReverseAxisDirection;

    _primaryMeasureAxis?.resetDomains();
    _primaryMeasureAxis?.axisDirection = primaryMeasureAxisDirection;
    _primaryMeasureAxis?.reverseOutputRange =
        primaryMeasureReverseAxisDirection;

    _secondaryMeasureAxis?.resetDomains();
    _secondaryMeasureAxis?.axisDirection = secondaryMeasureAxisDirection;
    _secondaryMeasureAxis?.reverseOutputRange =
        secondaryMeasureReverseAxisDirection;

    _disjointMeasureAxes.forEach((String axisId, NumericAxis axis) {
      axis.resetDomains();
      axis.axisDirection = disjointMeasureAxisDirection;
      axis.reverseOutputRange = disjointMeasureReverseAxisDirection;
    });

    if (_usePrimaryMeasureAxis && _primaryMeasureAxis == null) {
      final NumericAxisSpec spec = widget.primaryMeasureAxis;
      _primaryMeasureAxis = spec.createAxis(
        chartContext: this,
        tickDrawStrategy:
            const GridlineRendererSpec<num>().createDrawStrategy(this),
        axisDirection: primaryMeasureAxisDirection,
        reverseOutputRange: primaryMeasureReverseAxisDirection,
      );
    }

    if (_useSecondaryMeasureAxis && _secondaryMeasureAxis == null) {
      final NumericAxisSpec spec = widget.secondaryMeasureAxis;
      _secondaryMeasureAxis = spec.createAxis(
        chartContext: this,
        tickDrawStrategy:
            const GridlineRendererSpec<num>().createDrawStrategy(this),
        axisDirection: secondaryMeasureAxisDirection,
        reverseOutputRange: secondaryMeasureReverseAxisDirection,
      );
    }

    domainAxis ??= buildDomainAxis(
      axisDirection: domainAxisDirection,
      reverseOutputRange: domainReverseAxisDirection,
    );

    // // Have each renderer configure the axes with their domain and measure
    // // values.
    // rendererToSeriesList
    //     .forEach((String rendererId, List<MutableSeries<D>> seriesList) {
    //   getSeriesRenderer(rendererId)!.configureDomainAxes(seriesList);
    //   getSeriesRenderer(rendererId)!.configureMeasureAxes(seriesList);
    // });

    // return rendererToSeriesList;
  }

  @override
  void onPostLayout(Map<String, List<MutableSeries<D>>> rendererToSeriesList) {
    axisConfiguredNotifier.notifyListeners();
  }

  /// Returns a list of datum details from selection model of [type].
  @override
  List<DatumDetails<D>> getDatumDetails(SelectionModelType type) {
    final entries = <DatumDetails<D>>[];

    getSelectionModel(type).selectedDatum.forEach((seriesDatum) {
      final series = seriesDatum.series;
      final Object? datum = seriesDatum.datum;
      final datumIndex = seriesDatum.index;

      final domain = series.domainFn(datumIndex);
      final domainFormatterFn = series.domainFormatterFn;
      final measure = series.measureFn(datumIndex);
      final measureFormatterFn = series.measureFormatterFn;
      final measureOffset = series.measureOffsetFn!(datumIndex);
      final rawMeasure = series.rawMeasureFn(datumIndex);
      final color = series.colorFn!(datumIndex);

      final renderer = getSeriesRenderer(series.getAttr(rendererIdKey))!;

      final datumDetails = renderer.addPositionToDetailsForSeriesDatum(
        DatumDetails(
          datum: datum,
          domain: domain,
          domainFormatter: domainFormatterFn?.call(datumIndex),
          index: datumIndex,
          measure: measure,
          measureFormatter: measureFormatterFn?.call(datumIndex),
          measureOffset: measureOffset,
          rawMeasure: rawMeasure,
          series: series,
          color: color,
        ),
        seriesDatum,
      );

      entries.add(datumDetails);
    });

    return entries;
  }

  @protected
  Map<String, NumericAxis>? createDisjointMeasureAxes() {
    if (widget.disjointMeasureAxes != null) {
      final disjointAxes = {};

      // _disjointMeasureAxes.forEach((String axisId, NumericAxisSpec axisSpec) {
      //   disjointAxes[axisId] = axisSpec.createAxis();
      // });

      // return disjointAxes;
      return null;
    } else {
      return null;
    }
  }

  @override
  void didUpdateWidget(covariant S oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!ListEquality<Series<dynamic, D>>()
        .equals(widget.seriesList, oldWidget.seriesList)) {}
  }

  @override
  Widget buildChart() {
    final result = super.buildChart();

    return _Axis(
      domainAxis: domainAxis!,
      primaryMeasureAxis: _primaryMeasureAxis,
      secondaryMeasureAxis: _secondaryMeasureAxis,
      disjointMeasureAxes: _disjointMeasureAxes,
      isVertical: widget.isVertical,
      child: Container(
        //color: Color(0xff101010),
        child: result,
      ),
    );
  }
}

class _Axis<D> extends SingleChildRenderObjectWidget {
  const _Axis({
    super.key,
    required super.child,
    required this.domainAxis,
    required this.primaryMeasureAxis,
    required this.secondaryMeasureAxis,
    required this.disjointMeasureAxes,
    required this.isVertical,
  });

  final CartesianAxis<D> domainAxis;
  final NumericAxis? primaryMeasureAxis;
  final NumericAxis? secondaryMeasureAxis;
  final Map<String, NumericAxis> disjointMeasureAxes;
  final bool isVertical;

  @override
  RenderObject createRenderObject(BuildContext context) => _AxisRender(
        domainAxis: domainAxis,
        primaryMeasureAxis: primaryMeasureAxis,
        secondaryMeasureAxis: secondaryMeasureAxis,
        disjointMeasureAxes: disjointMeasureAxes,
        isVertical: isVertical,
      );

  @override
  void updateRenderObject(BuildContext context, _AxisRender renderObject) {
    renderObject
      ..domainAxis = domainAxis
      ..primaryMeasureAxis = primaryMeasureAxis
      ..secondaryMeasureAxis = secondaryMeasureAxis
      ..disjointMeasureAxes = disjointMeasureAxes
      ..isVertical = isVertical;
  }
}

class _AxisRender<D> extends RenderShiftedBox {
  _AxisRender({
    RenderBox? child,
    NumericAxis? primaryMeasureAxis,
    NumericAxis? secondaryMeasureAxis,
    required CartesianAxis<D> domainAxis,
    required Map<String, NumericAxis> disjointMeasureAxes,
    required bool isVertical,
  })  : _domainAxis = domainAxis,
        _primaryMeasureAxis = primaryMeasureAxis,
        _secondaryMeasureAxis = secondaryMeasureAxis,
        _disjointMeasureAxes = disjointMeasureAxes,
        _isVertical = isVertical,
        super(child);

  bool _isVertical;
  set isVertical(bool value) {
    if (_isVertical != value) {
      _isVertical = value;
      markNeedsLayout();
    }
  }

  CartesianAxis<D> _domainAxis;
  set domainAxis(CartesianAxis<D> value) {
    if (_domainAxis != value) {
      _domainAxis = value;
      markNeedsLayout();
    }
  }

  NumericAxis? _primaryMeasureAxis;
  set primaryMeasureAxis(NumericAxis? value) {
    if (_primaryMeasureAxis != value) {
      _primaryMeasureAxis = value;
      markNeedsLayout();
    }
  }

  NumericAxis? _secondaryMeasureAxis;
  set secondaryMeasureAxis(NumericAxis? value) {
    if (_secondaryMeasureAxis != value) {
      _secondaryMeasureAxis = value;
      markNeedsLayout();
    }
  }

  Map<String, NumericAxis> _disjointMeasureAxes;
  set disjointMeasureAxes(Map<String, NumericAxis> value) {
    if (_disjointMeasureAxes != value) {
      _disjointMeasureAxes = value;
      markNeedsLayout();
    }
  }

  Offset _domainOffset = Offset.zero;
  Offset _primaryMeasureOffsest = Offset.zero;
  Offset _secondaryMeasureOffset = Offset.zero;

  @override
  void performLayout() {
    double availableWidth = constraints.maxWidth;
    double availableHeight = constraints.maxHeight;
    double chartOffsetX = 0.0;
    double chartOffsetY = 0.0;

    final Size domainSize = _domainAxis.measure(constraints);
    final Size? primarySize = _primaryMeasureAxis?.measure(constraints);
    final Size? secondarySize = _secondaryMeasureAxis?.measure(constraints);

    if (_isVertical) {
      availableHeight -= domainSize.height;

      if (_primaryMeasureAxis != null) {
        if (_primaryMeasureAxis!.axisDirection == AxisDirection.left) {
          chartOffsetX += primarySize!.width;
        }

        availableWidth -= primarySize!.width;
      }

      if (_secondaryMeasureAxis != null) {
        if (_secondaryMeasureAxis!.axisDirection == AxisDirection.left) {
          chartOffsetX += secondarySize!.width;
        }

        availableWidth -= secondarySize!.width;
      }

      _domainAxis.measure(
        BoxConstraints(
          maxWidth: availableWidth,
          maxHeight: constraints.maxHeight,
        ),
      );
      _primaryMeasureAxis?.measure(
        BoxConstraints(
          maxWidth: constraints.maxWidth,
          maxHeight: availableHeight,
        ),
      );
      _secondaryMeasureAxis?.measure(
        BoxConstraints(
          maxWidth: constraints.maxWidth,
          maxHeight: availableHeight,
        ),
      );

      _domainOffset = Offset(chartOffsetX, 0.0);
      _primaryMeasureOffsest = Offset.zero;
      _secondaryMeasureOffset = Offset.zero;
    } else {
      if (_primaryMeasureAxis != null) {
        availableHeight -= primarySize!.height;

        if (_primaryMeasureAxis!.axisDirection == AxisDirection.up) {
          chartOffsetY += primarySize.height;
        }
      }

      if (_secondaryMeasureAxis != null) {
        availableHeight -= secondarySize!.height;

        if (_secondaryMeasureAxis!.axisDirection == AxisDirection.up) {
          chartOffsetY += secondarySize.height;
        }
      }

      if (_domainAxis.axisDirection == AxisDirection.left) {
        chartOffsetX += domainSize.width;
      }

      availableWidth -= domainSize.width;

      _domainAxis.measure(
        BoxConstraints(
          maxWidth: constraints.maxWidth,
          maxHeight: availableHeight,
        ),
      );
      _primaryMeasureAxis?.measure(
        BoxConstraints(
          maxWidth: availableWidth,
          maxHeight: constraints.maxHeight,
        ),
      );
      _secondaryMeasureAxis?.measure(
        BoxConstraints(
          maxWidth: availableWidth,
          maxHeight: constraints.maxHeight,
        ),
      );

      _domainOffset = Offset(0.0, chartOffsetY);
      _primaryMeasureOffsest = Offset(chartOffsetX, 0.0);
      _secondaryMeasureOffset = Offset(chartOffsetX, 0.0);
    }

    child!.layout(
        BoxConstraints(maxWidth: availableWidth, maxHeight: availableHeight));
    size = constraints.biggest;

    final BoxParentData childParentData = child!.parentData! as BoxParentData;
    childParentData.offset = Offset(chartOffsetX, chartOffsetY);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    _secondaryMeasureAxis?.update(_secondaryMeasureOffset + offset);
    _primaryMeasureAxis?.update(_primaryMeasureOffsest + offset);
    _domainAxis.update(_domainOffset + offset);

    _domainAxis.paint(context, _domainOffset + offset);
    _secondaryMeasureAxis?.paint(context, _secondaryMeasureOffset + offset);
    _primaryMeasureAxis?.paint(context, _primaryMeasureOffsest + offset);

    context.paintChild(
      child!,
      (child!.parentData! as BoxParentData).offset + offset,
    );
  }
}

class AxisItem<D, R extends CartesianAxis<D>> {
  const AxisItem({
    required this.axisDirection,
    required this.reverseOutputRange,
    required this.axis,
  });

  final R axis;

  final AxisDirection axisDirection;

  final bool reverseOutputRange;
}
