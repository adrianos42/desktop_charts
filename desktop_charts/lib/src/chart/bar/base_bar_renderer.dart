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

import 'dart:collection' show HashSet;
import 'dart:math' show max, Point;

import 'package:collection/collection.dart' show IterableExtension;
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import '../../data/series.dart' show AttributeKey;
import '../base_chart.dart' show BaseChart;
import '../cartesian/axis/axis.dart'
    show ImmutableAxis, OrdinalAxis, measureAxisIdKey;
import '../cartesian/axis/scale.dart' show RangeBandConfig;
import '../cartesian/cartesian_chart.dart'
    show CartesianChartState, CartesianChart;
import '../cartesian/cartesian_renderer.dart' show BaseCartesianRenderer;
import '../chart_canvas.dart' show FillPatternType;
import '../datum_details.dart' show DatumDetails;
import '../processed_series.dart' show ImmutableSeries, MutableSeries;
import 'base_bar_renderer_config.dart' show BaseBarRendererConfig;
import 'base_bar_renderer_element.dart'
    show BaseAnimatedBar, BaseBarRendererElement;

const barGroupIndexKey = AttributeKey<int>('BarRenderer.barGroupIndex');

const barGroupCountKey = AttributeKey<int>('BarRenderer.barGroupCount');

const barGroupWeightKey = AttributeKey<double>('BarRenderer.barGroupWeight');

const previousBarGroupWeightKey =
    AttributeKey<double>('BarRenderer.previousBarGroupWeight');

const allBarGroupWeightsKey =
    AttributeKey<List<double>>('BarRenderer.allBarGroupWeights');

const stackKeyKey = AttributeKey<String>('BarRenderer.stackKey');

const barElementsKey =
    AttributeKey<List<BaseBarRendererElement>>('BarRenderer.elements');

/// Base class for bar renderers that implements common stacking and grouping
/// logic.
///
/// Bar renderers support 4 different modes of rendering multiple series on the
/// chart, configured by the grouped and stacked flags.
/// * grouped - Render bars for each series that shares a domain value
///   side-by-side.
/// * stacked - Render bars for each series that shares a domain value in a
///   stack, ordered in the same order as the series list.
/// * grouped-stacked: Render bars for each series that shares a domain value in
///   a group of bar stacks. Each stack will contain all the series that share a
///   series category.
/// * floating style - When grouped and stacked are both false, all bars that
///   share a domain value will be rendered in the same domain space. Each datum
///   should be configured with a measure offset to position its bar along the
///   measure axis. Bars will freely overlap if their measure values and measure
///   offsets overlap. Note that bars for each series will be rendered in order,
///   such that bars from the last series will be "on top" of bars from previous
///   series.
abstract class BaseBarRenderer<
    D,
    E extends BaseBarRendererElement,
    B extends BaseAnimatedBar<D, E>,
    S extends BaseChart<D>> extends BaseCartesianRenderer<D, S> {
  BaseBarRenderer({
    required this.config,
    required super.rendererId,
    required super.chartState,
    required super.seriesList,
  }) : super(symbolRenderer: config.symbolRenderer);

  // `config` can't be a `BaseBarRendererConfig<D>` because `BarLaneRenderer<D>`
  // passes a `BarLaneRendererConfig`, but `BarLaneRendererConfig` is a
  // `BarRendererConfig<String>`.
  final BaseBarRendererConfig<Object?> config;

  // Save the chart.vertical value at the start of every draw cycle. If it
  // changes, delete all of the cached rendering element information so that we
  // start with a fresh state.
  bool _lastVertical = true;

  /// Store a map of domain+barGroupIndex+category index to bars in a stack.
  ///
  /// This map is used to render all the bars in a stack together, to account
  /// for rendering effects that need to take the full stack into account (e.g.
  /// corner rounding).
  ///
  /// [Map] is used to render the bars on the canvas in the same order
  /// as the data was given to the chart. For the case where both grouping and
  /// stacking are disabled, this means that bars for data later in the series
  /// will be drawn "on top of" bars earlier in the series.
  // ignore: prefer_collection_literals, https://github.com/dart-lang/linter/issues/1649
  final _barStackMap = Map<String, List<B>>();

  // Store a list of bar stacks that exist in the series data.
  //
  // This list will be used to remove any AnimatingBars that were rendered in
  // previous draw cycles, but no longer have a corresponding datum in the new
  // data.
  final _currentKeys = <String>[];

  /// Stores a list of stack keys for each group key.
  // ignore: prefer_collection_literals, https://github.com/dart-lang/linter/issues/1649
  final _currentGroupsStackKeys = Map<D, Set<String>>();

  /// Optimization for getNearest to avoid scanning all data if possible.
  ImmutableAxis<D>? _prevDomainAxis;

  @override
  void preprocessSeries() {
    // If the orientation of the chart changed, delete all data from the last
    // draw cycle. This allows us to start in a fresh state, so that we do not
    // get bad animations from the previously drawn data.
    //
    // Ideally we should animate the old bars out smoothly in some ways, but
    // this was the cheapest option.
    if (_lastVertical != chart.widget.isVertical) {
      _barStackMap.clear();
      _currentKeys.clear();
      _currentGroupsStackKeys.clear();
    }

    _lastVertical = chart.widget.isVertical;

    int barGroupIndex = 0;

    // Maps used to store the final measure offset of the previous series, for
    // each domain value.
    final posDomainToStackKeyToDetailsMap =
        <D, Map<String, BaseBarRendererElement>>{};
    final negDomainToStackKeyToDetailsMap =
        <D, Map<String, BaseBarRendererElement>>{};
    final categoryToIndexMap = <String, int>{};

    // Keep track of the largest bar stack size. This should be 1 for grouped
    // bars, and it should be the size of the tallest stack for stacked or
    // grouped stacked bars.
    int maxBarStackSize = 0;

    final orderedSeriesList = getOrderedSeriesList(seriesList);

    orderedSeriesList.forEach((MutableSeries<D> series) {
      final elements = <BaseBarRendererElement>[];

      final domainFn = series.domainFn;
      final measureFn = series.measureFn;
      final measureOffsetFn = series.measureOffsetFn;
      final fillPatternFn = series.fillPatternFn;
      final strokeWidthFn = series.strokeWidthFn;

      series.dashPatternFn ??= (_) => config.dashPattern;

      // Identifies which stack the series will go in, by default a single
      // stack.
      String stackKey = '__defaultKey__';

      // Override the stackKey with seriesCategory if we are GROUPED_STACKED
      // so we have a way to choose which series go into which stacks.
      if (config.grouped && config.stacked) {
        if (series.seriesCategory != null) {
          stackKey = series.seriesCategory!;
        }

        if (categoryToIndexMap.containsKey(stackKey)) {
          barGroupIndex = categoryToIndexMap[stackKey]!;
        } else {
          barGroupIndex = categoryToIndexMap.length;
          categoryToIndexMap[stackKey] = barGroupIndex;
        }
      }

      bool needsMeasureOffset = false;

      for (int barIndex = 0; barIndex < series.data.length; barIndex += 1) {
        final datum = series.data[barIndex];
        final details = getBaseDetails(datum, barIndex);

        details.barStackIndex = 0;
        details.measureOffset = measureOffsetFn!(barIndex);

        if (fillPatternFn != null) {
          details.fillPattern = fillPatternFn(barIndex);
        } else {
          details.fillPattern = config.fillPattern;
        }

        if (strokeWidthFn != null) {
          details.strokeWidth = strokeWidthFn(barIndex)?.toDouble();
        } else {
          details.strokeWidth = config.strokeWidth;
        }

        // When stacking is enabled, adjust the measure offset for each domain
        // value in each series by adding up the measures and offsets of lower
        // series.
        if (config.stacked) {
          needsMeasureOffset = true;
          final domain = domainFn(barIndex);
          final measure = measureFn(barIndex);

          // We will render positive bars in one stack, and negative bars in a
          // separate stack. Keep track of the measure offsets for these stacks
          // independently.
          final domainToCategoryToDetailsMap = measure == null || measure >= 0
              ? posDomainToStackKeyToDetailsMap
              : negDomainToStackKeyToDetailsMap;

          final categoryToDetailsMap = domainToCategoryToDetailsMap.putIfAbsent(
              domain, () => <String, BaseBarRendererElement>{});

          final prevDetail = categoryToDetailsMap[stackKey];

          if (prevDetail != null) {
            details.barStackIndex = prevDetail.barStackIndex! + 1;
          }

          details.cumulativeTotal = measure?.toDouble() ?? 0.0;

          // Get the previous series' measure offset.
          num measureOffset = measureOffsetFn(barIndex)!;
          if (prevDetail != null) {
            measureOffset += prevDetail.measureOffsetPlusMeasure!;

            details.cumulativeTotal =
                details.cumulativeTotal! + prevDetail.cumulativeTotal!;
          }

          // And overwrite the details measure offset.
          details.measureOffset = measureOffset;
          final measureValue = measure ?? 0;
          details.measureOffsetPlusMeasure = measureOffset + measureValue;

          categoryToDetailsMap[stackKey] = details;
        }

        maxBarStackSize = max(maxBarStackSize, details.barStackIndex! + 1);

        elements.add(details);
      }

      if (needsMeasureOffset) {
        // Override the measure offset function to return the measure offset we
        // calculated for each datum. This already includes any measure offset
        // that was configured in the series data.
        series.measureOffsetFn = (index) => elements[index!].measureOffset!;
      }

      series.setAttr(barGroupIndexKey, barGroupIndex);
      series.setAttr(stackKeyKey, stackKey);
      series.setAttr(barElementsKey, elements);

      if (config.grouped) {
        barGroupIndex += 1;
      }
    });

    // Compute number of bar groups. This must be done after we have processed
    // all of the series once, so that we know how many categories we have.
    int numBarGroups = 0;
    if (config.grouped && config.stacked) {
      // For grouped stacked bars, categoryToIndexMap effectively one list per
      // group of stacked bars.
      numBarGroups = categoryToIndexMap.length;
    } else if (config.stacked) {
      numBarGroups = 1;
    } else {
      numBarGroups = seriesList.length;
    }

    // Compute bar group weights.
    final barWeights = _calculateBarWeights(numBarGroups);

    for (final MutableSeries<D> series in seriesList) {
      series.setAttr(barGroupCountKey, numBarGroups);

      if (barWeights.isNotEmpty) {
        final barGroupIndex = series.getAttr(barGroupIndexKey)!;
        final barWeight = barWeights[barGroupIndex];

        // In RTL mode, we need to grab the weights for the bars that follow
        // this datum in the series (instead of precede it). The first datum is
        // physically positioned on the canvas to the right of all the rest of
        // the bar group data that follows it.
        final previousBarWeights = isRtl
            ? barWeights.getRange(barGroupIndex + 1, numBarGroups)
            : barWeights.getRange(0, barGroupIndex);

        final previousBarWeight = previousBarWeights.isNotEmpty
            ? previousBarWeights.reduce((a, b) => a + b)
            : 0.0;

        series.setAttr(barGroupWeightKey, barWeight);
        series.setAttr(previousBarGroupWeightKey, previousBarWeight);
        series.setAttr(allBarGroupWeightsKey, barWeights);
      }
    }
  }

  /// Calculates bar weights for a list of series from [config.weightPattern].
  ///
  /// If [config.weightPattern] is not set, then this will assign a weight
  /// proportional to the number of bar groups for every series.
  List<double> _calculateBarWeights(int numBarGroups) {
    // Set up bar weights for each series as a ratio of the total weight.
    final weights = <double>[];

    if (config.weightPattern != null) {
      if (numBarGroups > config.weightPattern!.length) {
        throw ArgumentError('Number of series exceeds length of weight '
            'pattern ${config.weightPattern}');
      }

      int totalBarWeight = 0;

      for (int i = 0; i < numBarGroups; i += 1) {
        totalBarWeight += config.weightPattern![i];
      }

      for (int i = 0; i < numBarGroups; i += 1) {
        weights.add(config.weightPattern![i] / totalBarWeight);
      }
    } else {
      for (int i = 0; i < numBarGroups; i += 1) {
        weights.add(1 / numBarGroups);
      }
    }

    return weights;
  }

  /// Construct a base details element for a given datum.
  ///
  /// This is intended to be overridden by child classes that need to add
  /// customized rendering properties.
  @protected
  E getBaseDetails(dynamic datum, int index);

  @override
  void configureDomainAxes() {
    super.configureDomainAxes();

    // Configure the domain axis to use a range band configuration.
    if (seriesList.isNotEmpty) {
      // Given that charts can only have one domain axis, just grab it from the
      // first series.
      final domainAxis =
          (chartState as CartesianChartState<D, CartesianChart<D>>).domainAxis!;
      // rangeBandConfig is set when current config is not valid to render
      // bars (this is necessary with combo charts that have NumericAxis)
      if (!domainAxis.hasValidBarChartRangeBandConfig) {
        domainAxis.setRangeBandConfig(
            RangeBandConfig.styleAssignedPercent(chartState.themeData));
      }
    }
  }

  @override
  void update() {
    super.update();

    _currentKeys.clear();
    _currentGroupsStackKeys.clear();

    final orderedSeriesList = getOrderedSeriesList(seriesList);

    for (final ImmutableSeries<D> series in orderedSeriesList) {
      final domainAxis =
          (chartState as CartesianChartState<D, CartesianChart<D>>).domainAxis;
      final domainFn = series.domainFn;
      final measureAxis =
          (chartState as CartesianChartState<D, CartesianChart<D>>)
              .getMeasureAxis(
        axisId: series.getAttr(measureAxisIdKey),
      );
      final measureFn = series.measureFn;
      final colorFn = series.colorFn;
      final dashPatternFn = series.dashPatternFn;
      final fillColorFn = series.fillColorFn;
      final seriesStackKey = series.getAttr(stackKeyKey);
      final barGroupCount = series.getAttr(barGroupCountKey);
      final barGroupIndex = series.getAttr(barGroupIndexKey);
      final previousBarGroupWeight = series.getAttr(previousBarGroupWeightKey);
      final barGroupWeight = series.getAttr(barGroupWeightKey);
      final allBarGroupWeights = series.getAttr(allBarGroupWeightsKey);
      final measureAxisPosition = measureAxis.getLocation(0.0);

      final elementsList = series.getAttr(barElementsKey);

      // Save off domainAxis for getNearest.
      _prevDomainAxis = domainAxis;

      for (int barIndex = 0; barIndex < series.data.length; barIndex += 1) {
        final Object? datum = series.data[barIndex];
        final details = elementsList![barIndex];
        final domainValue = domainFn(barIndex);

        final measureValue = measureFn(barIndex);
        final measureIsNull = measureValue == null;
        final measureIsNegative = !measureIsNull && measureValue < 0;

        // Each bar should be stored in barStackMap in a structure that mirrors
        // the visual rendering of the bars. Thus, they should be grouped by
        // domain value, series category (by way of the stack keys that were
        // generated for each series in the pre-process step), and bar group
        // index to account for all combinations of grouping and stacking.
        final barStackMapKey = '$domainValue'
            '__'
            '$seriesStackKey'
            '__'
            '${measureIsNegative ? 'pos' : 'neg'}'
            '__'
            '$barGroupIndex';

        final barKey = '$barStackMapKey${details.barStackIndex}';

        final barStackList = _barStackMap.putIfAbsent(barStackMapKey, () => []);

        // If we already have an AnimatingBarfor that index, use it.
        B? animatingBar =
            barStackList.firstWhereOrNull((B bar) => bar.key == barKey);

        // If we don't have any existing bar element, create a bar and have
        // it animate in from the domain axis.
        // TODO: Animate bars in the middle of a stack from their
        // nearest neighbors, instead of the measure axis.
        if (animatingBar == null) {
          // If the measure is null and there was no existing animating bar, it
          // means we don't need to draw this bar at all.
          if (!measureIsNull) {
            animatingBar = makeAnimatedBar(
              key: barKey,
              series: series,
              datum: datum,
              barGroupIndex: barGroupIndex!,
              previousBarGroupWeight: previousBarGroupWeight,
              barGroupWeight: barGroupWeight,
              allBarGroupWeights: allBarGroupWeights,
              color: colorFn!(barIndex),
              dashPattern: dashPatternFn!(barIndex),
              details: details as E,
              domainValue: domainFn(barIndex),
              domainAxis: domainAxis!,
              domainWidth: domainAxis.rangeBand.roundToDouble(),
              fillColor: fillColorFn!(barIndex),
              fillPattern: details.fillPattern,
              measureValue: 0.0,
              measureOffsetValue: 0.0,
              measureAxisPosition: measureAxisPosition,
              measureAxis: measureAxis,
              numBarGroups: barGroupCount!,
              strokeWidth: details.strokeWidth,
              measureIsNull: measureIsNull,
              measureIsNegative: measureIsNegative,
            );

            barStackList.add(animatingBar);
          }
        } else {
          animatingBar
            ..datum = datum
            ..series = series
            ..domainValue = domainValue;
        }

        if (animatingBar == null) {
          continue;
        }

        // Update the set of bars that still exist in the series data.
        _currentKeys.add(barKey);

        // Store off stack keys for each bar group to help getNearest identify
        // groups of stacks.
        _currentGroupsStackKeys
            .putIfAbsent(domainValue, () => <String>{})
            .add(barStackMapKey);

        // Get the barElement we are going to setup.
        // Optimization to prevent allocation in non-animating case.
        final BaseBarRendererElement barElement = makeBarRendererElement(
          barGroupIndex: barGroupIndex!,
          previousBarGroupWeight: previousBarGroupWeight,
          barGroupWeight: barGroupWeight,
          allBarGroupWeights: allBarGroupWeights,
          color: colorFn!(barIndex),
          dashPattern: dashPatternFn!(barIndex),
          details: details as E,
          domainValue: domainFn(barIndex),
          domainAxis: domainAxis!,
          domainWidth: domainAxis.rangeBand.roundToDouble(),
          fillColor: fillColorFn!(barIndex),
          fillPattern: details.fillPattern,
          measureValue: measureValue,
          measureOffsetValue: details.measureOffset!,
          measureAxisPosition: measureAxisPosition,
          measureAxis: measureAxis,
          numBarGroups: barGroupCount!,
          strokeWidth: details.strokeWidth,
          measureIsNull: measureIsNull,
          measureIsNegative: measureIsNegative,
        );

        animatingBar.setNewTarget(barElement as E);
      }
    }

    // Animate out bars that don't exist anymore.
    _barStackMap.forEach((String key, List<B> barStackList) {
      for (int barIndex = 0; barIndex < barStackList.length; barIndex += 1) {
        final bar = barStackList[barIndex];
        if (!_currentKeys.contains(bar.key)) {
          bar.animateOut();
        }
      }
    });
  }

  /// Generates a [BaseAnimatedBar] to represent the previous and current state
  /// of one bar on the chart.
  @protected
  B makeAnimatedBar({
    required String key,
    required ImmutableSeries<D> series,
    dynamic datum,
    required int barGroupIndex,
    double? previousBarGroupWeight,
    double? barGroupWeight,
    List<double>? allBarGroupWeights,
    Color? color,
    List<int>? dashPattern,
    required E details,
    D? domainValue,
    required ImmutableAxis<D> domainAxis,
    required double domainWidth,
    double? measureValue,
    required double measureOffsetValue,
    required ImmutableAxis<num> measureAxis,
    double? measureAxisPosition,
    required int numBarGroups,
    Color? fillColor,
    FillPatternType? fillPattern,
    double? strokeWidth,
    bool? measureIsNull,
    bool? measureIsNegative,
  });

  /// Generates a [BaseBarRendererElement] to represent the rendering data for
  /// one bar on the chart.
  @protected
  E makeBarRendererElement({
    required int barGroupIndex,
    double? previousBarGroupWeight,
    double? barGroupWeight,
    List<double>? allBarGroupWeights,
    Color? color,
    List<int>? dashPattern,
    required E details,
    D? domainValue,
    required ImmutableAxis<D> domainAxis,
    required double domainWidth,
    num? measureValue,
    required num measureOffsetValue,
    required ImmutableAxis<num> measureAxis,
    double? measureAxisPosition,
    required int numBarGroups,
    Color? fillColor,
    FillPatternType? fillPattern,
    double? strokeWidth,
    bool? measureIsNull,
    bool? measureIsNegative,
  });

  /// Paints the current bar data on the canvas.
  @override
  void paint(PaintingContext context, Offset offset) {
    super.paint(context, offset);
    
    final animationPercent = chartState.animationPosition.value;

    // Clean up the bars that no longer exist.
    if (chartState.animationPosition.isCompleted) {
      final keysToRemove = HashSet<String>();

      _barStackMap.forEach((String key, List<B> barStackList) {
        barStackList.retainWhere(
            (B bar) => !bar.animatingOut && !bar.targetBar!.measureIsNull!);

        if (barStackList.isEmpty) {
          keysToRemove.add(key);
        }
      });

      // When cleaning up the animation, also clean up the keys used to lookup
      // if a bar is selected.
      for (final key in keysToRemove) {
        _barStackMap.remove(key);
        _currentKeys.remove(key);
      }
      _currentGroupsStackKeys.forEach((domain, keys) {
        keys.removeWhere(keysToRemove.contains);
      });
    }

    _barStackMap.forEach((String stackKey, List<B> barStack) {
      // Turn this into a list so that the getCurrentBar isn't called more than
      // once for each animationPercent if the barElements are iterated more
      // than once.
      final barElements = barStack
          .map((B animatingBar) => animatingBar.getCurrentBar(animationPercent))
          .toList();

      if (barElements.isNotEmpty) {
        paintBar(context.canvas, offset, barElements);
      }
    });
  }

  /// Paints a stack of bar elements on the canvas.
  @protected
  void paintBar(
    Canvas canvas,
    Offset offset,
    Iterable<E> barElements,
  );

  @override
  List<DatumDetails<D>> getNearestDatumDetailPerSeries(
    Offset globalPosition,
    bool byDomain,
    Rect? boundsOverride, {
    bool selectOverlappingPoints = false,
    bool selectExactEventLocation = false,
  }) {
    var nearest = <DatumDetails<D>>[];

    final chartPoint = globalToLocal(globalPosition);

    if (!isPointWithinBounds(chartPoint, Offset.zero & size)) {
      return nearest;
    }

    if (_prevDomainAxis is OrdinalAxis) {
      final domainValue = _prevDomainAxis!.getDomain(
        renderingVertically ? chartPoint.dx : chartPoint.dy,
      );

      // If we have a domainValue for the event point, then find all segments
      // that match it.
      if (domainValue != null) {
        if (renderingVertically) {
          nearest =
              _getVerticalDetailsForDomainValue(domainValue, chartPoint);
        } else {
          nearest =
              _getHorizontalDetailsForDomainValue(domainValue, chartPoint);
        }
      }
    } else {
      if (renderingVertically) {
        nearest = _getVerticalDetailsForDomainValue(null, chartPoint);
      } else {
        nearest = _getHorizontalDetailsForDomainValue(null, chartPoint);
      }

      // Find the closest domain and only keep values that match the domain.
      double minRelativeDistance = double.maxFinite;
      double minDomainDistance = double.maxFinite;
      double minMeasureDistance = double.maxFinite;
      D? nearestDomain;

      // TODO: Optimize this with a binary search based on chartX.
      for (final detail in nearest) {
        if (byDomain) {
          if (detail.domainDistance! < minDomainDistance ||
              (detail.domainDistance! == minDomainDistance &&
                  detail.measureDistance! < minMeasureDistance)) {
            minDomainDistance = detail.domainDistance!;
            minMeasureDistance = detail.measureDistance!;
            nearestDomain = detail.domain;
          }
        } else {
          if (detail.relativeDistance! < minRelativeDistance) {
            minRelativeDistance = detail.relativeDistance!;
            nearestDomain = detail.domain;
          }
        }
      }

      nearest.retainWhere((d) => d.domain == nearestDomain);
    }

    // Note: the details are already sorted by domain & measure distance in
    // base chart.
    return nearest;
  }

  @protected
  Rect? getBoundsForBar(E bar);

  @protected
  List<BaseAnimatedBar<D, E>> _getSegmentsForDomainValue(
    D? domainValue, {
    bool Function(BaseAnimatedBar<D, E> bar)? where,
  }) {
    final matchingSegments = <BaseAnimatedBar<D, E>>[];

    // [domainValue] is null only when the bar renderer is being used with in
    // a non ordinal axis (ex. date time axis).
    //
    // In the case of null [domainValue] return all values to be compared, since
    // we can't use the optimized comparison for [OrdinalAxis].
    final stackKeys = (domainValue != null)
        ? _currentGroupsStackKeys[domainValue]
        : _currentGroupsStackKeys.values
            .reduce((allKeys, keys) => allKeys..addAll(keys));
    stackKeys?.forEach((String stackKey) {
      if (where != null) {
        matchingSegments.addAll(_barStackMap[stackKey]!.where(where));
      } else {
        matchingSegments.addAll(_barStackMap[stackKey]!);
      }
    });

    return matchingSegments;
  }

  // In the case of null [domainValue] return all values to be compared, since
  // we can't use the optimized comparison for [OrdinalAxis].
  List<DatumDetails<D>> _getVerticalDetailsForDomainValue(
    D? domainValue,
    Offset chartPoint,
  ) {
    return List<DatumDetails<D>>.from(_getSegmentsForDomainValue(domainValue,
            where: (BaseAnimatedBar<D, E> bar) => !bar.series.overlaySeries)
        .map<DatumDetails<D>>((BaseAnimatedBar<D, E> bar) {
      final barBounds = getBoundsForBar(bar.currentBar!)!;
      final segmentDomainDistance = _getDistance(
        chartPoint.dx.toDouble(),
        barBounds.left,
        barBounds.right,
      );
      final segmentMeasureDistance = _getDistance(
        chartPoint.dy.toDouble(),
        barBounds.top,
        barBounds.bottom,
      );

      final nearestPoint = Offset(
        chartPoint.dx.clamp(barBounds.left, barBounds.right).toDouble(),
        chartPoint.dy.clamp(barBounds.top, barBounds.bottom).toDouble(),
      );

      final relativeDistance = Point(chartPoint.dx, chartPoint.dy).distanceTo(
        Point(
          nearestPoint.dx,
          nearestPoint.dy,
        ),
      );

      return DatumDetails<D>(
        series: bar.series,
        datum: bar.datum,
        domain: bar.domainValue,
        domainDistance: segmentDomainDistance,
        measureDistance: segmentMeasureDistance,
        relativeDistance: relativeDistance,
      );
    }));
  }

  List<DatumDetails<D>> _getHorizontalDetailsForDomainValue(
    D? domainValue,
    Offset chartPoint,
  ) {
    return List<DatumDetails<D>>.from(_getSegmentsForDomainValue(domainValue,
            where: (BaseAnimatedBar<D, E> bar) => !bar.series.overlaySeries)
        .map<DatumDetails<D>>((BaseAnimatedBar<D, E> bar) {
      final barBounds = getBoundsForBar(bar.currentBar!)!;
      final segmentDomainDistance = _getDistance(
        chartPoint.dy.roundToDouble(),
        barBounds.top,
        barBounds.bottom,
      );
      final segmentMeasureDistance = _getDistance(
        chartPoint.dx.roundToDouble(),
        barBounds.left,
        barBounds.right,
      );

      return DatumDetails<D>(
        series: bar.series,
        datum: bar.datum,
        domain: bar.domainValue,
        domainDistance: segmentDomainDistance,
        measureDistance: segmentMeasureDistance,
      );
    }));
  }

  double _getDistance(double point, double min, double max) {
    if (max >= point && min <= point) {
      return 0.0;
    }
    return (point > max ? (point - max) : (min - point)).toDouble();
  }

  /// Gets the iterator for the series based grouped/stacked and orientation.
  ///
  /// For vertical stacked bars:
  /// * If grouped, return the iterator that keeps the category order but
  /// reverse the order of the series so the first series is on the top of the
  /// stack.
  /// * Otherwise, return iterator of the reversed list
  ///
  /// All other types, use the in order iterator.
  @protected
  Iterable<T> getOrderedSeriesList<T extends ImmutableSeries<D>>(
      List<T> seriesList) {
    return (renderingVertically && config.stacked)
        ? config.grouped
            ? _ReversedSeriesIterable(seriesList)
            : seriesList.reversed
        : seriesList;
  }

  bool get isRtl => chart.isRTL;
}

/// Iterable wrapping the seriesList that returns the ReversedSeriesItertor.
class _ReversedSeriesIterable<S extends ImmutableSeries<Object?>>
    extends Iterable<S> {
  _ReversedSeriesIterable(this.seriesList);

  final List<S> seriesList;

  @override
  Iterator<S> get iterator => _ReversedSeriesIterator(seriesList);
}

/// Iterator that keeps reverse series order but keeps category order.
///
/// This is needed because for grouped stacked bars, the category stays in the
/// order it was passed in for the grouping, but the series is flipped so that
/// the first series of that category is on the top of the stack.
class _ReversedSeriesIterator<S extends ImmutableSeries<Object?>>
    implements Iterator<S> {
  _ReversedSeriesIterator(List<S> list) : _list = list {
    // In the order of the list, save the category and the indices of the series
    // with the same category.
    final categoryAndSeriesIndexMap = <String?, List<int>>{};
    for (int i = 0; i < list.length; i += 1) {
      categoryAndSeriesIndexMap
          .putIfAbsent(list[i].seriesCategory, () => <int>[])
          .add(i);
    }

    // Creates a visit that is categories in order, but the series is reversed.
    categoryAndSeriesIndexMap
        .forEach((_, indices) => _visitIndex.addAll(indices.reversed));
  }

  final List<S> _list;
  final _visitIndex = <int>[];
  int? _current;

  @override
  bool moveNext() {
    _current = (_current == null) ? 0 : _current! + 1;

    return _current! < _list.length;
  }

  @override
  S get current => _list[_visitIndex[_current!]];
}
