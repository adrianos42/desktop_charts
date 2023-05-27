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

import 'dart:math' show max, min;
import 'dart:ui' show lerpDouble;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../../../math.dart' show NullablePoint;
import '../../../symbol_renderer.dart'
    show CircleSymbolRenderer, SymbolRenderer;
import '../../base_chart.dart'
    show BaseChartState, LifecycleListener, BaseChart;
import '../../cartesian/cartesian_chart.dart'
    show CartesianChartState, CartesianChart;
import '../../chart_canvas.dart' show ChartCanvas, getAnimatedColor;
import '../../processed_series.dart' show ImmutableSeries;
import '../../selection_model.dart' show SelectionModel, SelectionModelType;
import '../chart_behavior.dart' show ChartBehavior, ChartBehaviorState;

/// Chart behavior that monitors the specified [SelectionModel] and renders a
/// dot for selected data.
///
/// Vertical or horizontal follow lines can optionally be drawn underneath the
/// rendered dots. Follow lines will be drawn in the combined area of the chart
/// draw area, and the draw area for any layout components that provide a
/// series draw area (e.g. [SymbolAnnotationRenderer]).
///
/// This is typically used for line charts to highlight segments.
///
/// It is used in combination with SelectNearest to update the selection model
/// and expand selection out to the domain value.
class LinePointHighlighter<D> extends ChartBehavior<D> {
  const LinePointHighlighter({
    SelectionModelType? selectionModelType,
    double? defaultRadius,
    double? radiusPadding,
    LinePointHighlighterFollowLineType? showHorizontalFollowLine,
    LinePointHighlighterFollowLineType? showVerticalFollowLine,
    List<int>? dashPattern,
    bool? drawFollowLinesAcrossChart,
    SymbolRenderer? symbolRenderer,
  })  : selectionModelType = selectionModelType ?? SelectionModelType.info,
        defaultRadius = defaultRadius ?? 4.0,
        radiusPadding = radiusPadding ?? 2.0,
        showHorizontalFollowLine =
            showHorizontalFollowLine ?? LinePointHighlighterFollowLineType.none,
        showVerticalFollowLine = showVerticalFollowLine ??
            LinePointHighlighterFollowLineType.nearest,
        dashPattern = dashPattern ?? const [1, 3],
        drawFollowLinesAcrossChart = drawFollowLinesAcrossChart ?? true,
        symbolRenderer = symbolRenderer ?? const CircleSymbolRenderer();

  final SelectionModelType selectionModelType;

  /// Default radius of the dots if the series has no radius mapping function.
  ///
  /// When no radius mapping function is provided, this value will be used as
  /// is. [radiusPadding] will not be added to [defaultRadius].
  final double defaultRadius;

  /// Additional radius value added to the radius of the selected data.
  ///
  /// This value is only used when the series has a radius mapping function
  /// defined.
  final double radiusPadding;

  /// Whether or not to draw horizontal follow lines through the selected
  /// points.
  ///
  /// Defaults to drawing no horizontal follow lines.
  final LinePointHighlighterFollowLineType showHorizontalFollowLine;

  /// Whether or not to draw vertical follow lines through the selected points.
  ///
  /// Defaults to drawing a vertical follow line only for the nearest datum.
  final LinePointHighlighterFollowLineType showVerticalFollowLine;

  /// The dash pattern to be used for drawing the line.
  ///
  /// To disable dash pattern (to draw a solid line), pass in an empty list.
  /// This is because if dashPattern is null or not set, it defaults to [1,3].
  final List<int>? dashPattern;

  /// Whether or not follow lines should be drawn across the entire chart draw
  /// area, or just from the axis to the point.
  ///
  /// When disabled, measure follow lines will be drawn from the primary measure
  /// axis to the point. In RTL mode, this means from the right-hand axis. In
  /// LTR mode, from the left-hand axis.
  final bool drawFollowLinesAcrossChart;

  /// Renderer used to draw the highlighted points.
  final SymbolRenderer symbolRenderer;

  // Map<String, _AnimatedPoint<D>> get _seriesPointMap =>
  //     (_linePointKey.currentContext!.findRenderObject()!
  //             as _LinePointRender<D>)
  //         ._seriesPointMap;

  @override
  String get role => 'LinePointHighlighter-$selectionModelType';

  @override
  ChartBehaviorState<D, S, LinePointHighlighter<D>>
      build<S extends BaseChart<D>>({
    required BaseChartState<D, S> chartState,
  }) {
    return _LinePointHighlighterState<D, S>(
      behavior: this,
      chartState: chartState,
    );
  }
}

class _LinePointHighlighterState<D, S extends BaseChart<D>>
    extends ChartBehaviorState<D, S, LinePointHighlighter<D>> {
  _LinePointHighlighterState({
    required super.behavior,
    required super.chartState,
  });

  final GlobalKey linePointKey = GlobalKey();

  @override
  Widget buildBehaviorWidget(BuildContext context) {
    return _LinePointRenderObjectWidget(
      key: linePointKey,
      chartState: chartState as CartesianChartState<D, CartesianChart<D>>,
      dashPattern: behavior.dashPattern,
      defaultRadius: behavior.defaultRadius,
      drawFollowLinesAcrossChart: behavior.drawFollowLinesAcrossChart,
      radiusPadding: behavior.radiusPadding,
      selectionModelType: behavior.selectionModelType,
      showHorizontalFollowLine: behavior.showHorizontalFollowLine,
      showVerticalFollowLine: behavior.showVerticalFollowLine,
      symbolRenderer: behavior.symbolRenderer,
    );
  }
}

class _LinePointRenderObjectWidget<D, S extends CartesianChart<D>>
    extends LeafRenderObjectWidget {
  const _LinePointRenderObjectWidget({
    required this.dashPattern,
    required this.drawFollowLinesAcrossChart,
    required this.showHorizontalFollowLine,
    required this.showVerticalFollowLine,
    required this.symbolRenderer,
    required this.defaultRadius,
    required this.radiusPadding,
    required this.selectionModelType,
    required this.chartState,
    required super.key,
  });

  final CartesianChartState<D, CartesianChart<D>> chartState;
  final LinePointHighlighterFollowLineType showHorizontalFollowLine;
  final LinePointHighlighterFollowLineType showVerticalFollowLine;
  final SymbolRenderer symbolRenderer;
  final List<int>? dashPattern;
  final bool drawFollowLinesAcrossChart;
  final SelectionModelType selectionModelType;
  final double defaultRadius;
  final double radiusPadding;

  @override
  _LinePointRender<D> createRenderObject(BuildContext context) =>
      _LinePointRender<D>(
        chartState: chartState,
        dashPattern: dashPattern,
        drawFollowLinesAcrossChart: drawFollowLinesAcrossChart,
        showHorizontalFollowLine: showHorizontalFollowLine,
        showVerticalFollowLine: showVerticalFollowLine,
        symbolRenderer: symbolRenderer,
        defaultRadius: defaultRadius,
        radiusPadding: radiusPadding,
        selectionModelType: selectionModelType,
      );

  @override
  void updateRenderObject(
      BuildContext context, _LinePointRender<D> renderObject) {
    renderObject
      ..dashPattern = dashPattern
      ..drawFollowLinesAcrossChart = drawFollowLinesAcrossChart
      ..showHorizontalFollowLine = showHorizontalFollowLine
      ..showVerticalFollowLine = showVerticalFollowLine
      ..symbolRenderer = symbolRenderer
      ..defaultRadius = defaultRadius
      ..radiusPadding = radiusPadding
      ..selectionModelType = selectionModelType;
  }
}

class _LinePointRender<D> extends RenderBox {
  _LinePointRender({
    required this.chartState,
    required LinePointHighlighterFollowLineType showHorizontalFollowLine,
    required LinePointHighlighterFollowLineType showVerticalFollowLine,
    required SymbolRenderer symbolRenderer,
    required List<int>? dashPattern,
    required bool drawFollowLinesAcrossChart,
    required SelectionModelType selectionModelType,
    required double defaultRadius,
    required double radiusPadding,
  })  : _showHorizontalFollowLine = showHorizontalFollowLine,
        _showVerticalFollowLine = showVerticalFollowLine,
        _symbolRenderer = symbolRenderer,
        _dashPattern = dashPattern,
        _drawFollowLinesAcrossChart = drawFollowLinesAcrossChart,
        _selectionModelType = selectionModelType,
        _defaultRadius = defaultRadius,
        _radiusPadding = radiusPadding;

  final CartesianChartState<D, CartesianChart<D>> chartState;
  //behavior.chartState as CartesianChartState<D, CartesianChart<D>>;

  LinePointHighlighterFollowLineType _showHorizontalFollowLine;
  LinePointHighlighterFollowLineType get showHorizontalFollowLine =>
      _showHorizontalFollowLine;
  set showHorizontalFollowLine(LinePointHighlighterFollowLineType value) {
    if (value != _showHorizontalFollowLine) {
      _showHorizontalFollowLine = value;
      _markNeedsUpdate();
    }
  }

  LinePointHighlighterFollowLineType _showVerticalFollowLine;
  LinePointHighlighterFollowLineType get showVerticalFollowLine =>
      _showVerticalFollowLine;
  set showVerticalFollowLine(LinePointHighlighterFollowLineType value) {
    if (value != _showVerticalFollowLine) {
      _showVerticalFollowLine = value;
      _markNeedsUpdate();
    }
  }

  List<int>? _dashPattern;
  List<int>? get dashPattern => _dashPattern;
  set dashPattern(List<int>? value) {
    if (value != _dashPattern) {
      _dashPattern = value;
      _markNeedsUpdate();
    }
  }

  SymbolRenderer _symbolRenderer;
  SymbolRenderer get symbolRenderer => _symbolRenderer;
  set symbolRenderer(SymbolRenderer value) {
    if (value != _symbolRenderer) {
      _symbolRenderer = value;
      _markNeedsUpdate();
    }
  }

  bool _drawFollowLinesAcrossChart;
  bool get drawFollowLinesAcrossChart => _drawFollowLinesAcrossChart;
  set drawFollowLinesAcrossChart(bool value) {
    if (value != _drawFollowLinesAcrossChart) {
      _drawFollowLinesAcrossChart = value;
      _markNeedsUpdate();
    }
  }

  SelectionModelType _selectionModelType;
  SelectionModelType get selectionModelType => _selectionModelType;
  set selectionModelType(SelectionModelType value) {
    if (value != _selectionModelType) {
      _selectionModelType = value;
      _markNeedsUpdate();
    }
  }

  double _defaultRadius;
  double get defaultRadius => _defaultRadius;
  set defaultRadius(double value) {
    if (value != _defaultRadius) {
      _defaultRadius = value;
      _markNeedsUpdate();
    }
  }

  double _radiusPadding;
  double get radiusPadding => _radiusPadding;
  set radiusPadding(double value) {
    if (value != _radiusPadding) {
      _radiusPadding = value;
      _markNeedsUpdate();
    }
  }

  // Store a list of points that exist in the series data.
  //
  // This list will be used to remove any [_AnimatedPoint] that were rendered in
  // previous draw cycles, but no longer have a corresponding datum in the new
  // data.
  final _currentKeys = <String>[];

  /// Store a map of series drawn on the chart, mapped by series name.
  ///
  /// [Map] is used to render the series on the canvas in the same
  /// order as the data was given to the chart.
  Map<String, _AnimatedPoint<D>> _seriesPointMap = {};

  void update() {
    _currentKeys.clear();

    final selectedDatumDetails =
        chartState.getSelectedDatumDetails(selectionModelType);

    // Create a map each time to ensure that we have it sorted in the
    // selection model order. This preserves the "nearestDetail" ordering, so
    // that we render follow lines in the proper place.
    // ignore: prefer_collection_literals
    final newSeriesMap = Map<String, _AnimatedPoint<D>>();

    for (final detail in selectedDatumDetails) {
      final series = detail.series!;
      final Object? datum = detail.datum;

      final domainAxis = chartState.domainAxis;
      final measureAxis = chartState.getMeasureAxis();

      final lineKey = series.id;

      final radius = (detail.radius != null)
          ? detail.radius!.toDouble() + radiusPadding
          : defaultRadius;

      final pointKey = '$lineKey::${detail.domain}::${detail.measure}';

      // If we already have a point for that key, use it.
      _AnimatedPoint<D> animatingPoint;
      if (_seriesPointMap.containsKey(pointKey)) {
        animatingPoint = _seriesPointMap[pointKey]!;
      } else {
        // Create a point and have it animate in from axis.
        final point = _DatumPoint<D>(
          datum: datum,
          domain: detail.domain,
          series: series,
          x: domainAxis!.getLocation(detail.domain),
          y: measureAxis.getLocation(0.0),
        );

        animatingPoint = _AnimatedPoint<D>(
            key: pointKey, overlaySeries: series.overlaySeries)
          ..setNewTarget(
            _PointRendererElement<D>(
              point: point,
              color: detail.color,
              fillColor: detail.fillColor,
              radius: radius,
              measureAxisPosition: measureAxis.getLocation(0.0),
              strokeWidth: detail.strokeWidth,
              symbolRenderer: detail.symbolRenderer,
            ),
          );
      }

      newSeriesMap[pointKey] = animatingPoint;

      // Create a line using the final point locations.
      final point = _DatumPoint<D>(
        datum: datum,
        domain: detail.domain,
        series: series,
        x: detail.chartPosition!.dx,
        y: detail.chartPosition!.dy,
      );

      // Update the set of points that still exist in the series data.
      _currentKeys.add(pointKey);

      // Get the point element we are going to setup.
      final pointElement = _PointRendererElement<D>(
        point: point,
        color: detail.color,
        fillColor: detail.fillColor,
        radius: radius,
        measureAxisPosition: measureAxis.getLocation(0.0),
        strokeWidth: detail.strokeWidth,
        symbolRenderer: detail.symbolRenderer,
      );

      animatingPoint.setNewTarget(pointElement);
    }

    // Animate out points that don't exist anymore.
    _seriesPointMap.forEach((String key, _AnimatedPoint<D> point) {
      if (_currentKeys.contains(point.key) != true) {
        point.animateOut();
        newSeriesMap[point.key] = point;
      }
    });

    _seriesPointMap = newSeriesMap;
  }

  late LifecycleListener<D> _lifecycleListener;

  void _selectionChanged(SelectionModel<D> selectionModel) {
    chartState.redraw(skipAnimation: true);
  }

  bool _needsUpdate = true;
  void _markNeedsUpdate() {
    _needsUpdate = true;
    markNeedsPaint();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);

    chartState
        .getSelectionModel(selectionModelType)
        .addSelectionChangedListener(_selectionChanged);

    chartState.animationPosition.addListener(markNeedsPaint);

    _lifecycleListener = LifecycleListener<D>(onAxisConfigured: () {
      _markNeedsUpdate();
    });

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

    context.canvas
      ..save()
      ..clipRect((offset & size).inflate(20.0));

    final animationPercent = chartState.animationPosition.value;

    // Clean up the lines that no longer exist.
    if (animationPercent == 1.0) {
      final keysToRemove = <String>[];

      _seriesPointMap.forEach((String key, _AnimatedPoint<D> point) {
        if (point.animatingOut) {
          keysToRemove.add(key);
        }
      });

      keysToRemove.forEach(_seriesPointMap.remove);
    }

    final points = <_PointRendererElement<D>>[];
    _seriesPointMap.forEach((String key, _AnimatedPoint<D> point) {
      points.add(point.getCurrentPoint(animationPercent));
    });

    // Build maps of the position where the follow lines should stop for each
    // selected data point.
    final endPointPerValueVertical = <int, int>{};
    final endPointPerValueHorizontal = <int, int>{};

    for (final pointElement in points) {
      if (pointElement.point.dx == null || pointElement.point.dy == null) {
        continue;
      }
      final point = pointElement.point.toPoint();

      final roundedX = point.dx.round();
      final roundedY = point.dy.round();

      // Get the Y value closest to the top of the chart for this X position.
      if (endPointPerValueVertical[roundedX] == null) {
        endPointPerValueVertical[roundedX] = roundedY;
      } else {
        // In the nearest case, we rely on the selected data always starting
        // with the nearest point. In this case, we don't care about the rest of
        // the selected data positions.
        if (showVerticalFollowLine !=
            LinePointHighlighterFollowLineType.nearest) {
          endPointPerValueVertical[roundedX] =
              min(endPointPerValueVertical[roundedX]!, roundedY);
        }
      }

      // Get the X value closest to the "end" side of the chart for this Y
      // position.
      if (endPointPerValueHorizontal[roundedY] == null) {
        endPointPerValueHorizontal[roundedY] = roundedX;
      } else {
        // In the nearest case, we rely on the selected data always starting
        // with the nearest point. In this case, we don't care about the rest of
        // the selected data positions.
        if (showHorizontalFollowLine !=
            LinePointHighlighterFollowLineType.nearest) {
          endPointPerValueHorizontal[roundedY] =
              max(endPointPerValueHorizontal[roundedY]!, roundedX);
        }
      }
    }

    bool shouldShowHorizontalFollowLine = showHorizontalFollowLine ==
            LinePointHighlighterFollowLineType.all ||
        showHorizontalFollowLine == LinePointHighlighterFollowLineType.nearest;

    bool shouldShowVerticalFollowLine = showVerticalFollowLine ==
            LinePointHighlighterFollowLineType.all ||
        showVerticalFollowLine == LinePointHighlighterFollowLineType.nearest;

    // Keep track of points for which we've already drawn lines.
    final paintedHorizontalLinePositions = <double>[];
    final paintedVerticalLinePositions = <double>[];

    final drawBounds = Offset.zero & size;

    final rtl = chartState.isRTL;

    // Draw the follow lines first, below all of the highlight shapes.
    for (final pointElement in points) {
      if (pointElement.point.dx == null || pointElement.point.dy == null) {
        continue;
      }
      final point = pointElement.point.toPoint();

      final roundedX = point.dx.roundToDouble();
      final roundedY = point.dy.roundToDouble();

      // Draw the horizontal follow line.
      if (shouldShowHorizontalFollowLine &&
          !paintedHorizontalLinePositions.contains(roundedY)) {
        double leftBound;
        double rightBound;

        if (drawFollowLinesAcrossChart) {
          // RTL and LTR both go across the whole draw area.
          leftBound = drawBounds.left;
          rightBound = drawBounds.left + drawBounds.width;
        } else {
          final x = endPointPerValueHorizontal[roundedY]!.roundToDouble();

          // RTL goes from the point to the right edge. LTR goes from the left
          // edge to the point.
          leftBound = rtl ? x : drawBounds.left;
          rightBound = rtl ? drawBounds.left + drawBounds.width : x;
        }

        context.canvas.drawChartLine(
          offset,
          points: [
            Offset(leftBound, point.dy),
            Offset(rightBound, point.dy),
          ],
          stroke: chartState.themeData.linePointHighlighterColor,
          strokeWidth: 1.0,
          dashPattern: dashPattern,
        );

        if (showHorizontalFollowLine ==
            LinePointHighlighterFollowLineType.nearest) {
          shouldShowHorizontalFollowLine = false;
        }

        paintedHorizontalLinePositions.add(roundedY);
      }

      // Draw the vertical follow line.
      if (shouldShowVerticalFollowLine &&
          !paintedVerticalLinePositions.contains(roundedX)) {
        final topBound = drawFollowLinesAcrossChart
            ? drawBounds.top
            : endPointPerValueVertical[roundedX]!.roundToDouble();

        context.canvas.drawChartLine(
          offset,
          points: [
            Offset(point.dx, topBound),
            Offset(point.dx, drawBounds.top + drawBounds.height),
          ],
          stroke: chartState.themeData.linePointHighlighterColor,
          strokeWidth: 1.0,
          dashPattern: dashPattern,
        );

        if (showVerticalFollowLine ==
            LinePointHighlighterFollowLineType.nearest) {
          shouldShowVerticalFollowLine = false;
        }

        paintedVerticalLinePositions.add(roundedX);
      }

      if (!shouldShowHorizontalFollowLine && !shouldShowVerticalFollowLine) {
        break;
      }
    }

    // Draw the highlight shapes on top of all follow lines.
    for (final pointElement in points) {
      if (pointElement.point.dx == null || pointElement.point.dy == null) {
        continue;
      }
      final point = pointElement.point.toPoint();

      final bounds = Rect.fromLTWH(
        point.dx - pointElement.radius,
        point.dy - pointElement.radius,
        pointElement.radius * 2.0,
        pointElement.radius * 2.0,
      );

      // Draw the highlight dot. Use the [SymbolRenderer] from the datum if one
      // is defined.
      (pointElement.symbolRenderer ?? symbolRenderer).draw(
        context.canvas,
        offset,
        bounds,
        fillColor: pointElement.fillColor,
        strokeColor: pointElement.color,
        strokeWidth: pointElement.strokeWidth,
      );
    }

    context.canvas.restore();
  }
}

@immutable
class _DatumPoint<D> extends NullablePoint {
  const _DatumPoint({
    this.datum,
    this.domain,
    this.series,
    double? x,
    double? y,
  }) : super(x, y);

  factory _DatumPoint.from(_DatumPoint<D> other, [double? x, double? y]) {
    return _DatumPoint<D>(
      datum: other.datum,
      domain: other.domain,
      series: other.series,
      x: x ?? other.dx,
      y: y ?? other.dy,
    );
  }

  final dynamic datum;
  final D? domain;
  final ImmutableSeries<D>? series;
}

class _PointRendererElement<D> {
  _PointRendererElement({
    required this.point,
    required this.color,
    required this.fillColor,
    required this.radius,
    required this.measureAxisPosition,
    required this.strokeWidth,
    required this.symbolRenderer,
  });

  _PointRendererElement<D> clone() {
    return _PointRendererElement<D>(
      point: point,
      color: color,
      fillColor: fillColor,
      measureAxisPosition: measureAxisPosition,
      radius: radius,
      strokeWidth: strokeWidth,
      symbolRenderer: symbolRenderer,
    );
  }

  _DatumPoint<D> point;
  Color? color;
  Color? fillColor;
  double radius;
  double? measureAxisPosition;
  double? strokeWidth;
  SymbolRenderer? symbolRenderer;

  void updateAnimationPercent(_PointRendererElement<D> previous,
      _PointRendererElement<D> target, double animationPercent) {
    final targetPoint = target.point;
    final previousPoint = previous.point;

    final x = lerpDouble(previousPoint.dx, targetPoint.dx, animationPercent);

    final y = lerpDouble(previousPoint.dy, targetPoint.dy, animationPercent);

    point = _DatumPoint<D>.from(targetPoint, x, y);

    color = getAnimatedColor(previous.color!, target.color!, animationPercent);

    fillColor = getAnimatedColor(
      previous.fillColor!,
      target.fillColor!,
      animationPercent,
    );

    radius = lerpDouble(previous.radius, target.radius, animationPercent)!;

    final targetStrokeWidth = target.strokeWidth;
    final previousStrokeWidth = previous.strokeWidth;
    if (targetStrokeWidth != null && previousStrokeWidth != null) {
      strokeWidth =
          ((targetStrokeWidth - previousStrokeWidth) * animationPercent) +
              previousStrokeWidth;
    } else {
      strokeWidth = null;
    }
  }
}

class _AnimatedPoint<D> {
  _AnimatedPoint({
    required this.key,
    required this.overlaySeries,
  });

  final String key;
  final bool overlaySeries;

  _PointRendererElement<D>? _previousPoint;
  late _PointRendererElement<D> _targetPoint;
  _PointRendererElement<D>? _currentPoint;

  // Flag indicating whether this point is being animated out of the chart.
  bool animatingOut = false;

  /// Animates a point that was removed from the series out of the view.
  ///
  /// This should be called in place of "setNewTarget" for points that represent
  /// data that has been removed from the series.
  ///
  /// Animates the height of the point down to the measure axis position
  /// (position of 0).
  void animateOut() {
    final newTarget = _currentPoint!.clone();

    // Set the target measure value to the axis position for all points.
    final targetPoint = newTarget.point;

    final newPoint = _DatumPoint<D>.from(targetPoint, targetPoint.dx,
        newTarget.measureAxisPosition!.roundToDouble());

    newTarget.point = newPoint;

    // Animate the radius to 0 so that we don't get a lingering point after
    // animation is done.
    newTarget.radius = 0.0;

    setNewTarget(newTarget);
    animatingOut = true;
  }

  void setNewTarget(_PointRendererElement<D> newTarget) {
    animatingOut = false;
    _currentPoint ??= newTarget.clone();
    _previousPoint = _currentPoint!.clone();
    _targetPoint = newTarget;
  }

  _PointRendererElement<D> getCurrentPoint(double animationPercent) {
    if (animationPercent == 1.0 || _previousPoint == null) {
      _currentPoint = _targetPoint;
      _previousPoint = _targetPoint;
      return _currentPoint!;
    }

    _currentPoint!.updateAnimationPercent(
        _previousPoint!, _targetPoint, animationPercent);

    return _currentPoint!;
  }
}

/// Type of follow line(s) to draw.
enum LinePointHighlighterFollowLineType {
  /// Draw a follow line for only the nearest point in the selection.
  nearest,

  /// Draw no follow lines.
  none,

  /// Draw a follow line for every point in the selection.
  all,
}

/// Helper class that exposes fewer private internal properties for unit tests.
@visibleForTesting
class LinePointHighlighterTester<D> {
  const LinePointHighlighterTester(this.behavior);

  final LinePointHighlighter<D> behavior;

  //int getSelectionLength() => behavior._seriesPointMap.length;

  //bool isDatumSelected(D datum) => behavior._seriesPointMap.values
  //    .any((point) => point._currentPoint!.point.datum == datum);
}
