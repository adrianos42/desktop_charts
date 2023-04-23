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

import 'dart:math' show pi;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../../../text_element.dart' show MaxWidthStrategy, TextElement;
import '../../../theme.dart';
import '../../base_chart.dart'
    show BaseChartState, LifecycleListener, BaseChart;
import '../../cartesian/axis/axis.dart' show CartesianAxis;
import '../../cartesian/cartesian_chart.dart'
    show CartesianChartState, CartesianChart;
import '../../chart_canvas.dart' show ChartCanvas, getAnimatedColor;
import '../../processed_series.dart' show MutableSeries;
import '../chart_behavior.dart'
    show ChartBehavior, BehaviorPosition, ChartBehaviorState;
import '../../../theme.dart' show ChartsTheme;

const _defaultStrokeWidth = 2.0;

/// Chart behavior that annotates domain ranges with a solid fill color.
///
/// The annotations will be drawn underneath series data and chart axes.
///
/// This is typically used for line charts to call out sections of the data
/// range.
///
/// TODO: Support labels.
class RangeAnnotation<D> extends ChartBehavior<D> {
  RangeAnnotation(
    this.annotations, {
    AnnotationLabelAnchor? defaultLabelAnchor,
    AnnotationLabelDirection? defaultLabelDirection,
    AnnotationLabelPosition? defaultLabelPosition,
    this.defaultLabelStyleSpec,
    this.defaultColor,
    bool? extendAxis,
    double? labelPadding,
    double? defaultStrokeWidth,
  })  : defaultLabelAnchor = defaultLabelAnchor ?? _defaultLabelAnchor,
        defaultLabelDirection = defaultLabelDirection ?? _defaultLabelDirection,
        defaultLabelPosition = defaultLabelPosition ?? _defaultLabelPosition,
        extendAxis = extendAxis ?? true,
        labelPadding = labelPadding ?? _defaultLabelPadding,
        defaultStrokeWidth = defaultStrokeWidth ?? _defaultStrokeWidth;

  static const _defaultLabelAnchor = AnnotationLabelAnchor.end;
  static const _defaultLabelDirection = AnnotationLabelDirection.auto;
  static const _defaultLabelPosition = AnnotationLabelPosition.auto;
  static const _defaultLabelPadding = 5.0;

  /// List of annotations to render on the chart.
  final List<AnnotationSegment<Object>> annotations;

  /// Default color for annotations.
  final Color? defaultColor;

  /// Configures where to anchor annotation label text.
  final AnnotationLabelAnchor defaultLabelAnchor;

  /// Direction of label text on the annotations.
  final AnnotationLabelDirection defaultLabelDirection;

  /// Configures where to place labels relative to the annotation.
  final AnnotationLabelPosition defaultLabelPosition;

  /// Configures the style of label text.
  final TextStyle? defaultLabelStyleSpec;

  /// Configures the stroke width for line annotations.
  final double defaultStrokeWidth;

  /// Whether or not the range of the axis should be extended to include the
  /// annotation start and end values.
  final bool extendAxis;

  /// Space before and after label text.
  final double labelPadding;

  Map<String, _AnimatedAnnotation<D>> get _annotationMap =>
      throw 'Not implemented';

  /// Sub-classes can override this method to control label visibility.
  @protected
  bool shouldShowLabels(AnnotationSegment<Object> annotation) => true;

  @override
  BehaviorPosition get position => BehaviorPosition.insideBelowAxis;

  @override
  String get role => 'RangeAnnotation';

  @override
  ChartBehaviorState<D, S, RangeAnnotation<D>> build<S extends BaseChart<D>>({
    required BaseChartState<D, S> chartState,
  }) {
    return _RangeAnnotationState<D, S>(
      behavior: this,
      chartState: chartState,
    );
  }
}

class _RangeAnnotationState<D, S extends BaseChart<D>>
    extends ChartBehaviorState<D, S, RangeAnnotation<D>> {
  _RangeAnnotationState({
    required super.behavior,
    required super.chartState,
  }) {
    if (chartState is! CartesianChartState<D, CartesianChart<D>>) {
      throw ArgumentError(
          'RangeAnnotation can only be attached to a CartesianChart<D>');
    }

    _lifecycleListener = LifecycleListener<D>(
      onPostprocess: (List<MutableSeries<D>> series) {
        updateAxisRange(series);
      },
    );

    chartState.addLifecycleListener(_lifecycleListener);
  }

  late LifecycleListener<D> _lifecycleListener;
  CartesianChartState<D, CartesianChart<D>> get _chartState =>
      chartState as CartesianChartState<D, CartesianChart<D>>;

  void updateAxisRange(List<MutableSeries<D>> seriesList) {
    // Extend the axis range if enabled.
    if (behavior.extendAxis) {
      for (final annotation in behavior.annotations) {
        // Either an Axis<D> and Axis<double>.
        CartesianAxis<Object?> axis;

        switch (annotation.axisType) {
          case RangeAnnotationAxisType.domain:
            axis = _chartState.domainAxis!;
            break;

          case RangeAnnotationAxisType.measure:
            // We expect an empty axisId to get us the primary measure axis.
            axis = _chartState.getMeasureAxis(axisId: annotation.axisId);
            break;
        }

        if (annotation is RangeAnnotationSegment<Object>) {
          axis.addDomainValue(annotation.startValue);
          axis.addDomainValue(annotation.endValue);
        } else if (annotation is LineAnnotationSegment<Object>) {
          axis.addDomainValue(annotation.value);
        }
      }
    }
  }

  @override
  void dispose() {
    chartState.removeLifecycleListener(_lifecycleListener);

    super.dispose();
  }

  @override
  Widget buildBehaviorWidget(BuildContext context) {
    final themeData = ChartsTheme.of(context);

    return _RangeAnnotationLayoutRenderObjectWidget<D, CartesianChart<D>>(
      chartState: chartState as CartesianChartState<D, CartesianChart<D>>,
      annotations: behavior.annotations,
      defaultColor: behavior.defaultColor ?? themeData.rangeAnnotationColor,
      defaultLabelAnchor: behavior.defaultLabelAnchor,
      defaultLabelDirection: behavior.defaultLabelDirection,
      defaultLabelPosition: behavior.defaultLabelPosition,
      defaultLabelStyleSpec:
          behavior.defaultLabelStyleSpec ?? themeData.labelStyle,
      defaultStrokeWidth: behavior.defaultStrokeWidth,
      extendAxis: behavior.extendAxis,
      labelPadding: behavior.labelPadding,
      rangeAnnotation: behavior,
    );
  }
}

class _RangeAnnotationLayoutRenderObjectWidget<D, S extends CartesianChart<D>>
    extends LeafRenderObjectWidget {
  const _RangeAnnotationLayoutRenderObjectWidget({
    required this.chartState,
    required this.annotations,
    required this.defaultColor,
    required this.defaultLabelAnchor,
    required this.defaultLabelDirection,
    required this.defaultLabelPosition,
    required this.defaultLabelStyleSpec,
    required this.defaultStrokeWidth,
    required this.extendAxis,
    required this.labelPadding,
    required this.rangeAnnotation,
    super.key,
  });

  final CartesianChartState<D, S> chartState;

  final AnnotationLabelAnchor defaultLabelAnchor;

  final AnnotationLabelDirection defaultLabelDirection;

  final AnnotationLabelPosition defaultLabelPosition;

  final TextStyle defaultLabelStyleSpec;

  final double defaultStrokeWidth;

  final bool extendAxis;

  final List<AnnotationSegment<Object>> annotations;

  final Color defaultColor;

  final double labelPadding;

  final RangeAnnotation<D> rangeAnnotation;

  @override
  _RangeAnnotationLayoutRender<D> createRenderObject(BuildContext context) =>
      _RangeAnnotationLayoutRender<D>(
        chartState: chartState,
        annotations: annotations,
        defaultColor: defaultColor,
        defaultLabelAnchor: defaultLabelAnchor,
        defaultLabelDirection: defaultLabelDirection,
        defaultLabelPosition: defaultLabelPosition,
        defaultLabelStyleSpec: defaultLabelStyleSpec,
        defaultStrokeWidth: defaultStrokeWidth,
        extendAxis: extendAxis,
        labelPadding: labelPadding,
        rangeAnnotation: rangeAnnotation,
      );

  @override
  void updateRenderObject(
      BuildContext context, _RangeAnnotationLayoutRender<D> renderObject) {}
}

class _RangeAnnotationLayoutRender<D> extends RenderBox {
  _RangeAnnotationLayoutRender({
    required Color defaultColor,
    required double labelPadding,
    required RangeAnnotation<D> rangeAnnotation,
    required List<AnnotationSegment<Object>> annotations,
    required this.chartState,
    required this.defaultLabelAnchor,
    required this.defaultLabelDirection,
    required this.defaultLabelPosition,
    required this.defaultLabelStyleSpec,
    required this.defaultStrokeWidth,
    required this.extendAxis,
  })  : _rangeAnnotation = rangeAnnotation,
        _labelPadding = labelPadding,
        _defaultColor = defaultColor,
        _annotations = annotations;

  final AnnotationLabelAnchor defaultLabelAnchor;

  final AnnotationLabelDirection defaultLabelDirection;

  final AnnotationLabelPosition defaultLabelPosition;

  final TextStyle defaultLabelStyleSpec;

  final double defaultStrokeWidth;

  final bool extendAxis;

  final List<AnnotationSegment<Object>> _annotations;

  final Color _defaultColor;

  final double _labelPadding;

  final RangeAnnotation<D> _rangeAnnotation;

  final CartesianChartState<D, CartesianChart<D>> chartState;

  bool get isRtl => chartState.isRTL;

  /// Store a map of data drawn on the chart, mapped by series name.
  ///
  /// [Map] is used to render the series on the canvas in the same
  /// order as the data was given to the chart.
  // ignore: prefer_collection_literals, https://github.com/dart-lang/linter/issues/1649
  final _annotationMap = Map<String, _AnimatedAnnotation<D>>();

  // Store a list of annotations that exist in the current annotation list.
  //
  // This list will be used to remove any [_AnimatedAnnotation] that were
  // rendered in previous draw cycles, but no longer have a corresponding datum
  // in the data.
  final _currentKeys = <String>[];

  void update() {
    _currentKeys.clear();

    // The values (T) can match the data type of the domain (D) or measure axis
    // (double).
    void updateAnnotation<T>(
      CartesianAxis<T> axis,
      AnnotationSegment<Object> annotation,
    ) {
      final key = annotation.key;

      final color = annotation.color ?? _defaultColor;

      final startLabel = annotation.startLabel;
      final endLabel = annotation.endLabel;
      final middleLabel = annotation.middleLabel;
      final labelAnchor = annotation.labelAnchor ?? defaultLabelAnchor;
      AnnotationLabelDirection labelDirection =
          annotation.labelDirection ?? defaultLabelDirection;

      if (labelDirection == AnnotationLabelDirection.auto) {
        switch (annotation.axisType) {
          case RangeAnnotationAxisType.domain:
            labelDirection = AnnotationLabelDirection.vertical;
            break;

          case RangeAnnotationAxisType.measure:
            labelDirection = AnnotationLabelDirection.horizontal;
            break;
        }
      }

      final labelPosition = annotation.labelPosition ?? defaultLabelPosition;
      final labelStyleSpec = annotation.labelStyleSpec ?? defaultLabelStyleSpec;

      // Add line annotation settings.
      final dashPattern = annotation is LineAnnotationSegment<Object>
          ? annotation.dashPattern
          : null;
      final strokeWidth = annotation is LineAnnotationSegment<Object>
          ? annotation.strokeWidth
          : 0.0;

      final isRange = annotation is RangeAnnotationSegment;

      final T startValue;
      final T endValue;

      // We unfortunately can't check for `RangeAnnotationSegment<T>` nor
      // `LineAnnotationSegment<T>` here because the `AnnotationSegment` object
      // might not have been parameterized on `T` when it was initially
      // constructed.
      if (annotation is RangeAnnotationSegment<Object>) {
        startValue = annotation.startValue as T;
        endValue = annotation.endValue as T;
      } else if (annotation is LineAnnotationSegment<Object>) {
        startValue = endValue = annotation.value as T;
      } else {
        throw UnsupportedError(
            'Unrecognized annotation type: ${annotation.runtimeType}');
      }

      final annotationDatum =
          _getAnnotationDatum(startValue, endValue, axis, annotation.axisType);

      // If we already have a animatingAnnotation for that index, use it.
      _AnimatedAnnotation<D>? animatingAnnotation = _annotationMap[key];
      if (animatingAnnotation == null) {
        // Create a annotation, positioned at the start and end values.
        animatingAnnotation = _AnimatedAnnotation<D>(key: key)
          ..setNewTarget(_AnnotationElement<D>(
            annotation: annotationDatum,
            annotationSegment: annotation,
            color: color,
            dashPattern: dashPattern,
            startLabel: startLabel,
            endLabel: endLabel,
            middleLabel: middleLabel,
            isRange: isRange,
            labelAnchor: labelAnchor,
            labelDirection: labelDirection,
            labelPosition: labelPosition,
            labelStyleSpec: labelStyleSpec,
            strokeWidth: strokeWidth,
          ));

        _annotationMap[key] = animatingAnnotation;
      }

      // Update the set of annotations that still exist in the series data.
      _currentKeys.add(key);

      // Get the annotation element we are going to setup.
      final annotationElement = _AnnotationElement<D>(
        annotation: annotationDatum,
        annotationSegment: annotation,
        color: color,
        dashPattern: dashPattern,
        startLabel: startLabel,
        endLabel: endLabel,
        middleLabel: middleLabel,
        isRange: isRange,
        labelAnchor: labelAnchor,
        labelDirection: labelDirection,
        labelPosition: labelPosition,
        labelStyleSpec: labelStyleSpec,
        strokeWidth: strokeWidth,
      );

      animatingAnnotation.setNewTarget(annotationElement);
    }

    for (final annotation in _annotations) {
      switch (annotation.axisType) {
        case RangeAnnotationAxisType.domain:
          updateAnnotation(chartState.domainAxis!, annotation);
          break;

        case RangeAnnotationAxisType.measure:
          // We expect an empty axisId to get us the primary measure axis.
          updateAnnotation(
              chartState.getMeasureAxis(axisId: annotation.axisId), annotation);
          break;
      }
    }

    // Animate out annotations that don't exist anymore.
    _annotationMap.forEach((String key, _AnimatedAnnotation<D> annotation) {
      if (!_currentKeys.contains(annotation.key)) {
        annotation.animateOut();
      }
    });
  }

  /// Generates a datum that describes an annotation.
  ///
  /// [startValue] and [endValue] are dynamic because they can be different data
  /// types for domain and measure axes, e.g. DateTime and double for a TimeSeries
  /// chart.
  _DatumAnnotation _getAnnotationDatum<T>(T startValue, T endValue,
      CartesianAxis<T> axis, RangeAnnotationAxisType axisType) {
    // Remove floating point rounding errors by rounding to 2 decimal places of
    // precision. The difference in the canvas is negligible.
    final startPosition = (axis.getLocation(startValue)! * 100).round() / 100;
    final endPosition = (axis.getLocation(endValue)! * 100).round() / 100;

    return _DatumAnnotation(
        startPosition: startPosition,
        endPosition: endPosition,
        axisType: axisType);
  }

  late LifecycleListener<D> _lifecycleListener;

  bool _needsUpdate = true;
  void _markNeedsUpdate() {
    _needsUpdate = true;
    markNeedsPaint();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    chartState.animationPosition.addListener(markNeedsPaint);

    _lifecycleListener = LifecycleListener<D>(
      onAxisConfigured: () {
        _markNeedsUpdate();
      },
    );

    chartState.addLifecycleListener(_lifecycleListener);
  }

  @override
  void detach() {
    chartState.removeLifecycleListener(_lifecycleListener);
    chartState.animationPosition.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  void performLayout() {
    _markNeedsUpdate();
    size = constraints.biggest;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_needsUpdate) {
      update();
      _needsUpdate = false;
    }

    final animationPercent = chartState.animationPosition.value;

    // Clean up the annotations that no longer exist.
    if (animationPercent == 1.0) {
      final keysToRemove = <String>[];

      _annotationMap.forEach((String key, _AnimatedAnnotation<D> annotation) {
        if (annotation.animatingOut) {
          keysToRemove.add(key);
        }
      });

      keysToRemove.forEach(_annotationMap.remove);
    }

    _annotationMap.forEach((String key, _AnimatedAnnotation<D> annotation) {
      final annotationElement =
          annotation.getCurrentAnnotation(animationPercent);

      // Calculate the bounds of a range annotation.
      //
      // This will still be used for line annotations to compute the position of
      // labels. We always expect those to end up outside, since the bounds will
      // have zero width or  height.
      final bounds = _getAnnotationBounds(annotationElement);

      if (annotationElement.isRange) {
        // Draw the annotation.
        context.canvas.drawChartRect(
          offset,
          bounds,
          fill: annotationElement.color!,
        );
      } else {
        // Calculate the points for a line annotation.
        final points = _getLineAnnotationPoints(annotationElement);

        // Draw the annotation.
        context.canvas.drawChartLine(
          offset,
          dashPattern: annotationElement.dashPattern,
          points: points,
          stroke: annotationElement.color!,
          strokeWidth: annotationElement.strokeWidth,
        );
      }

      // Create [TextStyle] from [TextStyle] to be used by all the elements.
      final labelStyle = _getTextStyle(annotationElement.labelStyleSpec);

      final rotation =
          annotationElement.labelDirection == AnnotationLabelDirection.vertical
              ? -pi / 2.0
              : 0.0;

      if (_rangeAnnotation
          .shouldShowLabels(annotationElement.annotationSegment)) {
        final labels = {
          if (annotationElement.startLabel != null)
            _AnnotationLabelType.start: annotationElement.startLabel,
          if (annotationElement.endLabel != null)
            _AnnotationLabelType.end: annotationElement.endLabel,
          if (annotationElement.middleLabel != null)
            _AnnotationLabelType.middle: annotationElement.middleLabel,
        };

        // Draw labels that have been defined.
        labels.forEach((labelType, label) {
          final labelElement = TextElement(label!)
            ..maxWidthStrategy = MaxWidthStrategy.ellipsize
            ..textStyle = labelStyle;

          // Measure the label max width once if either type of label is defined.
          labelElement.maxWidth = _getLabelMaxWidth(
            bounds,
            annotationElement,
            labelElement,
          );

          final labelPoint = _getLabelPosition(
              labelType, bounds, annotationElement, labelElement);

          if (labelPoint != null) {
            context.canvas.drawChartText(
              offset,
              labelElement,
              labelPoint.dx,
              labelPoint.dy,
              rotation: rotation,
            );
          }
        });
      }
    });
  }

  /// Calculates the bounds of the annotation.
  Rect _getAnnotationBounds(_AnnotationElement<D> annotationElement) {
    final drawAreaBounds = Offset.zero & size;
    return switch (annotationElement.annotation.axisType) {
      RangeAnnotationAxisType.domain => Rect.fromLTWH(
          annotationElement.annotation.startPosition,
          drawAreaBounds.top,
          annotationElement.annotation.endPosition -
              annotationElement.annotation.startPosition,
          drawAreaBounds.height),
      RangeAnnotationAxisType.measure => Rect.fromLTWH(
          drawAreaBounds.left,
          annotationElement.annotation.endPosition,
          drawAreaBounds.width,
          annotationElement.annotation.startPosition -
              annotationElement.annotation.endPosition)
    };
  }

  /// Calculates the bounds of the annotation.
  List<Offset> _getLineAnnotationPoints(
      _AnnotationElement<D> annotationElement) {
    final drawAreaBounds = Offset.zero & size;
    final points = <Offset>[];

    switch (annotationElement.annotation.axisType) {
      case RangeAnnotationAxisType.domain:
        points.add(Offset(
            annotationElement.annotation.startPosition, drawAreaBounds.top));
        points.add(Offset(
            annotationElement.annotation.endPosition, drawAreaBounds.bottom));
        break;

      case RangeAnnotationAxisType.measure:
        points.add(Offset(
            drawAreaBounds.left, annotationElement.annotation.startPosition));
        points.add(Offset(
            drawAreaBounds.right, annotationElement.annotation.endPosition));
        break;
    }

    return points;
  }

  /// Measures the max label width of the annotation.
  double _getLabelMaxWidth(
    Rect bounds,
    _AnnotationElement<D> annotationElement,
    TextElement labelElement,
  ) {
    final drawBounds = Offset.zero & size;
    double maxWidth = 0;

    final calculatedLabelPosition =
        _resolveAutoLabelPosition(bounds, annotationElement, labelElement);

    if (annotationElement.labelPosition == AnnotationLabelPosition.margin &&
        annotationElement.annotation.axisType ==
            RangeAnnotationAxisType.measure) {
      switch (annotationElement.annotation.axisType) {
        case RangeAnnotationAxisType.domain:
          break;

        case RangeAnnotationAxisType.measure:
          switch (annotationElement.labelAnchor) {
            case AnnotationLabelAnchor.start:
              // TODO maxWidth = chart!.marginLeft - labelPadding;
              break;

            case AnnotationLabelAnchor.end:
              // TODO maxWidth = chart!.marginRight - labelPadding;
              break;

            case AnnotationLabelAnchor.middle:
              break;
          }
          break;
      }
    } else {
      if (calculatedLabelPosition == AnnotationLabelPosition.outside) {
        maxWidth = annotationElement.labelDirection ==
                AnnotationLabelDirection.horizontal
            ? drawBounds.width
            : drawBounds.height;
      } else {
        maxWidth = annotationElement.labelDirection ==
                AnnotationLabelDirection.horizontal
            ? bounds.width
            : bounds.height;
      }
    }

    return maxWidth.roundToDouble();
  }

  /// Gets the resolved location for a label element.
  Offset? _getLabelPosition(_AnnotationLabelType labelType, Rect bounds,
      _AnnotationElement<D> annotationElement, TextElement labelElement) {
    return switch (annotationElement.annotation.axisType) {
      RangeAnnotationAxisType.domain => _getDomainLabelPosition(
          labelType, bounds, annotationElement, labelElement),
      RangeAnnotationAxisType.measure => _getMeasureLabelPosition(
          labelType, bounds, annotationElement, labelElement)
    };
  }

  /// Gets the resolved location for a domain annotation label element.
  Offset _getDomainLabelPosition(_AnnotationLabelType labelType, Rect bounds,
      _AnnotationElement<D> annotationElement, TextElement labelElement) {
    if (annotationElement.labelDirection == AnnotationLabelDirection.vertical) {
      return _getDomainLabelPositionVertical(
          labelType, bounds, annotationElement, labelElement);
    } else {
      return _getDomainLabelPositionHorizontal(
          labelType, bounds, annotationElement, labelElement);
    }
  }

  /// Gets the resolved location for a horizontal domain annotation label
  /// element.
  Offset _getDomainLabelPositionHorizontal(
      _AnnotationLabelType labelType,
      Rect bounds,
      _AnnotationElement<D> annotationElement,
      TextElement labelElement) {
    double labelX = 0;
    double labelY = 0;

    final calculatedLabelPosition =
        _resolveAutoLabelPosition(bounds, annotationElement, labelElement);

    switch (annotationElement.labelAnchor) {
      case AnnotationLabelAnchor.middle:
        labelY = bounds.top +
            bounds.height / 2 -
            labelElement.measurement.verticalSliceWidth / 2 -
            _labelPadding;
        break;

      case AnnotationLabelAnchor.end:
        if (annotationElement.labelPosition == AnnotationLabelPosition.margin) {
          labelY = bounds.top -
              labelElement.measurement.verticalSliceWidth -
              _labelPadding;
        } else {
          labelY = bounds.top + _labelPadding;
        }
        break;

      case AnnotationLabelAnchor.start:
        if (annotationElement.labelPosition == AnnotationLabelPosition.margin) {
          labelY = bounds.bottom + _labelPadding;
        } else {
          labelY = bounds.bottom -
              labelElement.measurement.verticalSliceWidth -
              _labelPadding;
        }
        break;
    }

    switch (calculatedLabelPosition) {
      case AnnotationLabelPosition.margin:
      case AnnotationLabelPosition.auto:
        throw ArgumentError(_unresolvedAutoMessage);

      case AnnotationLabelPosition.outside:
        switch (labelType) {
          case _AnnotationLabelType.start:
            labelX = bounds.left -
                labelElement.measurement.horizontalSliceWidth -
                _labelPadding;
            break;
          case _AnnotationLabelType.end:
            labelX = bounds.right + _labelPadding;
            break;
          case _AnnotationLabelType.middle:
            labelX = bounds.left +
                (bounds.width - labelElement.measurement.horizontalSliceWidth) /
                    2;
            break;
        }

        labelElement.textDirection =
            isRtl ? TextDirection.rtl : TextDirection.ltr;
        break;

      case AnnotationLabelPosition.inside:
        switch (labelType) {
          case _AnnotationLabelType.start:
            labelX = bounds.left + _labelPadding;
            break;
          case _AnnotationLabelType.end:
            labelX = bounds.right -
                labelElement.measurement.horizontalSliceWidth -
                _labelPadding;
            break;
          case _AnnotationLabelType.middle:
            labelX = bounds.left +
                (bounds.width - labelElement.measurement.horizontalSliceWidth) /
                    2;
            break;
        }

        labelElement.textDirection =
            isRtl ? TextDirection.rtl : TextDirection.ltr;
        break;
    }

    return Offset(labelX.roundToDouble(), labelY.roundToDouble());
  }

  /// Gets the resolved location for a vertical domain annotation label element.
  Offset _getDomainLabelPositionVertical(
      _AnnotationLabelType labelType,
      Rect bounds,
      _AnnotationElement<D> annotationElement,
      TextElement labelElement) {
    double labelX = 0;
    double labelY = 0;

    final calculatedLabelPosition =
        _resolveAutoLabelPosition(bounds, annotationElement, labelElement);

    switch (annotationElement.labelAnchor) {
      case AnnotationLabelAnchor.middle:
        labelY = bounds.top +
            bounds.height / 2 +
            labelElement.measurement.horizontalSliceWidth / 2 +
            _labelPadding;
        break;

      case AnnotationLabelAnchor.end:
        if (annotationElement.labelPosition == AnnotationLabelPosition.margin) {
          labelY = bounds.top +
              labelElement.measurement.horizontalSliceWidth +
              _labelPadding;
        } else {
          labelY = bounds.top +
              labelElement.measurement.horizontalSliceWidth +
              _labelPadding;
        }
        break;

      case AnnotationLabelAnchor.start:
        if (annotationElement.labelPosition == AnnotationLabelPosition.margin) {
          labelY = bounds.bottom + _labelPadding;
        } else {
          labelY = bounds.bottom -
              labelElement.measurement.horizontalSliceWidth -
              _labelPadding;
        }
        break;
    }

    switch (calculatedLabelPosition) {
      case AnnotationLabelPosition.margin:
      case AnnotationLabelPosition.auto:
        throw ArgumentError(_unresolvedAutoMessage);

      case AnnotationLabelPosition.outside:
        switch (labelType) {
          case _AnnotationLabelType.start:
            labelX = bounds.left -
                labelElement.measurement.verticalSliceWidth -
                _labelPadding;
            break;
          case _AnnotationLabelType.end:
            labelX = bounds.right + _labelPadding;
            break;
          case _AnnotationLabelType.middle:
            labelX = bounds.left +
                (bounds.width - labelElement.measurement.verticalSliceWidth) /
                    2;
            break;
        }

        labelElement.textDirection =
            isRtl ? TextDirection.rtl : TextDirection.ltr;
        break;

      case AnnotationLabelPosition.inside:
        switch (labelType) {
          case _AnnotationLabelType.start:
            labelX = bounds.left + _labelPadding;
            break;
          case _AnnotationLabelType.end:
            labelX = bounds.right -
                labelElement.measurement.verticalSliceWidth -
                _labelPadding;
            break;
          case _AnnotationLabelType.middle:
            labelX = bounds.left +
                (bounds.width - labelElement.measurement.verticalSliceWidth) /
                    2;
            break;
        }

        labelElement.textDirection =
            isRtl ? TextDirection.rtl : TextDirection.ltr;
        break;
    }

    return Offset(labelX.roundToDouble(), labelY.roundToDouble());
  }

  /// Gets the resolved location for a measure annotation label element.
  Offset _getMeasureLabelPosition(
    _AnnotationLabelType labelType,
    Rect bounds,
    _AnnotationElement<D> annotationElement,
    TextElement labelElement,
  ) {
    if (annotationElement.labelDirection == AnnotationLabelDirection.vertical) {
      return _getMeasureLabelPositionVertical(
        labelType,
        bounds,
        annotationElement,
        labelElement,
      );
    } else {
      return _getMeasureLabelPositionHorizontal(
        labelType,
        bounds,
        annotationElement,
        labelElement,
      );
    }
  }

  /// Gets the resolved location for a horizontal measure annotation label
  /// element.
  Offset _getMeasureLabelPositionHorizontal(
      _AnnotationLabelType labelType,
      Rect bounds,
      _AnnotationElement<D> annotationElement,
      TextElement labelElement) {
    double labelX = 0;
    double labelY = 0;

    final calculatedLabelPosition = _resolveAutoLabelPosition(
      bounds,
      annotationElement,
      labelElement,
    );

    switch (annotationElement.labelAnchor) {
      case AnnotationLabelAnchor.middle:
        labelX = bounds.left +
            bounds.width / 2.0 -
            labelElement.measurement.horizontalSliceWidth / 2.0;
        labelElement.textDirection =
            isRtl ? TextDirection.rtl : TextDirection.ltr;
        break;

      case AnnotationLabelAnchor.end:
      case AnnotationLabelAnchor.start:
        if (annotationElement.labelPosition == AnnotationLabelPosition.margin) {
          final alignLeft = isRtl
              ? (annotationElement.labelAnchor == AnnotationLabelAnchor.end)
              : (annotationElement.labelAnchor == AnnotationLabelAnchor.start);

          if (alignLeft) {
            labelX = bounds.left - _labelPadding;
            labelElement.textDirection = TextDirection.rtl;
          } else {
            labelX = bounds.right + _labelPadding;
            labelElement.textDirection = TextDirection.ltr;
          }
        } else {
          final alignLeft = isRtl
              ? (annotationElement.labelAnchor == AnnotationLabelAnchor.end)
              : (annotationElement.labelAnchor == AnnotationLabelAnchor.start);

          if (alignLeft) {
            labelX = bounds.left + _labelPadding;
            labelElement.textDirection = TextDirection.ltr;
          } else {
            labelX = bounds.right - _labelPadding;
            labelElement.textDirection = TextDirection.rtl;
          }
        }
        break;
    }

    switch (calculatedLabelPosition) {
      case AnnotationLabelPosition.margin:
      case AnnotationLabelPosition.auto:
        throw ArgumentError(_unresolvedAutoMessage);

      case AnnotationLabelPosition.outside:
        switch (labelType) {
          case _AnnotationLabelType.start:
            labelY = bounds.bottom + _labelPadding;
            break;
          case _AnnotationLabelType.end:
            labelY = bounds.top -
                labelElement.measurement.verticalSliceWidth -
                _labelPadding;
            break;
          case _AnnotationLabelType.middle:
            labelY = bounds.top +
                (bounds.height - labelElement.measurement.verticalSliceWidth) /
                    2;
            break;
        }
        break;

      case AnnotationLabelPosition.inside:
        switch (labelType) {
          case _AnnotationLabelType.start:
            labelY = bounds.bottom -
                labelElement.measurement.verticalSliceWidth -
                _labelPadding;
            break;
          case _AnnotationLabelType.end:
            labelY = bounds.top + _labelPadding;
            break;
          case _AnnotationLabelType.middle:
            labelY = bounds.top +
                (bounds.height - labelElement.measurement.verticalSliceWidth) /
                    2;
            break;
        }
        break;
    }

    return Offset(labelX.roundToDouble(), labelY.roundToDouble());
  }

  /// Gets the resolved location for a vertical measure annotation label
  /// element.
  Offset _getMeasureLabelPositionVertical(
      _AnnotationLabelType labelType,
      Rect bounds,
      _AnnotationElement<D> annotationElement,
      TextElement labelElement) {
    double labelX = 0;
    double labelY = 0;

    final calculatedLabelPosition =
        _resolveAutoLabelPosition(bounds, annotationElement, labelElement);

    switch (annotationElement.labelAnchor) {
      case AnnotationLabelAnchor.middle:
        labelX = bounds.left +
            bounds.width / 2 -
            labelElement.measurement.verticalSliceWidth / 2;
        labelElement.textDirection =
            isRtl ? TextDirection.rtl : TextDirection.ltr;
        break;

      case AnnotationLabelAnchor.end:
      case AnnotationLabelAnchor.start:
        if (annotationElement.labelPosition == AnnotationLabelPosition.margin) {
          final alignLeft = isRtl
              ? (annotationElement.labelAnchor == AnnotationLabelAnchor.end)
              : (annotationElement.labelAnchor == AnnotationLabelAnchor.start);

          if (alignLeft) {
            labelX = bounds.left -
                labelElement.measurement.verticalSliceWidth -
                _labelPadding;
            labelElement.textDirection = TextDirection.ltr;
          } else {
            labelX = bounds.right + _labelPadding;
            labelElement.textDirection = TextDirection.ltr;
          }
        } else {
          final alignLeft = isRtl
              ? (annotationElement.labelAnchor == AnnotationLabelAnchor.end)
              : (annotationElement.labelAnchor == AnnotationLabelAnchor.start);

          if (alignLeft) {
            labelX = bounds.left + _labelPadding;
            labelElement.textDirection = TextDirection.ltr;
          } else {
            labelX = bounds.right -
                labelElement.measurement.verticalSliceWidth -
                _labelPadding;
            labelElement.textDirection = TextDirection.ltr;
          }
        }
        break;
    }

    switch (calculatedLabelPosition) {
      case AnnotationLabelPosition.margin:
      case AnnotationLabelPosition.auto:
        throw ArgumentError(_unresolvedAutoMessage);

      case AnnotationLabelPosition.outside:
        switch (labelType) {
          case _AnnotationLabelType.start:
            labelY = bounds.bottom +
                labelElement.measurement.horizontalSliceWidth +
                _labelPadding;
            break;
          case _AnnotationLabelType.end:
            labelY = bounds.top - _labelPadding;
            break;
          case _AnnotationLabelType.middle:
            labelY = bounds.bottom +
                (labelElement.measurement.horizontalSliceWidth -
                        bounds.height) /
                    2;
            break;
        }
        break;

      case AnnotationLabelPosition.inside:
        switch (labelType) {
          case _AnnotationLabelType.start:
            labelY = bounds.bottom - _labelPadding;
            break;
          case _AnnotationLabelType.end:
            labelY = bounds.top +
                labelElement.measurement.horizontalSliceWidth +
                _labelPadding;
            break;
          case _AnnotationLabelType.middle:
            labelY = bounds.bottom +
                (labelElement.measurement.horizontalSliceWidth -
                        bounds.height) /
                    2;
            break;
        }
        break;
    }

    return Offset(labelX.roundToDouble(), labelY.roundToDouble());
  }

  /// Resolves [AnnotationLabelPosition.auto] configuration for an annotation
  /// into an inside or outside position, depending on the size of the
  /// annotation and the chart draw area.
  AnnotationLabelPosition _resolveAutoLabelPosition(Rect bounds,
      _AnnotationElement<D> annotationElement, TextElement labelElement) {
    final drawBounds = Offset.zero & size;

    AnnotationLabelPosition calculatedLabelPosition =
        annotationElement.labelPosition;

    if (calculatedLabelPosition == AnnotationLabelPosition.auto ||
        calculatedLabelPosition == AnnotationLabelPosition.margin) {
      final isDomain = annotationElement.annotation.axisType ==
          RangeAnnotationAxisType.domain;

      final annotationBoundsSize = isDomain ? bounds.width : bounds.height;

      final drawBoundsSize = isDomain ? drawBounds.width : drawBounds.height;

      final isVertical =
          annotationElement.labelDirection == AnnotationLabelDirection.vertical;

      final labelSize = isDomain && isVertical || !isDomain && !isVertical
          ? labelElement.measurement.verticalSliceWidth
          : labelElement.measurement.horizontalSliceWidth;

      // Get space available inside and outside the annotation.
      final totalPadding = _labelPadding * 2;
      final insideBarWidth = annotationBoundsSize - totalPadding;
      final outsideBarWidth =
          drawBoundsSize - annotationBoundsSize - totalPadding;

      // A label fits if the space inside the annotation is >= outside
      // annotation or if the length of the text fits and the space. This is
      // because if the annotation has more space than the outside, it makes
      // more sense to place the label inside the annotation, even if the
      // entire label does not fit.
      calculatedLabelPosition =
          (insideBarWidth >= outsideBarWidth || labelSize < insideBarWidth)
              ? AnnotationLabelPosition.inside
              : AnnotationLabelPosition.outside;
    }

    return calculatedLabelPosition;
  }

  // Helper function that converts [TextStyle] to [TextStyle].
  TextStyle _getTextStyle(TextStyle labelSpec) {
    return TextStyle(
      color: labelSpec.color ?? const ChartsThemeData.fallbackw().foreground,
      fontFamily: labelSpec.fontFamily,
      fontSize: labelSpec.fontSize ?? 12.0,
      height: labelSpec.height,
    );
  }
}

@immutable
class _DatumAnnotation {
  const _DatumAnnotation({
    required this.startPosition,
    required this.endPosition,
    required this.axisType,
  });

  factory _DatumAnnotation.from(_DatumAnnotation other,
      [double? startPosition, double? endPosition]) {
    return _DatumAnnotation(
        startPosition: startPosition ?? other.startPosition,
        endPosition: endPosition ?? other.endPosition,
        axisType: other.axisType);
  }

  final double startPosition;
  final double endPosition;
  final RangeAnnotationAxisType axisType;
}

class _AnnotationElement<D> {
  _AnnotationElement({
    required this.annotation,
    required this.annotationSegment,
    required this.color,
    required this.startLabel,
    required this.endLabel,
    required this.middleLabel,
    required this.isRange,
    required this.labelAnchor,
    required this.labelDirection,
    required this.labelPosition,
    required this.labelStyleSpec,
    required this.dashPattern,
    required this.strokeWidth,
  });

  _DatumAnnotation annotation;
  final AnnotationSegment<Object> annotationSegment;
  Color? color;
  final String? startLabel;
  final String? endLabel;
  final String? middleLabel;
  final bool isRange;
  final AnnotationLabelAnchor labelAnchor;
  final AnnotationLabelDirection labelDirection;
  final AnnotationLabelPosition labelPosition;
  final TextStyle labelStyleSpec;
  final List<int>? dashPattern;
  double strokeWidth;

  _AnnotationElement<D> clone() {
    return _AnnotationElement<D>(
      annotation: _DatumAnnotation.from(annotation),
      annotationSegment: annotationSegment,
      color: color,
      startLabel: startLabel,
      endLabel: endLabel,
      middleLabel: middleLabel,
      isRange: isRange,
      labelAnchor: labelAnchor,
      labelDirection: labelDirection,
      labelPosition: labelPosition,
      labelStyleSpec: labelStyleSpec,
      dashPattern: dashPattern,
      strokeWidth: strokeWidth,
    );
  }

  void updateAnimationPercent(
    _AnnotationElement<D> previous,
    _AnnotationElement<D> target,
    double animationPercent,
  ) {
    final targetAnnotation = target.annotation;
    final previousAnnotation = previous.annotation;

    final startPosition =
        ((targetAnnotation.startPosition - previousAnnotation.startPosition) *
                animationPercent) +
            previousAnnotation.startPosition;

    final endPosition =
        ((targetAnnotation.endPosition - previousAnnotation.endPosition) *
                animationPercent) +
            previousAnnotation.endPosition;

    annotation =
        _DatumAnnotation.from(targetAnnotation, startPosition, endPosition);

    color = getAnimatedColor(previous.color!, target.color!, animationPercent);

    strokeWidth =
        ((target.strokeWidth - previous.strokeWidth) * animationPercent) +
            previous.strokeWidth;
  }
}

enum _AnnotationLabelType {
  start,
  end,
  middle,
}

class _AnimatedAnnotation<D> {
  _AnimatedAnnotation({required this.key});

  final String key;

  _AnnotationElement<D>? _previousAnnotation;
  late _AnnotationElement<D> _targetAnnotation;
  _AnnotationElement<D>? _currentAnnotation;

  // Flag indicating whether this annotation is being animated out of the chart.
  bool animatingOut = false;

  /// Animates an annotation that was removed from the list out of the view.
  ///
  /// This should be called in place of "setNewTarget" for annotations have been
  /// removed from the list.
  /// TODO: Needed?
  void animateOut() {
    final newTarget = _currentAnnotation!.clone();

    setNewTarget(newTarget);
    animatingOut = true;
  }

  void setNewTarget(_AnnotationElement<D> newTarget) {
    animatingOut = false;
    _currentAnnotation ??= newTarget.clone();
    _previousAnnotation = _currentAnnotation!.clone();
    _targetAnnotation = newTarget;
  }

  _AnnotationElement<D> getCurrentAnnotation(double animationPercent) {
    if (animationPercent == 1.0 || _previousAnnotation == null) {
      _currentAnnotation = _targetAnnotation;
      _previousAnnotation = _targetAnnotation;
      return _currentAnnotation!;
    }

    _currentAnnotation!.updateAnimationPercent(
        _previousAnnotation!, _targetAnnotation, animationPercent);

    return _currentAnnotation!;
  }
}

/// Helper class that exposes fewer private internal properties for unit tests.
@visibleForTesting
class RangeAnnotationTester<D> {
  const RangeAnnotationTester(this.behavior);

  final RangeAnnotation<D> behavior;

  void mockLayout(Rect bounds) {}

  /// Checks if an annotation exists with the given position and color.
  bool doesAnnotationExist({
    double? startPosition,
    double? endPosition,
    Color? color,
    List<int>? dashPattern,
    String? startLabel,
    String? endLabel,
    String? middleLabel,
    AnnotationLabelAnchor? labelAnchor,
    AnnotationLabelDirection? labelDirection,
    AnnotationLabelPosition? labelPosition,
  }) {
    for (final a in behavior._annotationMap.values) {
      final currentAnnotation = a._currentAnnotation!;
      final annotation = currentAnnotation.annotation;

      if (annotation.startPosition == startPosition &&
          annotation.endPosition == endPosition &&
          currentAnnotation.color == color &&
          currentAnnotation.startLabel == startLabel &&
          currentAnnotation.endLabel == endLabel &&
          currentAnnotation.middleLabel == middleLabel &&
          currentAnnotation.labelAnchor == labelAnchor &&
          currentAnnotation.labelDirection == labelDirection &&
          currentAnnotation.labelPosition == labelPosition &&
          (currentAnnotation is! LineAnnotationSegment ||
              currentAnnotation.dashPattern == dashPattern)) {
        return true;
      }
    }

    return false;
  }
}

/// Base class for chart annotations.
abstract class AnnotationSegment<D> {
  const AnnotationSegment(
    this.axisType, {
    this.axisId,
    this.color,
    this.startLabel,
    this.endLabel,
    this.middleLabel,
    this.labelAnchor,
    this.labelDirection,
    this.labelPosition,
    this.labelStyleSpec,
  });

  final RangeAnnotationAxisType axisType;
  final String? axisId;
  final Color? color;
  final String? startLabel;
  final String? endLabel;
  final String? middleLabel;
  final AnnotationLabelAnchor? labelAnchor;
  final AnnotationLabelDirection? labelDirection;
  final AnnotationLabelPosition? labelPosition;
  final TextStyle? labelStyleSpec;

  String get key;
}

/// Data for a chart range annotation.
class RangeAnnotationSegment<D> extends AnnotationSegment<D> {
  const RangeAnnotationSegment(
    this.startValue,
    this.endValue,
    super.axisType, {
    super.axisId,
    super.color,
    super.startLabel,
    super.endLabel,
    super.middleLabel,
    super.labelAnchor,
    super.labelDirection,
    super.labelPosition,
    super.labelStyleSpec,
  });

  final D startValue;
  final D endValue;

  @override
  String get key => 'r::$axisType::$axisId::$startValue::$endValue';
}

/// Data for a chart line annotation.
class LineAnnotationSegment<D> extends AnnotationSegment<D> {
  const LineAnnotationSegment(
    this.value,
    RangeAnnotationAxisType axisType, {
    String? axisId,
    Color? color,
    String? startLabel,
    String? endLabel,
    String? middleLabel,
    AnnotationLabelAnchor? labelAnchor,
    AnnotationLabelDirection? labelDirection,
    AnnotationLabelPosition? labelPosition,
    TextStyle? labelStyleSpec,
    this.dashPattern,
    this.strokeWidth = _defaultStrokeWidth,
  }) : super(
          axisType,
          axisId: axisId,
          color: color,
          startLabel: startLabel,
          endLabel: endLabel,
          middleLabel: middleLabel,
          labelAnchor: labelAnchor,
          labelDirection: labelDirection,
          labelPosition: labelPosition,
          labelStyleSpec: labelStyleSpec,
        );

  final D value;
  final List<int>? dashPattern;
  final double strokeWidth;

  @override
  String get key => 'l::$axisType::$axisId::$value';
}

/// Axis type for an annotation.
enum RangeAnnotationAxisType {
  domain,
  measure,
}

/// Configures where to anchor the label.
enum AnnotationLabelAnchor {
  /// Anchor to the starting side of the annotation range.
  start,

  /// Anchor to the middle of the annotation range.
  middle,

  /// Anchor to the ending side of the annotation range.
  end,
}

/// Direction of the label text on the chart.
enum AnnotationLabelDirection {
  /// Automatically assign a direction based on the [RangeAnnotationAxisType].
  ///
  /// [horizontal] for measure axes, or [vertical] for domain axes.
  auto,

  /// Text flows parallel to the x axis.
  horizontal,

  /// Text flows parallel to the y axis.
  /// TODO[b/112553019]: Implement vertical text rendering of labels.
  vertical,
}

/// Configures where to place the label relative to the annotation.
enum AnnotationLabelPosition {
  /// Automatically try to place the label inside the bar first and place it on
  /// the outside of the space available outside the bar is greater than space
  /// available inside the bar.
  auto,

  /// Always place label on the outside.
  outside,

  /// Always place label on the inside.
  inside,

  /// Place the label outside of the draw area, in the chart margin.
  ///
  /// Labels will be rendered on the opposite side of the chart from the primary
  /// axis. For measure annotations, this means the "end" side, opposite from
  /// the "start" side where the primary measure axis is located.
  ///
  /// This should not be used for measure annotations if the chart has a
  /// secondary measure axis. The annotation behaviors do not perform collision
  /// detection with tick labels.
  margin,
}

const String _unresolvedAutoMessage = 'Unresolved AnnotationLabelPosition.auto';
