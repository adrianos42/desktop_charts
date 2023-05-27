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

class SimpleStackedBarChartBuilder extends ExampleBuilder {
  const SimpleStackedBarChartBuilder();

  @override
  String? get subtitle => SimpleStackedBarChart.subtitle;

  @override
  String get title => SimpleStackedBarChart.title;

  @override
  Widget withSampleData([bool animate = true]) =>
      SimpleStackedBarChart.withSampleData(animate);

  @override
  Widget withData(dynamic data, [bool animate = true]) => SimpleStackedBarChart(
        data as List<charts.Series<dynamic, String>>,
        animate: animate,
      );

  @override
  dynamic generateRandomData() => SimpleStackedBarChart.createRandomData();

  @override
  bool get hasParent => true;

  @override
  String get parentTitle => 'Stacked';
}

/// Bar chart example
class SimpleStackedBarChart extends StatelessWidget {
  const SimpleStackedBarChart(
    this.seriesList, {
    this.animate = true,
    super.key,
  });

  /// Creates a stacked [BarChart] with sample data and no transition.
  factory SimpleStackedBarChart.withSampleData([bool animate = true]) {
    return SimpleStackedBarChart(
      createSampleData(),
      animate: animate,
    );
  }

  static String get title => 'Simple';
  static String? get subtitle => 'Stacked bar chart with multiple series';

  final List<charts.Series<dynamic, String>> seriesList;
  final bool animate;

  /// Create random data.
  static List<charts.Series<OrdinalSales, String>> createRandomData() {
    final random = Random();

    final desktopSalesData = [
      OrdinalSales('2024', random.nextInt(100)),
      OrdinalSales('2025', random.nextInt(100)),
      OrdinalSales('2026', random.nextInt(100)),
      OrdinalSales('2027', random.nextInt(100)),
    ];

    final tableSalesData = [
      OrdinalSales('2024', random.nextInt(100)),
      OrdinalSales('2025', random.nextInt(100)),
      OrdinalSales('2026', random.nextInt(100)),
      OrdinalSales('2027', random.nextInt(100)),
    ];

    final mobileSalesData = [
      OrdinalSales('2024', random.nextInt(100)),
      OrdinalSales('2025', random.nextInt(100)),
      OrdinalSales('2026', random.nextInt(100)),
      OrdinalSales('2027', random.nextInt(100)),
    ];

    return [
      charts.Series<OrdinalSales, String>(
        id: 'Desktop',
        domain: (OrdinalSales sales, _) => sales.year,
        measure: (OrdinalSales sales, _) => sales.sales,
        data: desktopSalesData,
      ),
      charts.Series<OrdinalSales, String>(
        id: 'Tablet',
        domain: (OrdinalSales sales, _) => sales.year,
        measure: (OrdinalSales sales, _) => sales.sales,
        data: tableSalesData,
      ),
      charts.Series<OrdinalSales, String>(
        id: 'Mobile',
        domain: (OrdinalSales sales, _) => sales.year,
        measure: (OrdinalSales sales, _) => sales.sales,
        data: mobileSalesData,
      ),
    ];
  }

  /// Create series list with multiple series
  static List<charts.Series<OrdinalSales, String>> createSampleData() {
    const desktopSalesData = [
      OrdinalSales('2024', 5),
      OrdinalSales('2025', 25),
      OrdinalSales('2026', 100),
      OrdinalSales('2027', 75),
    ];

    const tableSalesData = [
      OrdinalSales('2024', 25),
      OrdinalSales('2025', 50),
      OrdinalSales('2026', 10),
      OrdinalSales('2027', 20),
    ];

    const mobileSalesData = [
      OrdinalSales('2024', 10),
      OrdinalSales('2025', 15),
      OrdinalSales('2026', 50),
      OrdinalSales('2027', 45),
    ];

    return [
      charts.Series<OrdinalSales, String>(
        id: 'Desktop',
        domain: (OrdinalSales sales, _) => sales.year,
        measure: (OrdinalSales sales, _) => sales.sales,
        data: desktopSalesData,
      ),
      charts.Series<OrdinalSales, String>(
        id: 'Tablet',
        domain: (OrdinalSales sales, _) => sales.year,
        measure: (OrdinalSales sales, _) => sales.sales,
        data: tableSalesData,
      ),
      charts.Series<OrdinalSales, String>(
        id: 'Mobile',
        domain: (OrdinalSales sales, _) => sales.year,
        measure: (OrdinalSales sales, _) => sales.sales,
        data: mobileSalesData,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return charts.BarChart(
      seriesList,
      animate: animate,
      barGroupingType: charts.BarGroupingType.stacked,
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
