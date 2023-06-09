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

class SimpleHorizontalBarChartBuilder extends ExampleBuilder {
  const SimpleHorizontalBarChartBuilder();

  @override
  String? get subtitle => SimpleHorizontalBarChart.subtitle;

  @override
  String get title => SimpleHorizontalBarChart.title;

  @override
  Widget withSampleData([bool animate = true]) =>
      SimpleHorizontalBarChart.withSampleData(animate);

  @override
  Widget withData(dynamic data, [bool animate = true]) =>
      SimpleHorizontalBarChart(
        data as List<charts.Series<dynamic, String>>,
        animate: animate,
      );

  @override
  dynamic generateRandomData() => SimpleHorizontalBarChart.createRandomData();

  @override
  bool get hasParent => true;

  @override
  String get parentTitle => 'Horizontal';
}

/// Horizontal bar chart example
class SimpleHorizontalBarChart extends StatelessWidget {
  const SimpleHorizontalBarChart(
    this.seriesList, {
    this.animate = true,
    super.key,
  });

  /// Creates a [BarChart] with sample data and no transition.
  factory SimpleHorizontalBarChart.withSampleData([bool animate = true]) {
    return SimpleHorizontalBarChart(
      createSampleData(),
      animate: animate,
    );
  }

  static String get title => 'Simple';
  static String? get subtitle => 'Horizontal bar chart with a single series';

  final List<charts.Series<dynamic, String>> seriesList;
  final bool animate;

  /// Create random data.
  static List<charts.Series<OrdinalSales, String>> createRandomData() {
    final random = Random();

    final data = [
      OrdinalSales('2014', random.nextInt(100)),
      OrdinalSales('2015', random.nextInt(100)),
      OrdinalSales('2016', random.nextInt(100)),
      OrdinalSales('2017', random.nextInt(100)),
    ];

    return [
      charts.Series<OrdinalSales, String>(
        id: 'Sales',
        domain: (OrdinalSales sales, _) => sales.year,
        measure: (OrdinalSales sales, _) => sales.sales,
        data: data,
      )
    ];
  }

  /// Create one series with sample hard coded data.
  static List<charts.Series<OrdinalSales, String>> createSampleData() {
    const data = [
      OrdinalSales('2014', 5),
      OrdinalSales('2015', 25),
      OrdinalSales('2016', 100),
      OrdinalSales('2017', 75),
    ];

    return [
      charts.Series<OrdinalSales, String>(
        id: 'Sales',
        domain: (OrdinalSales sales, _) => sales.year,
        measure: (OrdinalSales sales, _) => sales.sales,
        data: data,
      )
    ];
  }

  @override
  Widget build(BuildContext context) {
    // For horizontal bar charts, set the [vertical] flag to false.
    return charts.BarChart(
      seriesList,
      animate: animate,
      isVertical: false,
    );
  }
}

/// Sample ordinal data type.
@immutable
class OrdinalSales {
  const OrdinalSales(this.year, this.sales);

  final String year;
  final int sales;
}
