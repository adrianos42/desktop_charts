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

import 'dart:math' show Point;

import 'package:collection/collection.dart' show IterableExtension;
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../../data/series.dart' show AttributeKey, Accessor;
import '../../math.dart';
import '../base_chart.dart' show BaseChart;
import '../cartesian/axis/axis.dart'
    show ImmutableAxis, OrdinalAxis, measureAxisIdKey;
import '../cartesian/cartesian_renderer.dart' show BaseCartesianRenderer;
import '../chart_canvas.dart' show ChartCanvas, getAnimatedColor;
import '../datum_details.dart' show DatumDetails;
import '../processed_series.dart' show ImmutableSeries, MutableSeries;
import '../series_datum.dart' show SeriesDatum;
import 'line_renderer_config.dart' show LineRendererConfig;
import '../cartesian/cartesian_chart.dart'
    show CartesianChartState, CartesianChart;

const styleSegmentsKey = AttributeKey<List<_LineRendererElement<Object>>>(
    'LineRenderer.styleSegments');

const lineStackIndexKey = AttributeKey<int>('LineRenderer.lineStackIndex');

class LineRenderer<D, S extends BaseChart<D>>
    extends BaseCartesianRenderer<D, S> {
  LineRenderer({
    String? rendererId,
    required this.config,
    required super.chartState,
    required super.seriesList,
  }) : super(
          rendererId: rendererId ?? 'line',
          layoutPaintOrder: config.layoutPaintOrder,
          symbolRenderer: config.symbolRenderer,
        );

  final LineRendererConfig<D> config;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);

    // _pointRenderer = PointRenderer<D, S>(
    //   config: PointRendererConfig(
    //     radius: config.radius,
    //   ),
    // );
  }

  // Configuration used to extend the clipping area to extend the draw bounds.
  static const drawBoundTopExtension = 5.0;
  static const drawBoundBottomExtension = 5.0;

  /// True if any series has a measureUpperBoundFn and measureLowerBoundFn.
  ///
  /// Used to enable drawing confidence interval areas segments.
  late bool _hasMeasureBounds;

  /// Store a map of series drawn on the chart, mapped by series name.
  ///
  /// [Map] is used to render the series on the canvas in the same
  /// order as the data was given to the chart.
  final _seriesLineMap = <String, List<_AnimatedElements<D>>>{};

  // Store a list of lines that exist in the series data.
  //
  // This list will be used to remove any [_AnimatedLine] that were rendered in
  // previous draw cycles, but no longer have a corresponding datum in the new
  // data.
  final _currentKeys = <String>[];

  @override
  void configureSeries() {
    assignMissingColors(seriesList, emptyCategoryUsesSinglePalette: false);

    for (final series in seriesList) {
      // Add a default area color function which applies the configured
      // areaOpacity value to the datum's current color.
      series.areaColorFn ??= (int? index) {
        final color = series.colorFn?.call(index);
        if (color == null) {
          return null;
        }

        return Color.fromARGB(
          (color.alpha * config.areaOpacity).round(),
          color.red,
          color.green,
          color.blue,
        );
      };
    }
  }

  @override
  void preprocessSeries() {
    int stackIndex = 0;

    _hasMeasureBounds = seriesList.any((series) =>
        series.measureUpperBoundFn != null &&
        series.measureLowerBoundFn != null);

    for (final series in seriesList) {
      final colorFn = series.colorFn;
      final areaColorFn = series.areaColorFn;
      final domainFn = series.domainFn;
      final measureFn = series.measureFn;
      final strokeWidthFn = series.strokeWidthFn;

      series.dashPatternFn ??= (_) => config.dashPattern;
      final dashPatternFn = series.dashPatternFn!;

      final styleSegments = <_LineRendererElement<D>>[];
      int styleSegmentsIndex = 0;

      final usedKeys = <String>{};

      // Configure style segments for each series.
      String? previousSegmentKey;
      _LineRendererElement<D>? currentDetails;

      for (int index = 0; index < series.data.length; index += 1) {
        final domain = domainFn(index);
        final measure = measureFn(index);

        if (domain == null || measure == null) {
          continue;
        }

        final color = colorFn!(index);
        final areaColor = areaColorFn!(index);
        final dashPattern = dashPatternFn(index);
        final strokeWidth =
            strokeWidthFn?.call(index)?.toDouble() ?? config.strokeWidth;

        // Create a style key for this datum, and then compare it to the
        // previous datum.
        //
        // Compare strokeWidth to 2 decimals of precision. Any less and you
        // can't see any difference in the canvas anyways.
        final strokeWidthRounded = (strokeWidth * 100).round() / 100;
        String styleKey = '${series.id}__${styleSegmentsIndex}__$color'
            '__${dashPattern}__$strokeWidthRounded';

        if (styleKey != previousSegmentKey) {
          // If we have a repeated style segment, update the repeat index and
          // create a key.
          // TODO: Paint repeated styles with multiple clip regions.
          if (usedKeys.isNotEmpty && usedKeys.contains(styleKey)) {
            styleSegmentsIndex += 1;

            styleKey = '${series.id}__${styleSegmentsIndex}__$color'
                '__${dashPattern}__$strokeWidthRounded';
          }

          // Make sure that the previous style segment extends to the current
          // domain value. This will ensure that the style of the line changes
          // right at the point of the datum that changes the style.
          if (currentDetails != null) {
            currentDetails.domainExtent.includePoint(domain);
          }

          // Create a style segment.
          currentDetails = _LineRendererElement<D>(
            color: color,
            areaColor: areaColor,
            dashPattern: dashPattern,
            domainExtent: _Range<D>(domain, domain),
            strokeWidth: strokeWidth,
            styleKey: styleKey,
            roundEndCaps: config.roundEndCaps,
          );

          styleSegments.add(currentDetails);
          usedKeys.add(styleKey);

          previousSegmentKey = styleKey;
        } else {
          // Extend the range of the current segment to include the current
          // domain value.
          currentDetails!.domainExtent.includePoint(domain);
        }
      }

      series.setAttr(styleSegmentsKey, styleSegments);
      series.setAttr(lineStackIndexKey, stackIndex);

      if (config.stacked) {
        stackIndex += 1;
      }
    }

    // If we are stacking, generate stacking measure offset functions for
    // each series. Each datum should have a measure offset consisting of the
    // sum of the measure and measure offsets of each datum with the same domain
    // value in series below it in the stack. The first series will be treated
    // as the bottom of the stack.
    if (config.stacked && seriesList.isNotEmpty) {
      var curOffsets = _createInitialOffsetMap(seriesList[0]);
      var nextOffsets = <D, num>{};

      for (int i = 0; i < seriesList.length; i += 1) {
        final series = seriesList[i];
        final measureOffsetFn = _createStackedMeasureOffsetFunction(
          series,
          curOffsets,
          nextOffsets,
        );

        if (i > 0) {
          series.measureOffsetFn = measureOffsetFn;
        }

        curOffsets = nextOffsets;
        nextOffsets = <D, num>{};
      }
    }
  }

  /// Creates the initial offsets for the series given the measureOffset values.
  Map<D, num?> _createInitialOffsetMap(MutableSeries<D> series) {
    final domainFn = series.domainFn;
    final measureOffsetFn = series.measureOffsetFn!;
    final initialOffsets = <D, num?>{};

    for (int index = 0; index < series.data.length; index += 1) {
      initialOffsets[domainFn(index)] = measureOffsetFn(index);
    }

    return initialOffsets;
  }

  /// Function needed to create a closure preserving the previous series
  /// information. y0 for this series is just y + y0 for previous series as long
  /// as both y and y0 are not null. If they are null propagate up the
  /// missing/null data.
  Accessor<num?> _createStackedMeasureOffsetFunction(MutableSeries<D> series,
      Map<D, num?> curOffsets, Map<D, num> nextOffsets) {
    final domainFn = series.domainFn;
    final measureFn = series.measureFn;

    for (int index = 0; index < series.data.length; index += 1) {
      final domainValue = domainFn(index);
      final measure = measureFn(index);
      final prevOffset = curOffsets[domainValue];

      if (measure != null && prevOffset != null) {
        nextOffsets[domainValue] = measure + prevOffset;
      }
    }

    return (int? i) => curOffsets[domainFn(i)];
  }

  /// Merge the line map and the series so that the elements are mixed
  /// with the previous ones.
  ///
  /// This is to deal with the issue that every series added after the fact
  /// would be be rendered on top of the old ones, no matter the order of the
  /// series list.
  void _mergeIntoSeriesMap(List<ImmutableSeries<D>> seriesList) {
    final newLineMap = <MapEntry<String, List<_AnimatedElements<D>>>>[];

    for (final series in seriesList) {
      final key = series.id;

      // First, add all the series from the old map that have been removed from
      // the seriesList in the same order they appear, stopping at the first
      // series that is still in the list. We need to maintain them in the same
      // order animate them out smoothly.
      bool checkNext = true;
      while (checkNext && _seriesLineMap.isNotEmpty) {
        final firstKey = _seriesLineMap.keys.first;
        if (!seriesList.any((s) => s.id == firstKey)) {
          newLineMap.add(MapEntry(firstKey, _seriesLineMap.remove(firstKey)!));
          checkNext = true;
        } else {
          checkNext = false;
        }
      }

      // If it's a key, we add it and move to the next one. If not, we
      // remove it from the current list and add it to the one.
      if (!_seriesLineMap.containsKey(key)) {
        newLineMap.add(MapEntry(key, []));
      } else {
        newLineMap.add(MapEntry(key, _seriesLineMap.remove(key)!));
      }
    }

    // Now whatever is left is stuff that has been removed. We still add it to
    // the end and removed them as the map is modified in place.
    newLineMap.addAll(_seriesLineMap.entries);
    _seriesLineMap.clear();

    _seriesLineMap.addEntries(newLineMap);
  }

  @override
  void update(Offset offset) {
    super.update(offset);

    final bounds = offset & size;

    _currentKeys.clear();

    // List of final points for the previous line in a stack.
    final previousPointList = <List<_DatumPoint<D>>>[];

    // List of initial points for the previous line in a stack, animated in from
    // the measure axis.
    final previousInitialPointList = <List<_DatumPoint<D>>>[];

    _mergeIntoSeriesMap(seriesList);

    for (final series in seriesList) {
      final domainAxis =
          (chartState as CartesianChartState<D, CartesianChart<D>>).domainAxis;
      final lineKey = series.id;
      final stackIndex = series.getAttr(lineStackIndexKey)!;

      previousPointList.add([]);
      previousInitialPointList.add([]);

      final elementsList = _seriesLineMap[lineKey]!;

      final styleSegments = series.getAttr(styleSegmentsKey)!;

      // Include the end points of the domain axis range in the first and last
      // style segments to avoid clipping everything when the domain range of
      // the data is very small. Doing this after [preProcess] handles invalid
      // data (e.g. null measure) at the ends of the series data.
      //
      // TODO: Handle ordinal axes by looking at the next domains.
      if (styleSegments.isNotEmpty && domainAxis is! OrdinalAxis) {
        final drawBounds = bounds;
        final start =
            (chartState.isRTL ? drawBounds.right : drawBounds.left).toDouble();
        final end =
            (chartState.isRTL ? drawBounds.left : drawBounds.right).toDouble();

        final startDomain = domainAxis!.getDomain(start);
        final endDomain = domainAxis.getDomain(end);

        styleSegments.first.domainExtent.includePoint(startDomain);
        styleSegments.last.domainExtent.includePoint(endDomain);
      }

      // Create a set of animated line and area elements for each style segment.
      //
      // If the series contains null measure values, then multiple animated line
      // and area objects will be created to represent the isolated sections of
      // the series.
      //
      // The full set of line and area elements will be rendered on the canvas
      // for each style segment, with a clip region added in the [paint] process
      // later to display only the relevant parts of data. This ensures that
      // styles that visually depend on the start location, such as dash
      // patterns, are not disrupted by other changes in style.
      for (final styleSegment in styleSegments) {
        final styleKey = styleSegment.styleKey;

        // If we already have an AnimatingPoint for that index, use it.
        _AnimatedElements<D>? animatingElements = elementsList
            .firstWhereOrNull((elements) => elements.styleKey == styleKey);

        if (animatingElements != null) {
          previousInitialPointList[stackIndex] = animatingElements.allPoints;
        } else {
          // Create a line and have it animate in from axis.
          final lineAndArea = _createLineAndAreaElements(
            series,
            styleSegment as _LineRendererElement<D>,
            stackIndex > 0 ? previousInitialPointList[stackIndex - 1] : null,
            true,
            offset,
          );
          final lineElementList =
              lineAndArea[0] as List<_LineRendererElement<D>>;
          final areaElementList =
              lineAndArea[1] as List<_AreaRendererElement<D>>;
          final allPointList = lineAndArea[2] as List<_DatumPoint<D>>;
          final boundsElementList =
              lineAndArea[3] as List<_AreaRendererElement<D>>;

          // Create the line elements.
          final animatingLines = <_AnimatedLine<D>>[];

          for (int index = 0; index < lineElementList.length; index += 1) {
            animatingLines.add(_AnimatedLine<D>(
                key: lineElementList[index].styleKey,
                overlaySeries: series.overlaySeries)
              ..setNewTarget(lineElementList[index]));
          }

          // Create the area elements.
          List<_AnimatedArea<D>>? animatingAreas;
          if (config.includeArea) {
            animatingAreas = <_AnimatedArea<D>>[];

            for (int index = 0; index < areaElementList.length; index += 1) {
              animatingAreas.add(_AnimatedArea<D>(
                  key: areaElementList[index].styleKey,
                  overlaySeries: series.overlaySeries)
                ..setNewTarget(areaElementList[index]));
            }
          }

          // Create the bound elements separately from area elements, because
          // it needs to be rendered on top of the area elements.
          List<_AnimatedArea<D>>? animatingBounds;
          if (_hasMeasureBounds) {
            animatingBounds ??= <_AnimatedArea<D>>[];

            for (int index = 0; index < boundsElementList.length; index += 1) {
              animatingBounds.add(_AnimatedArea<D>(
                  key: boundsElementList[index].styleKey,
                  overlaySeries: series.overlaySeries)
                ..setNewTarget(boundsElementList[index]));
            }
          }

          animatingElements = _AnimatedElements<D>(
            styleKey: styleSegment.styleKey,
            allPoints: allPointList,
            lines: animatingLines,
            areas: animatingAreas,
            bounds: animatingBounds,
          );

          elementsList.add(animatingElements);

          previousInitialPointList[stackIndex] = allPointList;
        }

        // Create a line using the final point locations.
        final lineAndArea = _createLineAndAreaElements(
          series,
          styleSegment as _LineRendererElement<D>,
          stackIndex > 0 ? previousPointList[stackIndex - 1] : null,
          false,
          offset,
        );
        final lineElementList = lineAndArea[0] as List<_LineRendererElement<D>>;
        final areaElementList = lineAndArea[1] as List<_AreaRendererElement<D>>;
        final allPointList = lineAndArea[2] as List<_DatumPoint<D>>;
        final boundsElementList =
            lineAndArea[3] as List<_AreaRendererElement<D>>;

        for (int index = 0; index < lineElementList.length; index += 1) {
          final lineElement = lineElementList[index];

          // Add a animated line if we have more segments in this draw cycle
          // than we did in the previous chart draw cycle.
          // TODO: Nicer animations for incoming segments.
          if (index >= animatingElements.lines.length) {
            animatingElements.lines.add(_AnimatedLine<D>(
                key: lineElement.styleKey,
                overlaySeries: series.overlaySeries));
          }
          animatingElements.lines[index].setNewTarget(lineElement);
        }

        if (config.includeArea) {
          for (int index = 0; index < areaElementList.length; index += 1) {
            final areaElement = areaElementList[index];

            // Add a animated area if we have more segments in this draw
            // cycle than we did in the previous chart draw cycle.
            // TODO: Nicer animations for incoming segments.
            if (index >= animatingElements.areas!.length) {
              animatingElements.areas!.add(_AnimatedArea<D>(
                  key: areaElement.styleKey,
                  overlaySeries: series.overlaySeries));
            }
            animatingElements.areas![index].setNewTarget(areaElement);
          }
        }

        if (_hasMeasureBounds) {
          for (int index = 0; index < boundsElementList.length; index += 1) {
            final boundElement = boundsElementList[index];

            // Add a animated bound if we have more segments in this draw
            // cycle than we did in the previous chart draw cycle.
            // TODO: Nicer animations for incoming segments.
            if (index >= animatingElements.bounds!.length) {
              animatingElements.bounds!.add(_AnimatedArea<D>(
                  key: boundElement.styleKey,
                  overlaySeries: series.overlaySeries));
            }
            animatingElements.bounds![index].setNewTarget(boundElement);
          }
        }

        animatingElements.allPoints = allPointList;

        // Save the line points for the current series so that we can use them
        // in the area skirt for the next stacked series.
        previousPointList[stackIndex] = allPointList;
      }
    }

    // Animate out lines that don't exist anymore.
    _seriesLineMap.forEach((String key, List<_AnimatedElements<D>> elements) {
      for (final element in elements) {
        for (final line in element.lines) {
          if (!_currentKeys.contains(line.key)) {
            line.animateOut();
          }
        }

        if (element.areas != null) {
          for (final area in element.areas!) {
            if (!_currentKeys.contains(area.key)) {
              area.animateOut();
            }
          }
        }

        if (element.bounds != null) {
          for (final bound in element.bounds!) {
            if (!_currentKeys.contains(bound.key)) {
              bound.animateOut();
            }
          }
        }
      }
    });
  }

  /// Creates a tuple of lists of [_LineRendererElement]s,
  /// [_AreaRendererElement]s, [_DatumPoint]s for a given style segment of a
  /// series.
  ///
  /// The first element in the returned array is a list of line elements, broken
  /// apart by null data.
  ///
  /// The second element in the returned array is a list of area elements,
  /// broken apart by null data.
  ///
  /// The third element in the returned array is a list of all of the points for
  /// the entire series. This is intended to be used as the [previousPointList]
  /// for the next series.
  ///
  /// [series] the series that this line represents.
  ///
  /// [styleSegment] represents the rendering style for a subset of the series
  /// data, bounded by its domainExtent.
  ///
  /// [previousPointList] contains the points for the line below this series in
  /// the stack, if stacking is enabled. It forms the bottom edges for the area
  /// skirt.
  ///
  /// [initializeFromZero] controls whether we generate elements with measure
  /// values of 0, or using series data. This should be true when calculating
  /// point positions to animate in from the measure axis.
  List<Object> _createLineAndAreaElements(
    ImmutableSeries<D> series,
    _LineRendererElement<D> styleSegment,
    List<_DatumPoint<D>>? previousPointList,
    bool initializeFromZero,
    Offset offset,
  ) {
    final measureAxis =
        (chartState as CartesianChartState<D, CartesianChart<D>>)
            .getMeasureAxis(axisId: series.getAttr(measureAxisIdKey));

    final color = styleSegment.color;
    final areaColor = styleSegment.areaColor;
    final dashPattern = styleSegment.dashPattern;
    final domainExtent = styleSegment.domainExtent;
    final strokeWidth = styleSegment.strokeWidth;
    final styleKey = styleSegment.styleKey;
    final roundEndCaps = styleSegment.roundEndCaps;

    // Get a list of all positioned points for this series.
    final pointList = _createPointListForSeries(series, initializeFromZero);

    // Break pointList up into sets of line and area segments, divided by null
    // measure values in the series data.
    final segmentsList = _createLineAndAreaSegmentsForSeries(
        pointList, previousPointList, series, initializeFromZero);
    final lineSegments = segmentsList[0];
    final areaSegments = segmentsList[1];
    final boundsSegment = segmentsList[2];

    _currentKeys.add(styleKey);

    final positionExtent = _createPositionExtent(series, styleSegment, offset);

    // Get the line elements we are going to to set up.
    final lineElements = <_LineRendererElement<D>>[];
    for (int index = 0; index < lineSegments.length; index += 1) {
      final linePointList = lineSegments[index];

      // Update the set of areas that still exist in the series data.
      final lineStyleKey = '${styleKey}__line__$index';
      _currentKeys.add(lineStyleKey);

      lineElements.add(_LineRendererElement<D>(
        points: linePointList,
        color: color,
        areaColor: areaColor,
        dashPattern: dashPattern,
        domainExtent: domainExtent,
        measureAxisPosition: measureAxis.getLocation(0.0),
        positionExtent: positionExtent,
        strokeWidth: strokeWidth,
        styleKey: lineStyleKey,
        roundEndCaps: roundEndCaps,
      ));
    }

    // Get the area elements we are going to set up.
    final areaElements = <_AreaRendererElement<D>>[];
    if (config.includeArea) {
      for (int index = 0; index < areaSegments.length; index += 1) {
        final areaPointList = areaSegments[index];

        // Update the set of areas that still exist in the series data.
        final areaStyleKey = '${styleKey}__area_$index';
        _currentKeys.add(areaStyleKey);

        areaElements.add(_AreaRendererElement<D>(
          points: areaPointList,
          color: color,
          areaColor: areaColor,
          domainExtent: domainExtent,
          measureAxisPosition: measureAxis.getLocation(0.0)!,
          positionExtent: positionExtent,
          styleKey: areaStyleKey,
        ));
      }
    }

    // Create the bounds element
    final boundsElements = <_AreaRendererElement<D>>[];
    if (_hasMeasureBounds) {
      // Update the set of bounds that still exist in the series data.
      for (int index = 0; index < boundsSegment.length; index += 1) {
        final boundsPointList = boundsSegment[index];

        final boundsStyleKey = '${styleKey}__bounds_$index';
        _currentKeys.add(boundsStyleKey);

        boundsElements.add(_AreaRendererElement<D>(
          points: boundsPointList,
          color: color,
          areaColor: areaColor,
          domainExtent: domainExtent,
          measureAxisPosition: measureAxis.getLocation(0.0)!,
          positionExtent: positionExtent,
          styleKey: boundsStyleKey,
        ));
      }
    }

    return [lineElements, areaElements, pointList, boundsElements];
  }

  /// Builds a list of data points for the entire series.
  ///
  /// [series] the series that this line represents.
  ///
  /// [initializeFromZero] controls whether we generate elements with measure
  /// values of 0, or using series data. This should be true when calculating
  /// point positions to animate in from the measure axis.
  List<_DatumPoint<D>> _createPointListForSeries(
    ImmutableSeries<D> series,
    bool initializeFromZero,
  ) {
    final domainAxis =
        (chartState as CartesianChartState<D, CartesianChart<D>>).domainAxis;
    final domainFn = series.domainFn;
    final measureAxis =
        (chartState as CartesianChartState<D, CartesianChart<D>>)
            .getMeasureAxis(axisId: series.getAttr(measureAxisIdKey));
    final measureFn = series.measureFn;
    final measureOffsetFn = series.measureOffsetFn!;

    final pointList = <_DatumPoint<D>>[];

    // Generate [_DatumPoints]s for the series data.
    for (int index = 0; index < series.data.length; index += 1) {
      final Object? datum = series.data[index];

      // TODO: Animate from the nearest lines in the stack.
      num? measure = measureFn(index);
      if (measure != null && initializeFromZero) {
        measure = 0.0;
      }

      num? measureOffset = measureOffsetFn(index);

      if (measureOffset != null && initializeFromZero) {
        measureOffset = 0.0;
      }

      pointList.add(_getPoint(
        datum,
        domainFn(index),
        series,
        domainAxis!,
        measure,
        measureOffset,
        measureAxis,
        index: index,
      ));
    }

    return pointList;
  }

  /// Builds a list of line and area segments for a series.
  ///
  /// This method returns a list of two elements. The first is a list of line
  /// segments, and the second is a list of area segments. Both sets of segments
  /// are broken up by null measure values in the series data.
  ///
  /// [pointList] list of all points in the line.
  ///
  /// [previousPointList] list of all points in the line below this one in the
  /// stack.
  ///
  /// [series] the series that this line represents.
  List<List<List<_DatumPoint<D>>>> _createLineAndAreaSegmentsForSeries(
      List<_DatumPoint<D>> pointList,
      List<_DatumPoint<D>>? previousPointList,
      ImmutableSeries<D> series,
      bool initializeFromZero) {
    final lineSegments = <List<_DatumPoint<D>>>[];
    final areaSegments = <List<_DatumPoint<D>>>[];
    final boundsSegments = <List<_DatumPoint<D>>>[];

    int? startPointIndex;
    int? endPointIndex;

    // Only build bound segments for this series if it has bounds functions.
    final seriesHasMeasureBounds = series.measureUpperBoundFn != null &&
        series.measureLowerBoundFn != null;

    for (int index = 0; index < pointList.length; index += 1) {
      final point = pointList[index];

      if (point.dy == null) {
        if (startPointIndex == null) {
          continue;
        }
        assert(endPointIndex != null);

        lineSegments.add(
            _createLineSegment(startPointIndex, endPointIndex!, pointList));

        // Isolated data points are handled by the line painter. Do not add an
        // area segment for them.
        if (startPointIndex != endPointIndex) {
          if (config.includeArea) {
            areaSegments.add(_createAreaSegment(startPointIndex, endPointIndex,
                pointList, previousPointList, series, initializeFromZero));
          }
          if (seriesHasMeasureBounds) {
            boundsSegments.add(_createBoundsSegment(
                pointList.sublist(startPointIndex, endPointIndex + 1),
                series,
                initializeFromZero));
          }
        }

        startPointIndex = null;
        endPointIndex = null;
        continue;
      }

      startPointIndex ??= index;
      endPointIndex = index;
    }

    // Create an area point list for the final segment. This will be the only
    // segment if no null measure values were found in the series.
    if (startPointIndex != null && endPointIndex != null) {
      lineSegments
          .add(_createLineSegment(startPointIndex, endPointIndex, pointList));

      // Isolated data points are handled by the line painter. Do not add an
      // area segment for them.
      if (startPointIndex != endPointIndex) {
        if (config.includeArea) {
          areaSegments.add(_createAreaSegment(startPointIndex, endPointIndex,
              pointList, previousPointList, series, initializeFromZero));
        }

        if (seriesHasMeasureBounds) {
          boundsSegments.add(_createBoundsSegment(
              pointList.sublist(startPointIndex, endPointIndex + 1),
              series,
              initializeFromZero));
        }
      }
    }

    return [lineSegments, areaSegments, boundsSegments];
  }

  /// Builds a list of data points for a line segment.
  ///
  /// For a line, this is effectively just a sub list of [pointList].
  ///
  /// [start] index of the first point in the segment.
  ///
  /// [end] index of the last point in the segment.
  ///
  /// [pointList] list of all points in the line.
  List<_DatumPoint<D>> _createLineSegment(
          int start, int end, List<_DatumPoint<D>> pointList) =>
      pointList.sublist(start, end + 1);

  /// Builds a list of data points for an area segment.
  ///
  /// The list of points will include a baseline at the domain axis if there was
  /// no previous line in the stack. Otherwise, the bottom of the shape will
  /// consist of the points from the previous series that line up with the
  /// current series.
  ///
  /// [start] index of the first point in the segment.
  ///
  /// [end] index of the last point in the segment.
  ///
  /// [pointList] list of all points in the line.
  ///
  /// [previousPointList] list of all points in the line below this one in the
  /// stack.
  ///
  /// [series] the series that this line represents.
  List<_DatumPoint<D>> _createAreaSegment(
      int start,
      int end,
      List<_DatumPoint<D>> pointList,
      List<_DatumPoint<D>>? previousPointList,
      ImmutableSeries<D> series,
      bool initializeFromZero) {
    final domainAxis =
        (chartState as CartesianChartState<D, CartesianChart<D>>).domainAxis;
    final domainFn = series.domainFn;
    final measureAxis =
        (chartState as CartesianChartState<D, CartesianChart<D>>)
            .getMeasureAxis(axisId: series.getAttr(measureAxisIdKey));

    final areaPointList = <_DatumPoint<D>>[];

    if (!config.stacked || previousPointList == null) {
      // Start area segments at the bottom of a stack by adding a bottom line
      // segment along the measure axis.
      areaPointList.add(_getPoint(
          null, domainFn(end), series, domainAxis!, 0.0, 0.0, measureAxis));

      areaPointList.add(_getPoint(
          null, domainFn(start), series, domainAxis, 0.0, 0.0, measureAxis));
    } else {
      // Start subsequent area segments in a stack by adding the previous
      // points in reverse order, so that we can get a properly closed
      // polygon.
      areaPointList.addAll(previousPointList.sublist(start, end + 1).reversed);
    }

    areaPointList.addAll(pointList.sublist(start, end + 1));

    return areaPointList;
  }

  List<_DatumPoint<D>> _createBoundsSegment(List<_DatumPoint<D>> pointList,
      ImmutableSeries<D> series, bool initializeFromZero) {
    final measureAxis =
        (chartState as CartesianChartState<D, CartesianChart<D>>)
            .getMeasureAxis(axisId: series.getAttr(measureAxisIdKey));
    final areaPointList = <_DatumPoint<D>>[];

    // Add all points for upper bounds.
    areaPointList.addAll(
      pointList.map(
        (datumPoint) => _DatumPoint.from(
          datumPoint,
          datumPoint.dx,
          initializeFromZero
              ? datumPoint.dy
              : measureAxis.getLocation(
                  (series.measureUpperBoundFn!(datumPoint.index) ?? 0.0) +
                      series.measureOffsetFn!(datumPoint.index)!,
                ),
        ),
      ),
    );

    // Add all points for lower bounds, in reverse order.
    areaPointList.addAll(
      pointList.reversed.map(
        (datumPoint) => _DatumPoint.from(
          datumPoint,
          datumPoint.dx,
          initializeFromZero
              ? datumPoint.dy
              : measureAxis.getLocation(
                  ((series.measureLowerBoundFn!(datumPoint.index) ?? 0.0) +
                          series.measureOffsetFn!(datumPoint.index)!)
                      .toDouble(),
                ),
        ),
      ),
    );

    return areaPointList;
  }

  /// Converts the domain value extent for the series into axis positions,
  /// clamped to the edges of the draw area.
  ///
  /// [series] the series that this line represents.
  ///
  /// [details] represents the element details for a line segment.
  _Range<double> _createPositionExtent(
    ImmutableSeries<D> series,
    _LineRendererElement<D> details,
    Offset offset,
  ) {
    final bounds = Rect.fromLTWH(offset.dx, offset.dy, size.width, size.height);

    final domainAxis =
        (chartState as CartesianChartState<D, CartesianChart<D>>).domainAxis;

    // Convert the domain extent into axis positions.
    // Clamp start position to the beginning of the draw area if it is outside
    // the domain viewport range.
    final startPosition = domainAxis!.getLocation(details.domainExtent.start) ??
        bounds.left.toDouble();

    // Clamp end position to the end of the draw area if it is outside the
    // domain viewport range.
    final endPosition = domainAxis.getLocation(details.domainExtent.end) ??
        bounds.right.toDouble();

    return _Range<double>(startPosition, endPosition);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    update(offset);

    super.paint(context, offset);

    final animationPercent = chartState.animationPosition.value;

    // Clean up the lines that no longer exist.
    if (chartState.animationPosition.isCompleted) {
      final keysToRemove = <String>[];

      _seriesLineMap.forEach((String key, List<_AnimatedElements<D>> elements) {
        elements.removeWhere(
            (_AnimatedElements<D> element) => element.animatingOut);

        if (elements.isEmpty) {
          keysToRemove.add(key);
        }
      });

      keysToRemove.forEach(_seriesLineMap.remove);
    }

    _seriesLineMap.forEach((String key, List<_AnimatedElements<D>> elements) {
      if (config.includeArea) {
        elements
            .map<List<_AnimatedArea<D>>>(
                (_AnimatedElements<D> animatingElement) =>
                    animatingElement.areas!)
            .expand<_AnimatedArea<D>>((List<_AnimatedArea<D>> areas) => areas)
            .map<_AreaRendererElement<D>>((_AnimatedArea<D> animatingArea) =>
                animatingArea.getCurrentArea(animationPercent))
            .forEach((area) {
          context.canvas.drawChartPolygon(
              clipBounds: _getClipBoundsForExtent(area.positionExtent, offset),
              fill: area.areaColor ?? area.color,
              points: area.points.toPoints());
        });
      }

      if (_hasMeasureBounds) {
        elements
            .map<List<_AnimatedArea<D>>>(
                (_AnimatedElements<D> animatingElement) =>
                    animatingElement.bounds!)
            .expand<_AnimatedArea<D>>((List<_AnimatedArea<D>> bounds) => bounds)
            .map<_AreaRendererElement<D>>((_AnimatedArea<D> animatingBounds) =>
                animatingBounds.getCurrentArea(animationPercent))
            .forEach((bound) {
          context.canvas.drawChartPolygon(
              clipBounds: _getClipBoundsForExtent(bound.positionExtent, offset),
              fill: bound.areaColor ?? bound.color,
              points: bound.points.toPoints());
        });
      }

      if (config.includeLine) {
        elements
            .map<List<_AnimatedLine<D>>>(
                (_AnimatedElements<D> animatingElement) =>
                    animatingElement.lines)
            .expand<_AnimatedLine<D>>((List<_AnimatedLine<D>> lines) => lines)
            .map<_LineRendererElement<D>>((_AnimatedLine<D> animatingLine) =>
                animatingLine.getCurrentLine(animationPercent))
            .forEach((line) {
          context.canvas.drawChartLine(
            clipBounds: _getClipBoundsForExtent(line.positionExtent!, offset),
            dashPattern: line.dashPattern,
            points: line.points!.toPoints(),
            stroke: line.color!,
            strokeWidth: line.strokeWidth,
          );
        });
      }
    });
  }

  /// Builds a clip region bounding box within the component [drawBounds] for a
  /// given domain range [extent].
  Rect _getClipBoundsForExtent(_Range<double> extent, Offset offset) {
    // In RTL mode, the domain range extent has start on the right side of the
    // chart. Adjust the calculated positions to define a regular left-anchored
    // [Rect]. Clamp both ends to be within the draw area.
    final drawBounds =
        Rect.fromLTWH(offset.dx, offset.dy, size.width, size.height);

    final left = chartState.isRTL
        ? clampDouble(extent.end, drawBounds.left, drawBounds.right)
        : clampDouble(extent.start, drawBounds.left, drawBounds.right);

    final right = chartState.isRTL
        ? clampDouble(extent.start, drawBounds.left, drawBounds.right)
        : clampDouble(extent.end, drawBounds.left, drawBounds.right);

    return Rect.fromLTWH(
        left,
        drawBounds.top - drawBoundTopExtension,
        right - left,
        drawBounds.height + drawBoundTopExtension + drawBoundBottomExtension);
  }

  _DatumPoint<D> _getPoint(
    dynamic datum,
    D? domainValue,
    ImmutableSeries<D> series,
    ImmutableAxis<D> domainAxis,
    num? measureValue,
    num? measureOffsetValue,
    ImmutableAxis<num> measureAxis, {
    int? index,
  }) {
    final domainPosition = domainAxis.getLocation(domainValue);

    final measurePosition = measureValue != null && measureOffsetValue != null
        ? measureAxis.getLocation(measureValue + measureOffsetValue)
        : null;

    return _DatumPoint<D>(
        datum: datum,
        domain: domainValue,
        series: series,
        dx: domainPosition,
        dy: measurePosition,
        index: index);
  }

  @override
  List<DatumDetails<D>> getNearestDatumDetailPerSeries(
    Offset chartPoint,
    bool byDomain,
    Rect? boundsOverride, {
    bool selectOverlappingPoints = false,
    bool selectExactEventLocation = false,
  }) {
    final nearest = <DatumDetails<D>>[];

    // Was it even in the component bounds?
    if (!isPointWithinBounds(chartPoint, boundsOverride!)) {
      return nearest;
    }

    bool isFirstSeriesAbovePoint = false;

    final componentBounds =
        Rect.fromLTWH(0.0, 0.0, size.width, size.height); // TODO

    for (final seriesSegments in _seriesLineMap.values) {
      _DatumPoint<D>? nearestPoint;
      double nearestDomainDistance = 10000.0;
      double nearestMeasureDistance = 10000.0;
      double nearestRelativeDistance = 10000.0;

      for (final segment in seriesSegments) {
        if (segment.overlaySeries) {
          continue;
        }

        for (final p in segment.allPoints) {
          // Don't look at points not in the drawArea.
          if (p.dx! < componentBounds.left || p.dx! > componentBounds.right) {
            continue;
          }

          double measureDistance;
          double relativeDistance;
          double domainDistance;

          if (p.dy != null) {
            measureDistance = (p.dy! - chartPoint.dy).abs();
            domainDistance = (p.dx! - chartPoint.dx).abs();
            relativeDistance = Point(chartPoint.dx, chartPoint.dy).distanceTo(
              Point(
                p.toPoint().dx,
                p.toPoint().dy,
              ),
            );
          } else {
            // Null measures have no real position, so make them the farthest
            // away by real distance.
            measureDistance = double.infinity;
            domainDistance = double.infinity;
            relativeDistance = byDomain ? domainDistance : double.infinity;
          }

          if (byDomain) {
            if ((domainDistance < nearestDomainDistance) ||
                ((domainDistance == nearestDomainDistance) &&
                    (measureDistance < nearestMeasureDistance))) {
              nearestPoint = p;
              nearestDomainDistance = domainDistance;
              nearestMeasureDistance = measureDistance;
              nearestRelativeDistance = relativeDistance;
            }
          } else {
            if (relativeDistance < nearestRelativeDistance) {
              nearestPoint = p;
              nearestDomainDistance = domainDistance;
              nearestMeasureDistance = measureDistance;
              nearestRelativeDistance = relativeDistance;
            }
          }
        }

        // For area charts, check if the current series is the first series
        // above [chartPoint] or not. If it is, it means that [chartPoint] is
        // inside the area skirt of the current series. In this case, set the
        // measure distance to 0 so the current [nearestPoint] has the smallest
        // measure distance among all.
        if (config.includeArea &&
            !isFirstSeriesAbovePoint &&
            nearestPoint != null &&
            _isPointBelowSeries(chartPoint, nearestPoint, segment.allPoints)) {
          nearestMeasureDistance = 0;
          isFirstSeriesAbovePoint = true;
        }
      }

      // Found a point, add it to the list.
      if (nearestPoint != null) {
        nearest.add(DatumDetails<D>(
            chartPosition: NullablePoint(nearestPoint.dx, nearestPoint.dy),
            datum: nearestPoint.datum,
            domain: nearestPoint.domain,
            series: nearestPoint.series,
            domainDistance: nearestDomainDistance,
            measureDistance: nearestMeasureDistance,
            relativeDistance: nearestRelativeDistance));
      }
    }

    // Note: the details are already sorted by domain & measure distance in
    // base chart.

    return nearest;
  }

  /// Checks if [chartPoint] is below the series represented by
  /// [allPointsForSeries] or not.
  ///
  /// [nearestPoint] is the point in [allPointsForSeries] that is closest to
  /// [chartPoint].
  bool _isPointBelowSeries(Offset chartPoint, _DatumPoint<D> nearestPoint,
      List<_DatumPoint<D>> allPointsForSeries) {
    _DatumPoint<D>? leftPoint;
    _DatumPoint<D>? rightPoint;
    final nearestPointIdx =
        allPointsForSeries.indexWhere((p) => p == nearestPoint);
    if (chartPoint.dx < nearestPoint.dx!) {
      leftPoint =
          nearestPointIdx > 0 ? allPointsForSeries[nearestPointIdx - 1] : null;
      rightPoint = nearestPoint;
    } else {
      leftPoint = nearestPoint;
      rightPoint = nearestPointIdx < allPointsForSeries.length - 1
          ? allPointsForSeries[nearestPointIdx + 1]
          : null;
    }
    double limit = chartPoint.dy;
    if (leftPoint != null &&
        leftPoint.dy != null &&
        rightPoint != null &&
        rightPoint.dy != null) {
      final slope =
          (rightPoint.dy! - leftPoint.dy!) / (rightPoint.dx! - leftPoint.dx!);
      limit = (chartPoint.dx - leftPoint.dx!) * slope + leftPoint.dy!;
    } else if (leftPoint != null && leftPoint.dy != null) {
      limit = leftPoint.dy!;
    } else if (rightPoint != null && rightPoint.dy != null) {
      limit = rightPoint.dy!;
    }

    return chartPoint.dy >= limit;
  }

  @override
  DatumDetails<D> addPositionToDetailsForSeriesDatum(
      DatumDetails<D> details, SeriesDatum<D> seriesDatum) {
    final series = details.series!;

    final domainAxis =
        (chartState as CartesianChartState<D, CartesianChart<D>>).domainAxis;
    final measureAxis =
        (chartState as CartesianChartState<D, CartesianChart<D>>)
            .getMeasureAxis(axisId: series.getAttr(measureAxisIdKey));

    final point = _getPoint(
      seriesDatum.datum,
      details.domain,
      series,
      domainAxis!,
      details.measure,
      details.measureOffset,
      measureAxis,
    );
    final chartPosition = NullablePoint(point.dx, point.dy);

    return DatumDetails.from(details, chartPosition: chartPosition);
  }
}

class _DatumPoint<D> extends NullablePoint {
  _DatumPoint({
    this.datum,
    this.domain,
    this.series,
    this.index,
    double? dx,
    double? dy,
  }) : super(dx, dy);

  factory _DatumPoint.from(_DatumPoint<D> other, [double? dx, double? dy]) {
    return _DatumPoint<D>(
      datum: other.datum,
      domain: other.domain,
      series: other.series,
      index: other.index,
      dx: dx ?? other.dx,
      dy: dy ?? other.dy,
    );
  }

  final dynamic datum;
  final D? domain;
  final ImmutableSeries<D>? series;
  final int? index;
}

/// Rendering information for the line portion of a series.
class _LineRendererElement<D> {
  _LineRendererElement({
    this.points,
    required this.color,
    required this.areaColor,
    required this.dashPattern,
    required this.domainExtent,
    this.measureAxisPosition,
    this.positionExtent,
    required this.strokeWidth,
    required this.styleKey,
    required this.roundEndCaps,
  });

  List<_DatumPoint<D>>? points;
  Color? color;
  Color? areaColor;
  List<int>? dashPattern;
  _Range<D> domainExtent;
  double? measureAxisPosition;
  _Range<double>? positionExtent;
  double strokeWidth;
  String styleKey;
  bool roundEndCaps;

  _LineRendererElement<D> clone() {
    return _LineRendererElement<D>(
      points: points != null ? List.of(points!) : null,
      color: color,
      areaColor: areaColor,
      dashPattern: dashPattern != null ? List.of(dashPattern!) : null,
      domainExtent: domainExtent,
      measureAxisPosition: measureAxisPosition,
      positionExtent: positionExtent,
      strokeWidth: strokeWidth,
      styleKey: styleKey,
      roundEndCaps: roundEndCaps,
    );
  }

  void updateAnimationPercent(_LineRendererElement<D> previous,
      _LineRendererElement<D> target, double animationPercent) {
    final points = this.points!;

    late _DatumPoint<D> lastPoint;

    int pointIndex;
    for (pointIndex = 0; pointIndex < target.points!.length; pointIndex += 1) {
      final targetPoint = target.points![pointIndex];

      // If we have more points than the previous line, animate in the point
      // by starting its measure position at the last known official point.
      // TODO: Can this be done in setNewTarget instead?
      _DatumPoint<D> previousPoint;
      if (previous.points!.length - 1 >= pointIndex) {
        previousPoint = previous.points![pointIndex];
        lastPoint = previousPoint;
      } else {
        previousPoint =
            _DatumPoint<D>.from(targetPoint, targetPoint.dx, lastPoint.dy);
      }

      final x = ((targetPoint.dx! - previousPoint.dx!) * animationPercent) +
          previousPoint.dx!;

      double? y;
      if (targetPoint.dy != null && previousPoint.dy != null) {
        y = ((targetPoint.dy! - previousPoint.dy!) * animationPercent) +
            previousPoint.dy!;
      } else if (targetPoint.dy != null) {
        y = targetPoint.dy;
      } else {
        y = null;
      }

      if (points.length - 1 >= pointIndex) {
        points[pointIndex] = _DatumPoint<D>.from(targetPoint, x, y);
      } else {
        points.add(_DatumPoint<D>.from(targetPoint, x, y));
      }
    }

    // Removing extra points that don't exist anymore.
    if (pointIndex < points.length) {
      points.removeRange(pointIndex, points.length);
    }

    color = getAnimatedColor(previous.color!, target.color!, animationPercent);

    if (areaColor != null) {
      areaColor = getAnimatedColor(
          previous.areaColor!, target.areaColor!, animationPercent);
    }

    strokeWidth =
        ((target.strokeWidth - previous.strokeWidth) * animationPercent) +
            previous.strokeWidth;
  }
}

/// Animates the line element of a series between different states.
class _AnimatedLine<D> {
  _AnimatedLine({required this.key, required this.overlaySeries});

  final String key;
  final bool overlaySeries;

  _LineRendererElement<D>? _previousLine;
  late _LineRendererElement<D> _targetLine;
  _LineRendererElement<D>? _currentLine;

  // Flag indicating whether this line is being animated out of the chart.
  bool animatingOut = false;

  /// Animates a line that was removed from the series out of the view.
  ///
  /// This should be called in place of "setNewTarget" for lines that represent
  /// data that has been removed from the series.
  ///
  /// Animates the height of the line down to the measure axis position
  /// (position of 0).
  void animateOut() {
    final newTarget = _currentLine!.clone();

    // Set the target measure value to the axis position for all points.
    // TODO: Animate to the nearest lines in the stack.
    final newPoints = <_DatumPoint<D>>[];
    for (int index = 0; index < newTarget.points!.length; index += 1) {
      final targetPoint = newTarget.points![index];

      newPoints.add(_DatumPoint<D>.from(targetPoint, targetPoint.dx,
          newTarget.measureAxisPosition!.roundToDouble()));
    }

    newTarget.points = newPoints;

    // Animate the stroke width to 0 so that we don't get a lingering line after
    // animation is done.
    newTarget.strokeWidth = 0.0;

    setNewTarget(newTarget);
    animatingOut = true;
  }

  void setNewTarget(_LineRendererElement<D> newTarget) {
    animatingOut = false;
    _currentLine ??= newTarget.clone();
    _previousLine = _currentLine!.clone();
    _targetLine = newTarget;
  }

  _LineRendererElement<D> getCurrentLine(double animationPercent) {
    if (animationPercent == 1.0 || _previousLine == null) {
      _currentLine = _targetLine;
      _previousLine = _targetLine;
      return _currentLine!;
    }

    _currentLine!
        .updateAnimationPercent(_previousLine!, _targetLine, animationPercent);

    return _currentLine!;
  }

  /// Returns the [points] of the current target element, without updating
  /// animation state.
  List<_DatumPoint<D>>? get currentPoints => _currentLine?.points;
}

/// Rendering information for the area skirt portion of a series.
class _AreaRendererElement<D> {
  _AreaRendererElement({
    required this.points,
    required this.color,
    required this.areaColor,
    required this.domainExtent,
    required this.measureAxisPosition,
    required this.positionExtent,
    required this.styleKey,
  });

  List<_DatumPoint<D>> points;
  Color? color;
  Color? areaColor;
  _Range<D> domainExtent;
  double measureAxisPosition;
  _Range<double> positionExtent;
  String styleKey;

  _AreaRendererElement<D> clone() {
    return _AreaRendererElement<D>(
      points: List.of(points),
      color: color,
      areaColor: areaColor,
      domainExtent: domainExtent,
      measureAxisPosition: measureAxisPosition,
      positionExtent: positionExtent,
      styleKey: styleKey,
    );
  }

  void updateAnimationPercent(_AreaRendererElement<D> previous,
      _AreaRendererElement<D> target, double animationPercent) {
    late _DatumPoint<D> lastPoint;

    int pointIndex;
    for (pointIndex = 0; pointIndex < target.points.length; pointIndex += 1) {
      final targetPoint = target.points[pointIndex];

      // If we have more points than the previous line, animate in the point
      // by starting its measure position at the last known official point.
      // TODO: Can this be done in setNewTarget instead?
      _DatumPoint<D> previousPoint;
      if (previous.points.length - 1 >= pointIndex) {
        previousPoint = previous.points[pointIndex];
        lastPoint = previousPoint;
      } else {
        previousPoint =
            _DatumPoint<D>.from(targetPoint, targetPoint.dx, lastPoint.dy);
      }

      final x = ((targetPoint.dx! - previousPoint.dx!) * animationPercent) +
          previousPoint.dx!;

      double? y;
      if (targetPoint.dy != null && previousPoint.dy != null) {
        y = ((targetPoint.dy! - previousPoint.dy!) * animationPercent) +
            previousPoint.dy!;
      } else if (targetPoint.dy != null) {
        y = targetPoint.dy;
      } else {
        y = null;
      }

      if (points.length - 1 >= pointIndex) {
        points[pointIndex] = _DatumPoint<D>.from(targetPoint, x, y);
      } else {
        points.add(_DatumPoint<D>.from(targetPoint, x, y));
      }
    }

    // Removing extra points that don't exist anymore.
    if (pointIndex < points.length) {
      points.removeRange(pointIndex, points.length);
    }

    color = getAnimatedColor(previous.color!, target.color!, animationPercent);

    if (areaColor != null) {
      areaColor = getAnimatedColor(
          previous.areaColor!, target.areaColor!, animationPercent);
    }
  }
}

/// Animates the area element of a series between different states.
class _AnimatedArea<D> {
  _AnimatedArea({required this.key, required this.overlaySeries});

  final String key;
  final bool overlaySeries;

  _AreaRendererElement<D>? _previousArea;
  late _AreaRendererElement<D> _targetArea;
  _AreaRendererElement<D>? _currentArea;

  // Flag indicating whether this line is being animated out of the chart.
  bool animatingOut = false;

  /// Animates a line that was removed from the series out of the view.
  ///
  /// This should be called in place of "setNewTarget" for lines that represent
  /// data that has been removed from the series.
  ///
  /// Animates the height of the line down to the measure axis position
  /// (position of 0).
  void animateOut() {
    final newTarget = _currentArea!.clone();

    // Set the target measure value to the axis position for all points.
    // TODO: Animate to the nearest areas in the stack.
    final newPoints = <_DatumPoint<D>>[];
    for (int index = 0; index < newTarget.points.length; index += 1) {
      final targetPoint = newTarget.points[index];

      newPoints.add(_DatumPoint<D>.from(targetPoint, targetPoint.dx,
          newTarget.measureAxisPosition.roundToDouble()));
    }

    newTarget.points = newPoints;

    setNewTarget(newTarget);
    animatingOut = true;
  }

  void setNewTarget(_AreaRendererElement<D> newTarget) {
    animatingOut = false;
    _currentArea ??= newTarget.clone();
    _previousArea = _currentArea!.clone();
    _targetArea = newTarget;
  }

  _AreaRendererElement<D> getCurrentArea(double animationPercent) {
    if (animationPercent == 1.0 || _previousArea == null) {
      _currentArea = _targetArea;
      _previousArea = _targetArea;
      return _currentArea!;
    }

    _currentArea!
        .updateAnimationPercent(_previousArea!, _targetArea, animationPercent);

    return _currentArea!;
  }
}

class _AnimatedElements<D> {
  _AnimatedElements({
    required this.allPoints,
    required this.areas,
    required this.lines,
    required this.bounds,
    required this.styleKey,
  });

  List<_DatumPoint<D>> allPoints;
  List<_AnimatedArea<D>>? areas;
  List<_AnimatedLine<D>> lines;
  List<_AnimatedArea<D>>? bounds;
  String styleKey;

  bool get animatingOut {
    bool areasAnimatingOut = true;
    if (areas != null) {
      for (final area in areas!) {
        areasAnimatingOut = areasAnimatingOut && area.animatingOut;
      }
    }

    bool linesAnimatingOut = true;
    for (final line in lines) {
      linesAnimatingOut = linesAnimatingOut && line.animatingOut;
    }

    bool boundsAnimatingOut = true;
    if (bounds != null) {
      for (final bound in bounds!) {
        boundsAnimatingOut = boundsAnimatingOut && bound.animatingOut;
      }
    }

    return areasAnimatingOut && linesAnimatingOut && boundsAnimatingOut;
  }

  bool get overlaySeries {
    bool areasOverlaySeries = true;
    if (areas != null) {
      for (final area in areas!) {
        areasOverlaySeries = areasOverlaySeries && area.overlaySeries;
      }
    }

    bool linesOverlaySeries = true;
    for (final line in lines) {
      linesOverlaySeries = linesOverlaySeries && line.overlaySeries;
    }

    bool boundsOverlaySeries = true;
    if (bounds != null) {
      for (final bound in bounds!) {
        boundsOverlaySeries = boundsOverlaySeries && bound.overlaySeries;
      }
    }

    return areasOverlaySeries && linesOverlaySeries && boundsOverlaySeries;
  }
}

/// Describes a numeric range with a start and end value.
///
/// [start] must always be less than [end].
class _Range<D> {
  _Range(D start, D end)
      : _start = start,
        _end = end;

  D _start;
  D _end;

  /// Gets the start of the range.
  D get start => _start;

  /// Gets the end of the range.
  D get end => _end;

  /// Extends the range to include [value].
  void includePoint(D? value) {
    if (value == null) {
      return;
    } else if (value is num) {
      _includePointAsNum(value);
    } else if (value is DateTime) {
      _includePointAsDateTime(value);
    } else if (value is String) {
      _includePointAsString(value);
    } else {
      throw ArgumentError(
          'Unsupported object type for LineRenderer domain value: '
          '${value.runtimeType}');
    }
  }

  /// Extends the range to include value by casting as numbers.
  void _includePointAsNum(D value) {
    value as num;
    if (value < (_start as num)) {
      _start = value;
    } else if (value > (_end as num)) {
      _end = value;
    }
  }

  /// Extends the range to include value by casting as DateTime objects.
  void _includePointAsDateTime(D value) {
    value as DateTime;
    if (value.isBefore(_start as DateTime)) {
      _start = value;
    } else if (value.isAfter(_end as DateTime)) {
      _end = value;
    }
  }

  /// Extends the range to include value by casting as String objects.
  ///
  /// In this case, we assume that the data is ordered in the same order as the
  /// axis.
  void _includePointAsString(D value) {
    _end = value;
  }
}

@visibleForTesting
class LineRendererTester<D, S extends BaseChart<D>> {
  LineRendererTester(this.renderer);

  final LineRenderer<D, S> renderer;

  Iterable<String> get seriesKeys => renderer._seriesLineMap.keys;

  void setSeriesKeys(List<String> keys) {
    renderer._seriesLineMap.addEntries(keys.map((key) => MapEntry(key, [])));
  }

  void merge(List<ImmutableSeries<D>> series) {
    renderer._mergeIntoSeriesMap(series);
  }
}
