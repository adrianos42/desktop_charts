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

/// Example of a time series chart with range annotations configured to render
/// labels in the chart margin area.

import 'dart:math';

import 'package:desktop/desktop.dart';
import 'package:desktop_charts/desktop_charts.dart' as charts;

class TimeSeriesRangeAnnotationMarginChart extends StatelessWidget {
  const TimeSeriesRangeAnnotationMarginChart(
    this.seriesList, {
    this.animate = true,
    super.key,
  });

  /// Creates a [TimeSeriesChart] with sample data and no transition.
  factory TimeSeriesRangeAnnotationMarginChart.withSampleData([
    bool animate = true,
  ]) {
    return TimeSeriesRangeAnnotationMarginChart(
      createSampleData(),
      animate: animate,
    );
  }

  // This section is excluded from being copied to the gallery.
  // It is used for creating random series data to demonstrate animation in
  // the example app only.
  factory TimeSeriesRangeAnnotationMarginChart.withRandomData([
    bool animate = true,
  ]) {
    return TimeSeriesRangeAnnotationMarginChart(
      createRandomData(),
      animate: animate,
    );
  }

  final List<charts.Series<dynamic, DateTime>> seriesList;
  final bool animate;

  /// Create random data.
  static List<charts.Series<TimeSeriesSales, DateTime>> createRandomData() {
    final random = Random();

    final data = [
      TimeSeriesSales(DateTime(2017, 9, 19), random.nextInt(100)),
      TimeSeriesSales(DateTime(2017, 9, 26), random.nextInt(100)),
      TimeSeriesSales(DateTime(2017, 10, 3), random.nextInt(100)),
      // Fix one of the points to 100 so that the annotations are consistently
      // placed.
      TimeSeriesSales(DateTime(2017, 10, 10), 100),
    ];

    return [
      charts.Series<TimeSeriesSales, DateTime>(
        id: 'Sales',
        domain: (TimeSeriesSales sales, _) => sales.time,
        measure: (TimeSeriesSales sales, _) => sales.sales,
        data: data,
      )
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return charts.TimeSeriesChart(seriesList,
        animate: animate,

        // Allow enough space in the left and right chart margins for the
        // annotations.
        // TODO layoutConfig: charts.LayoutConfig(
        // TODO   leftSpec: charts.MarginSpec.fixedPixel(60),
        // TODO   topSpec: charts.MarginSpec.fixedPixel(20),
        // TODO   rightSpec: charts.MarginSpec.fixedPixel(60),
        // TODO   bottomSpec: charts.MarginSpec.fixedPixel(20),
        // TODO ),
        behaviors: [
          // Define one domain and two measure annotations configured to render
          // labels in the chart margins.
          charts.RangeAnnotation([
            charts.RangeAnnotationSegment(
              DateTime(2017, 10, 4),
              DateTime(2017, 10, 15), charts.RangeAnnotationAxisType.domain,
              startLabel: 'D1 Start',
              endLabel: 'D1 End',
              labelAnchor: charts.AnnotationLabelAnchor.end,
              color: colorScheme.background[4],
              // Override the default vertical direction for domain labels.
              labelDirection: charts.AnnotationLabelDirection.horizontal,
            ),
            charts.RangeAnnotationSegment(
              15,
              20,
              charts.RangeAnnotationAxisType.measure,
              startLabel: 'M1 Start',
              endLabel: 'M1 End',
              labelAnchor: charts.AnnotationLabelAnchor.end,
              color: colorScheme.background[8],
            ),
            charts.RangeAnnotationSegment(
              35,
              65,
              charts.RangeAnnotationAxisType.measure,
              startLabel: 'M2 Start',
              endLabel: 'M2 End',
              labelAnchor: charts.AnnotationLabelAnchor.start,
              color: colorScheme.background[12],
            ),
          ], defaultLabelPosition: charts.AnnotationLabelPosition.margin),
        ]);
  }

  /// Create one series with sample hard coded data.
  static List<charts.Series<TimeSeriesSales, DateTime>> createSampleData() {
    final data = [
      TimeSeriesSales(DateTime(2017, 9, 19), 5),
      TimeSeriesSales(DateTime(2017, 9, 26), 25),
      TimeSeriesSales(DateTime(2017, 10, 3), 100),
      TimeSeriesSales(DateTime(2017, 10, 10), 75),
    ];

    return [
      charts.Series<TimeSeriesSales, DateTime>(
        id: 'Sales',
        domain: (TimeSeriesSales sales, _) => sales.time,
        measure: (TimeSeriesSales sales, _) => sales.sales,
        data: data,
      )
    ];
  }
}

/// Sample time series data type.
@immutable
class TimeSeriesSales {
  const TimeSeriesSales(this.time, this.sales);

  final DateTime time;
  final int sales;
}
