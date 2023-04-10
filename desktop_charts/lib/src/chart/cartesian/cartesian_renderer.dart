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

import 'package:flutter/foundation.dart';

import '../../data/series.dart' show Accessor;
import '../base_chart.dart' show BaseChart;
import '../processed_series.dart' show MutableSeries;
import '../series_renderer.dart' show BaseSeriesRenderer;
import 'axis/axis.dart' show CartesianAxis, measureAxisIdKey;
import 'cartesian_chart.dart' show CartesianChartState, CartesianChart;

abstract class BaseCartesianRenderer<D, S extends BaseChart<D>>
    extends BaseSeriesRenderer<D, S> {
  BaseCartesianRenderer({
    required super.chartState,
    required super.rendererId,
    required super.layoutPaintOrder,
    required super.seriesList,
    super.symbolRenderer,
  });

  CartesianChartState<D, CartesianChart<D>> get chart =>
      chartState as CartesianChartState<D, CartesianChart<D>>;

  // True when the chart should be rendered in vertical mode, false when in
  // horizontal mode.
  bool get renderingVertically => chart.widget.isVertical;

  @override
  void configure() {
    super.configure();

    configureDomainAxes();
    configureMeasureAxes();
  }

  @override
  void configureDomainAxes() {
    for (final series in seriesList) {
      if (series.data.isEmpty) {
        break;
      }

      final domainAxis =
          (chartState as CartesianChartState<D, CartesianChart<D>>).domainAxis;
      final domainFn = series.domainFn;
      final domainLowerBoundFn = series.domainLowerBoundFn;
      final domainUpperBoundFn = series.domainUpperBoundFn;

      if (domainAxis == null) {
        break;
      }

      if (renderingVertically) {
        for (int i = 0; i < series.data.length; i += 1) {
          domainAxis.addDomainValue(domainFn(i)!);

          if (domainLowerBoundFn != null && domainUpperBoundFn != null) {
            final domainLowerBound = domainLowerBoundFn(i);
            final domainUpperBound = domainUpperBoundFn(i);
            if (domainLowerBound != null && domainUpperBound != null) {
              domainAxis.addDomainValue(domainLowerBound);
              domainAxis.addDomainValue(domainUpperBound);
            }
          }
        }
      } else {
        // When rendering horizontally, domains are displayed from top to bottom
        // in order to match visual display in legend.
        for (int i = series.data.length - 1; i >= 0; i -= 1) {
          domainAxis.addDomainValue(domainFn(i)!);

          if (domainLowerBoundFn != null && domainUpperBoundFn != null) {
            final domainLowerBound = domainLowerBoundFn(i);
            final domainUpperBound = domainUpperBoundFn(i);
            if (domainLowerBound != null && domainUpperBound != null) {
              domainAxis.addDomainValue(domainLowerBound);
              domainAxis.addDomainValue(domainUpperBound);
            }
          }
        }
      }
    }
  }

  @override
  void configureMeasureAxes() {
    for (final series in seriesList) {
      if (series.data.isEmpty) {
        break;
      }

      final domainAxis =
          (chartState as CartesianChartState<D, CartesianChart<D>>).domainAxis;
      final domainFn = series.domainFn;

      if (domainAxis == null) {
        break;
      }

      final measureAxis =
          (chartState as CartesianChartState<D, CartesianChart<D>>)
              .getMeasureAxis(axisId: series.getAttr(measureAxisIdKey));

      // Only add the measure values for datum who's domain is within the
      // domainAxis viewport.
      final startIndex =
          findNearestViewportStart(domainAxis, domainFn, series.data);
      final endIndex =
          findNearestViewportEnd(domainAxis, domainFn, series.data);

      addMeasureValuesFor(series, measureAxis, startIndex, endIndex);
    }
  }

  void addMeasureValuesFor(
    MutableSeries<D> series,
    CartesianAxis<num> measureAxis,
    int startIndex,
    int endIndex,
  ) {
    final measureFn = series.measureFn;
    final measureOffsetFn = series.measureOffsetFn!;
    final measureLowerBoundFn = series.measureLowerBoundFn;
    final measureUpperBoundFn = series.measureUpperBoundFn;

    for (int i = startIndex; i <= endIndex; i += 1) {
      final num? measure = measureFn(i);
      final num? measureOffset = measureOffsetFn(i);

      if (measure != null && measureOffset != null) {
        measureAxis.addDomainValue((measure + measureOffset).toDouble());

        if (measureLowerBoundFn != null && measureUpperBoundFn != null) {
          measureAxis.addDomainValue(
              ((measureLowerBoundFn(i) ?? 0.0) + measureOffset).toDouble());
          measureAxis.addDomainValue(
              ((measureUpperBoundFn(i) ?? 0.0) + measureOffset).toDouble());
        }
      }
    }
  }

  @visibleForTesting
  int findNearestViewportStart(
      CartesianAxis<D> domainAxis, Accessor<D> domainFn, List<Object?> data) {
    assert(data.isNotEmpty);

    // Quick optimization for full viewport (likely).
    if (domainAxis.compareDomainValueToViewport(domainFn(0)) == 0) {
      return 0;
    }

    int start = 1; // Index zero was already checked for above.
    int end = data.length - 1;

    // Binary search for the start of the viewport.
    while (end >= start) {
      final searchIndex = ((end - start) / 2).floor() + start;
      final prevIndex = searchIndex - 1;

      final comparisonValue =
          domainAxis.compareDomainValueToViewport(domainFn(searchIndex));
      final prevComparisonValue =
          domainAxis.compareDomainValueToViewport(domainFn(prevIndex));

      // Found start?
      if (prevComparisonValue == -1 && comparisonValue == 0) {
        return searchIndex;
      }

      // Straddling viewport?
      // Return previous index as the nearest start of the viewport.
      if (comparisonValue == 1 && prevComparisonValue == -1) {
        return searchIndex - 1;
      }

      // Before start? Update startIndex
      if (comparisonValue == -1) {
        start = searchIndex + 1;
      } else {
        // Middle or after viewport? Update endIndex
        end = searchIndex - 1;
      }
    }

    // Binary search would reach this point for the edge cases where the domain
    // specified is prior or after the domain viewport.
    // If domain is prior to the domain viewport, return the first index as the
    // nearest viewport start.
    // If domain is after the domain viewport, return the last index as the
    // nearest viewport start.
    final lastComparison =
        domainAxis.compareDomainValueToViewport(domainFn(data.length - 1));
    return lastComparison == 1 ? (data.length - 1) : 0;
  }

  @visibleForTesting
  int findNearestViewportEnd(
      CartesianAxis<D> domainAxis, Accessor<D> domainFn, List<Object?> data) {
    assert(data.isNotEmpty);

    int start = 1;
    int end = data.length - 1;

    // Quick optimization for full viewport (likely).
    if (domainAxis.compareDomainValueToViewport(domainFn(end)) == 0) {
      return end;
    }
    end = end - 1; // Last index was already checked for above.

    // Binary search for the start of the viewport.
    while (end >= start) {
      final searchIndex = ((end - start) / 2).floor() + start;
      final prevIndex = searchIndex - 1;

      final comparisonValue =
          domainAxis.compareDomainValueToViewport(domainFn(searchIndex));
      final prevComparisonValue =
          domainAxis.compareDomainValueToViewport(domainFn(prevIndex));

      // Found end?
      if (prevComparisonValue == 0 && comparisonValue == 1) {
        return prevIndex;
      }

      // Straddling viewport?
      // Return the current index as the start of the viewport.
      if (comparisonValue == 1 && prevComparisonValue == -1) {
        return searchIndex;
      }

      // After end? Update endIndex
      if (comparisonValue == 1) {
        end = searchIndex - 1;
      } else {
        // Middle or before viewport? Update startIndex
        start = searchIndex + 1;
      }
    }

    // Binary search would reach this point for the edge cases where the domain
    // specified is prior or after the domain viewport.
    // If domain is prior to the domain viewport, return the first index as the
    // nearest viewport end.
    // If domain is after the domain viewport, return the last index as the
    // nearest viewport end.
    final lastComparison =
        domainAxis.compareDomainValueToViewport(domainFn(data.length - 1));
    return lastComparison == 1 ? (data.length - 1) : 0;
  }
}
