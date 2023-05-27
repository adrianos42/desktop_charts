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

import 'dart:math';

import 'package:desktop/desktop.dart';
import 'package:desktop_charts/desktop_charts.dart' as charts;

import '../../defaults.dart';

class SimpleLineRangeAnnotationChartBuilder extends ExampleBuilder {
  const SimpleLineRangeAnnotationChartBuilder();

  @override
  String? get subtitle => SimpleLineRangeAnnotationChart.subtitle;

  @override
  String get title => SimpleLineRangeAnnotationChart.title;

  @override
  Widget withSampleData([bool animate = true]) =>
      SimpleLineRangeAnnotationChart.withSampleData(animate);

  @override
  Widget withData(dynamic data, [bool animate = true]) =>
      SimpleLineRangeAnnotationChart(
        data as List<charts.Series<dynamic, num>>,
        animate: animate,
      );

  @override
  dynamic generateRandomData() =>
      SimpleLineRangeAnnotationChart.createRandomData();

  @override
  bool get hasParent => true;

  @override
  String get parentTitle => 'Range Annotation';
}

/// Line chart with range annotations example.
class SimpleLineRangeAnnotationChart extends StatelessWidget {
  const SimpleLineRangeAnnotationChart(
    this.seriesList, {
    this.animate = true,
    super.key,
  });

  /// Creates a [LineChart] with sample data and range annotations.
  ///
  /// The second annotation extends beyond the range of the series data,
  /// demonstrating the effect of the [Charts.RangeAnnotation.extendAxis] flag.
  /// This can be set to false to disable range extension.
  factory SimpleLineRangeAnnotationChart.withSampleData([bool animate = true]) {
    return SimpleLineRangeAnnotationChart(
      createSampleData(),
      animate: animate,
    );
  }

  static String get title => 'Range Annotation';
  static String? get subtitle => 'Line chart with range annotations';

  final List<charts.Series<dynamic, num>> seriesList;
  final bool animate;

  /// Create random data.
  static List<charts.Series<LinearSales, int>> createRandomData() {
    final random = Random();

    final data = [
      LinearSales(0, random.nextInt(100)),
      LinearSales(1, random.nextInt(100)),
      LinearSales(2, random.nextInt(100)),
      // Fix one of the points to 100 so that the annotations are consistently
      // placed.
      const LinearSales(3, 100),
    ];

    return [
      charts.Series<LinearSales, int>(
        id: 'Sales',
        domain: (LinearSales sales, _) => sales.year,
        measure: (LinearSales sales, _) => sales.sales,
        data: data,
      )
    ];
  }

  /// Create one series with sample hard coded data.
  static List<charts.Series<LinearSales, int>> createSampleData() {
    const data = [
      LinearSales(0, 5),
      LinearSales(1, 25),
      LinearSales(2, 100),
      LinearSales(3, 75),
    ];

    return [
      charts.Series<LinearSales, int>(
        id: 'Sales',
        domain: (LinearSales sales, _) => sales.year,
        measure: (LinearSales sales, _) => sales.sales,
        data: data,
      )
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return charts.LineChart(
      seriesList,
      animate: animate,
      behaviors: [
        charts.RangeAnnotation(
          [
            charts.RangeAnnotationSegment(
              0.5,
              1.0,
              charts.RangeAnnotationAxisType.domain,
              startLabel: 'Domain 1',
              color: colorScheme.background[4],
            ),
            charts.RangeAnnotationSegment(
              2,
              4,
              charts.RangeAnnotationAxisType.domain,
              endLabel: 'Domain 2',
              color: colorScheme.background[8],
            ),
            charts.RangeAnnotationSegment(
              15,
              20,
              charts.RangeAnnotationAxisType.measure,
              startLabel: 'Measure 1 Start',
              endLabel: 'Measure 1 End',
              color: colorScheme.background[12],
            ),
            charts.RangeAnnotationSegment(
              35,
              65,
              charts.RangeAnnotationAxisType.measure,
              startLabel: 'Measure 2 Start',
              endLabel: 'Measure 2 End',
              color: colorScheme.background[16],
            ),
          ],
        ),
      ],
    );
  }
}

/// Sample linear data type.
@immutable
class LinearSales {
  const LinearSales(this.year, this.sales);

  final int year;
  final int sales;
}
