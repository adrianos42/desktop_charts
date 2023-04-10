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

import 'dart:math' show max;
import 'package:collection/collection.dart' show ListEquality;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../data/series.dart' show AttributeKey;
import '../symbol_renderer.dart' show SymbolRenderer;
import 'base_chart.dart' show BaseChart, BaseChartState;
import 'datum_details.dart' show DatumDetails;
import 'layout/layout_view.dart'
    show
        LayoutPosition,
        LayoutViewMixin,
        LayoutViewConfig,
        LayoutViewPositionOrder;
import 'processed_series.dart' show MutableSeries;
import 'series_datum.dart' show SeriesDatum;

/// Unique identifier used to associate custom series renderers on a chart with
/// one or more series of data.
///
/// [rendererIdKey] can be added as an attribute to user-defined [Series]
/// objects.
const rendererIdKey = AttributeKey<String>('SeriesRenderer.rendererId');

const rendererKey =
    AttributeKey<SeriesRenderer<dynamic, dynamic>>('SeriesRenderer.renderer');

abstract class SeriesRenderer<D, S extends BaseChart<D>> extends RenderBox
    with LayoutViewMixin {
  SeriesRenderer({
    required this.rendererId,
    required BaseChartState<D, S> chartState,
    required List<MutableSeries<D>> seriesList,
    this.symbolRenderer,
  })  : _chartState = chartState,
        _seriesList = seriesList {
    configure();
  }

  /// Symbol renderer for this renderer.
  ///
  /// The default is set natively by the platform. This is because in Flutter,
  /// the [SymbolRenderer] has to be a Flutter wrapped version to support
  /// building widget based symbols.
  final SymbolRenderer? symbolRenderer;

  BaseChartState<D, S> _chartState;

  BaseChartState<D, S> get chartState => _chartState;
  set chartState(BaseChartState<D, S> value) {
    if (_chartState != value) {
      _chartState = value;
      markNeedsLayout();
    }
  }

  List<MutableSeries<D>> _seriesList = [];
  List<MutableSeries<D>> get seriesList => _seriesList;
  set seriesList(List<MutableSeries<D>> value) {
    if (value != _seriesList ||
        !ListEquality<MutableSeries<D>>().equals(value, _seriesList)) {
      _seriesList = value;
      configure();
      markNeedsLayout();
    }
  }

  @protected
  @mustCallSuper
  void configure() {
    configureSeries();
    preprocessSeries();
  }

  @mustCallSuper
  void update(Offset offset) {}

  @mustCallSuper
  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    chartState.animationController.addListener(markNeedsPaint);
  }

  @mustCallSuper
  @override
  void detach() {
    chartState.animationController.removeListener(markNeedsPaint);
    super.detach();
  }

  @mustCallSuper
  @override
  void paint(PaintingContext context, Offset offset);

  static const defaultRendererId = 'default';

  /// Unique identifier for this renderer. Any [Series] on a chart with a
  /// matching  [rendererIdKey] will be drawn by this renderer.
  final String rendererId;

  /// Performs basic configuration for the series, before it is pre-processed.
  ///
  /// Typically, a series renderer should assign color mapping functions to
  /// series that do not have them.
  void configureSeries();

  /// Pre-calculates some details for the series that will be needed later
  /// during the drawing phase.
  void preprocessSeries();

  /// Adds the domain values for the given series to the chart's domain axis.
  void configureDomainAxes();

  /// Adds the measure values for the given series to the chart's measure axes.
  void configureMeasureAxes();

  /// Generates rendering data needed to paint the data on the chart.
  ///
  /// This is called during the post layout phase of the chart draw cycle.
  // void update(List<ImmutableSeries<D>> seriesList, bool isAnimating);

  /// Gets a list of the data from each series that is closest to a given point.
  ///
  /// [chartPoint] represents a point in the chart, such as a point that was
  /// clicked/tapped on by a user.
  ///
  /// [selectOverlappingPoints] specifies whether to include all points that
  /// overlap the tapped position in the result. If specified, the method will
  /// return either the closest point or all the overlapping points with the
  /// tapped position.
  ///
  /// [byDomain] specifies whether the nearest data should be defined by domain
  /// distance, or relative Cartesian distance.
  ///
  /// [boundsOverride] optionally specifies a bounding box for the selection
  /// event. If specified, then no data should be returned if [chartPoint] lies
  /// outside the box. If not specified, then each series renderer on the chart
  /// will use its own component bounds for filtering out selection events
  /// (usually the chart draw area).
  List<DatumDetails<D>> getNearestDatumDetailPerSeries(
    Offset chartPoint,
    bool byDomain,
    Rect? boundsOverride, {
    bool selectOverlappingPoints = false,
    bool selectExactEventLocation = false,
  });

  /// Get an expanded set of processed [DatumDetails] for a given [SeriesDatum].
  ///
  /// This is typically called by chart behaviors that need to get full details
  /// on selected data.
  DatumDetails<D> getDetailsForSeriesDatum(SeriesDatum<D> seriesDatum);

  /// Adds chart position data to [details].
  ///
  /// This is a helper function intended to be called from
  /// [getDetailsForSeriesDatum]. Every concrete [SeriesRendererState] needs to
  /// implement custom logic for setting location data.
  DatumDetails<D> addPositionToDetailsForSeriesDatum(
    DatumDetails<D> details,
    SeriesDatum<D> seriesDatum,
  );
}

/// Concrete base class for [SeriesRendererState]s that implements common
/// functionality.
abstract class BaseSeriesRenderer<D, S extends BaseChart<D>>
    extends SeriesRenderer<D, S> {
  BaseSeriesRenderer({
    required int layoutPaintOrder,
    this.symbolRenderer,
    required super.rendererId,
    required super.chartState,
    required super.seriesList,
  }) : layoutConfig = LayoutViewConfig(
          paintOrder: layoutPaintOrder,
          position: LayoutPosition.drawArea,
          positionOrder: LayoutViewPositionOrder.drawArea,
        );

  final LayoutViewConfig layoutConfig;

  final SymbolRenderer? symbolRenderer;

  /// Assigns colors to series that are missing their colorFn.
  ///
  /// [emptyCategoryUsesSinglePalette] Flag indicating whether having all
  ///     series with no categories will use the same or separate palettes.
  ///     Setting it to true uses various Blues for each series.
  ///     Setting it to false used different palettes (ie: s1 uses Blue500,
  ///     s2 uses Red500),
  @protected
  void assignMissingColors(
    Iterable<MutableSeries<D>> seriesList, {
    required bool emptyCategoryUsesSinglePalette,
  }) {
    const defaultCategory = '__default__';

    // Count up the number of missing series per category, keeping a max across
    // categories.
    final missingColorCountPerCategory = <String, int>{};
    int maxMissing = 0;
    bool hasSpecifiedCategory = false;

    for (final series in seriesList) {
      // Assign the seriesColor as the color of every datum if no colorFn was
      // provided.
      if (series.colorFn == null && series.seriesColor != null) {
        series.colorFn = (_) => series.seriesColor!;
      }

      // This series was missing both seriesColor and a colorFn. Add it to the
      // "missing" set.
      if (series.colorFn == null) {
        // If there is no category, give it a default category to match logic.
        String? category = series.seriesCategory;
        if (category == null) {
          category = defaultCategory;
        } else {
          hasSpecifiedCategory = true;
        }

        // Increment the missing counts for the category.
        final missingCnt = (missingColorCountPerCategory[category] ?? 0) + 1;
        missingColorCountPerCategory[category] = missingCnt;
        maxMissing = max(maxMissing, missingCnt);
      }
    }

    if (maxMissing > 0) {
      // Special handling of only series with empty categories when we want
      // to use different palettes.
      if (!emptyCategoryUsesSinglePalette && !hasSpecifiedCategory) {
        final palettes = chartState.themeData.getOrderedPalettes(maxMissing);
        int index = 0;

        for (final series in seriesList) {
          if (series.colorFn == null) {
            final color = palettes[index % palettes.length].shadeDefault;
            index += 1;
            series.colorFn = (_) => color;
            series.seriesColor ??= color;
          } else {
            // Fill in missing seriesColor values with the color of the first
            // datum in the series. Note that [Series.colorFn] should always
            // return a color.
            if (series.seriesColor == null) {
              try {
                series.seriesColor = series.colorFn!(0);
              } catch (exception) {
                series.seriesColor = chartState.themeData.defaultSeriesColor;
              }
            }
          }
        }

        return;
      }

      // Get a list of palettes to use given the number of categories we've
      // seen. One palette per category (but might need to repeat).
      final colorPalettes = chartState.themeData
          .getOrderedPalettes(missingColorCountPerCategory.length);

      // Create a map of Color palettes for each category. Each Palette uses
      // the max for any category to ensure that the gradients look appropriate.
      final colorsByCategory = <String, List<Color>>{};
      int index = 0;

      for (final category in missingColorCountPerCategory.keys) {
        colorsByCategory[category] =
            colorPalettes[index % colorPalettes.length].makeShades(maxMissing);
        index += 1;

        // Reset the count so we can use it to count as we set the colorFn.
        missingColorCountPerCategory[category] = 0;
      }

      for (final series in seriesList) {
        if (series.colorFn == null) {
          final category = series.seriesCategory ?? defaultCategory;

          // Get the current index into the color list.
          final colorIndex = missingColorCountPerCategory[category]!;
          missingColorCountPerCategory[category] = colorIndex + 1;

          final color = colorsByCategory[category]![colorIndex];
          series.colorFn = (_) => color;
        }

        // Fill color defaults to the series color if no accessor is provided.
        series.fillColorFn ??= (int? index) => series.colorFn!(index);
      }
    } else {
      for (final series in seriesList) {
        // Fill color defaults to the series color if no accessor is provided.
        series.fillColorFn ??= (int? index) => series.colorFn!(index);
      }
    }

    // Fill in any missing seriesColor values with the color of the first datum
    // in the series. Note that [Series.colorFn] should always return a color.
    for (final series in seriesList) {
      if (series.seriesColor == null) {
        try {
          series.seriesColor = series.colorFn!(0);
        } catch (exception) {
          series.seriesColor = chartState.themeData.defaultSeriesColor;
        }
      }
    }
  }

  @override
  bool get isSeriesRenderer => true;

  @override
  void configureSeries() {}

  @override
  void preprocessSeries() {}

  @override
  void configureDomainAxes() {}

  @override
  void configureMeasureAxes() {}

  @override
  DatumDetails<D> getDetailsForSeriesDatum(SeriesDatum<D> seriesDatum) {
    // Generate details relevant to every type of series renderer. Position
    // details are left as an exercise for every renderer that extends this
    // class.
    final series = seriesDatum.series;
    final index = seriesDatum.index;
    final domainFn = series.domainFn;
    final domainLowerBoundFn = series.domainLowerBoundFn;
    final domainUpperBoundFn = series.domainUpperBoundFn;
    final measureFn = series.measureFn;
    final measureLowerBoundFn = series.measureLowerBoundFn;
    final measureUpperBoundFn = series.measureUpperBoundFn;
    final measureOffsetFn = series.measureOffsetFn;
    final rawMeasureFn = series.rawMeasureFn;
    final rawMeasureLowerBoundFn = series.rawMeasureLowerBoundFn;
    final rawMeasureUpperBoundFn = series.rawMeasureUpperBoundFn;
    final colorFn = series.colorFn;
    final areaColorFn = series.areaColorFn ?? colorFn;
    final fillColorFn = series.fillColorFn ?? colorFn;
    final radiusFn = series.radiusFn;
    final strokeWidthFn = series.strokeWidthFn;

    final domainValue = domainFn(index);
    final domainLowerBoundValue = domainLowerBoundFn?.call(index);
    final domainUpperBoundValue = domainUpperBoundFn?.call(index);

    final measureValue = measureFn(index);
    final measureLowerBoundValue = measureLowerBoundFn?.call(index);
    final measureUpperBoundValue = measureUpperBoundFn?.call(index);
    final measureOffsetValue = measureOffsetFn?.call(index);

    final rawMeasureValue = rawMeasureFn(index);
    final rawMeasureLowerBoundValue = rawMeasureLowerBoundFn?.call(index);
    final rawMeasureUpperBoundValue = rawMeasureUpperBoundFn?.call(index);

    final color = colorFn!(index);

    // Fill color is an optional override for color. Make sure we get a value if
    // the series doesn't define anything specific.
    Color? fillColor = fillColorFn!(index);
    fillColor ??= color;

    // Area color is entirely optional.
    final areaColor = areaColorFn!(index);

    double? radius = radiusFn?.call(index)?.toDouble();
    radius = radius?.toDouble();

    double? strokeWidth = strokeWidthFn?.call(index)?.toDouble();
    strokeWidth = strokeWidth?.toDouble();

    final details = DatumDetails<D>(
      datum: seriesDatum.datum,
      index: seriesDatum.index,
      domain: domainValue,
      domainLowerBound: domainLowerBoundValue,
      domainUpperBound: domainUpperBoundValue,
      measure: measureValue,
      measureLowerBound: measureLowerBoundValue,
      measureUpperBound: measureUpperBoundValue,
      measureOffset: measureOffsetValue,
      rawMeasure: rawMeasureValue,
      rawMeasureLowerBound: rawMeasureLowerBoundValue,
      rawMeasureUpperBound: rawMeasureUpperBoundValue,
      series: series,
      color: color,
      fillColor: fillColor,
      areaColor: areaColor,
      radius: radius,
      strokeWidth: strokeWidth,
    );

    // chartPosition depends on the shape of the rendered elements, and must be
    // added by concrete [SeriesRenderer] classes.
    return addPositionToDetailsForSeriesDatum(details, seriesDatum);
  }

  /// Returns true of [chartPoint] is within the component bounds for this
  /// renderer.
  ///
  /// [chartPoint] a point to test.
  ///
  /// [bounds] optional override for component bounds. If this is passed, then
  /// we will check whether the point is within these bounds instead of the
  /// component bounds.
  bool isPointWithinBounds(Offset chartPoint, Rect bounds) {
    // Was it even in the drawArea?
    return bounds.contains(chartPoint);
  }

  @override
  void performLayout() {
    chartState.requestAnimation(); // TODO
    size = constraints.biggest;
  }
}
