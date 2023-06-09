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

class PercentOfSeriesBarChartBuilder extends ExampleBuilder {
  const PercentOfSeriesBarChartBuilder();

  @override
  String? get subtitle => PercentOfSeriesBarChart.subtitle;

  @override
  String get title => PercentOfSeriesBarChart.title;

  @override
  Widget withSampleData([bool animate = true]) =>
      PercentOfSeriesBarChart.withSampleData(animate);

  @override
  Widget withData(dynamic data, [bool animate = true]) =>
      PercentOfSeriesBarChart(
        data as List<charts.Series<dynamic, String>>,
        animate: animate,
      );

  @override
  dynamic generateRandomData() => PercentOfSeriesBarChart.createRandomData();

  @override
  bool get hasParent => true;

  @override
  String get parentTitle => 'Percent';
}

/// Example of a percentage bar chart which shows each bar as the percentage of
/// the total series measure value.
class PercentOfSeriesBarChart extends StatelessWidget {
  const PercentOfSeriesBarChart(
    this.seriesList, {
    this.animate = true,
    super.key,
  });

  /// Creates a stacked [BarChart] with sample data and no transition.
  factory PercentOfSeriesBarChart.withSampleData([bool animate = true]) {
    return PercentOfSeriesBarChart(
      createSampleData(),
      animate: animate,
    );
  }

  static String get title => 'Series';
  static String? get subtitle =>
      'Grouped bar chart with measures calculated as percent of series';

  final List<charts.Series<dynamic, String>> seriesList;
  final bool animate;

  /// Create random data.
  static List<charts.Series<OrdinalSales, String>> createRandomData() {
    final random = Random();

    final desktopSalesData = [
      OrdinalSales('2014', random.nextInt(100)),
      OrdinalSales('2015', random.nextInt(100)),
      OrdinalSales('2016', random.nextInt(100)),
      OrdinalSales('2017', random.nextInt(100)),
      OrdinalSales('2014', random.nextInt(100)),
      OrdinalSales('2015', random.nextInt(100)),
      OrdinalSales('2016', random.nextInt(100)),
      OrdinalSales('2017', random.nextInt(100)),
    ];

    return [
      charts.Series<OrdinalSales, String>(
        id: 'Desktop',
        domain: (OrdinalSales sales, _) => sales.year,
        measure: (OrdinalSales sales, _) => sales.sales,
        data: desktopSalesData,
      ),
    ];
  }

  /// Create series list with multiple series
  static List<charts.Series<OrdinalSales, String>> createSampleData() {
    const desktopSalesData = [
      OrdinalSales('2011', 5),
      OrdinalSales('2012', 25),
      OrdinalSales('2013', 50),
      OrdinalSales('2014', 75),
      OrdinalSales('2015', 100),
      OrdinalSales('2016', 125),
      OrdinalSales('2017', 200),
      OrdinalSales('2018', 150),
    ];

    return [
      charts.Series<OrdinalSales, String>(
        id: 'Desktop',
        domain: (OrdinalSales sales, _) => sales.year,
        measure: (OrdinalSales sales, _) => sales.sales,
        data: desktopSalesData,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return charts.BarChart(
      seriesList,
      animate: animate,
      barGroupingType: charts.BarGroupingType.grouped,
      // Configures a [PercentInjector] behavior that will calculate measure
      // values as the percentage of the total of all data in its series.
      behaviors: const [
        charts.PercentInjector(
          totalType: charts.PercentInjectorTotalType.series,
        )
      ],
      // Configure the axis spec to show percentage values.
      primaryMeasureAxis: charts.PercentAxisSpec(),
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
