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

/// Bar chart example

import 'dart:math';

import 'package:desktop/desktop.dart';
import 'package:desktop_charts/desktop_charts.dart' as charts;

/// Example of a grouped bar chart with three series, each rendered with
/// different fill colors.
class GroupedFillColorBarChart extends StatelessWidget {
  const GroupedFillColorBarChart(
    this.seriesList, {
    this.animate = true,
    super.key,
  });

  factory GroupedFillColorBarChart.withSampleData([bool animate = true]) {
    return GroupedFillColorBarChart(
      createSampleData(),
      animate: animate,
    );
  }

  // This section is excluded from being copied to the gallery.
  // It is used for creating random series data to demonstrate animation in
  // the example app only.
  factory GroupedFillColorBarChart.withRandomData([bool animate = true]) {
    return GroupedFillColorBarChart(
      createRandomData(),
      animate: animate,
    );
  }

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
    ];

    final tableSalesData = [
      OrdinalSales('2014', random.nextInt(100)),
      OrdinalSales('2015', random.nextInt(100)),
      OrdinalSales('2016', random.nextInt(100)),
      OrdinalSales('2017', random.nextInt(100)),
    ];

    final mobileSalesData = [
      OrdinalSales('2014', random.nextInt(100)),
      OrdinalSales('2015', random.nextInt(100)),
      OrdinalSales('2016', random.nextInt(100)),
      OrdinalSales('2017', random.nextInt(100)),
    ];

    return [
      // Blue bars with a lighter center color.
      charts.Series<OrdinalSales, String>(
        id: 'Desktop',
        domain: (OrdinalSales sales, _) => sales.year,
        measure: (OrdinalSales sales, _) => sales.sales,
        data: desktopSalesData,
        color: (_, __) => charts.DesktopPalette.blue.shadeDefault,
        fillColor: (_, __) => charts.DesktopPalette.blue.shadeDefault,
      ),
      // Solid red bars. Fill color will default to the series color if no
      // fillColor is configured.
      charts.Series<OrdinalSales, String>(
        id: 'Tablet',
        domain: (OrdinalSales sales, _) => sales.year,
        measure: (OrdinalSales sales, _) => sales.sales,
        data: tableSalesData,
        color: (_, __) => charts.DesktopPalette.red.shadeDefault,
      ),
      // Hollow green bars.
      charts.Series<OrdinalSales, String>(
        id: 'Mobile',
        domain: (OrdinalSales sales, _) => sales.year,
        measure: (OrdinalSales sales, _) => sales.sales,
        data: mobileSalesData,
        color: (_, __) => charts.DesktopPalette.green.shadeDefault,
        fillColor: (_, __) => charts.DesktopPalette.transparent,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return charts.BarChart(
      seriesList,
      animate: animate,
      // Configure a stroke width to enable borders on the bars.
      defaultRenderer: const charts.BarRendererConfig(
        groupingType: charts.BarGroupingType.grouped,
        strokeWidth: 2.0,
      ),
    );
  }

  /// Create series list with multiple series
  static List<charts.Series<OrdinalSales, String>> createSampleData() {
    const desktopSalesData = [
      OrdinalSales('2014', 5),
      OrdinalSales('2015', 25),
      OrdinalSales('2016', 100),
      OrdinalSales('2017', 75),
    ];

    const tableSalesData = [
      OrdinalSales('2014', 25),
      OrdinalSales('2015', 50),
      OrdinalSales('2016', 10),
      OrdinalSales('2017', 20),
    ];

    const mobileSalesData = [
      OrdinalSales('2014', 10),
      OrdinalSales('2015', 50),
      OrdinalSales('2016', 50),
      OrdinalSales('2017', 45),
    ];

    return [
      // Blue bars with a lighter center color.
      charts.Series<OrdinalSales, String>(
        id: 'Desktop',
        domain: (OrdinalSales sales, _) => sales.year,
        measure: (OrdinalSales sales, _) => sales.sales,
        data: desktopSalesData,
        color: (_, __) => charts.DesktopPalette.blue.shadeDefault,
        fillColor: (_, __) => charts.DesktopPalette.blue.shadeDefault,
      ),
      // Solid red bars. Fill color will default to the series color if no
      // fillColor is configured.
      charts.Series<OrdinalSales, String>(
        id: 'Tablet',
        measure: (OrdinalSales sales, _) => sales.sales,
        data: tableSalesData,
        color: (_, __) => charts.DesktopPalette.red.shadeDefault,
        domain: (OrdinalSales sales, _) => sales.year,
      ),
      // Hollow green bars.
      charts.Series<OrdinalSales, String>(
        id: 'Mobile',
        domain: (OrdinalSales sales, _) => sales.year,
        measure: (OrdinalSales sales, _) => sales.sales,
        data: mobileSalesData,
        color: (_, __) => charts.DesktopPalette.green.shadeDefault,
        fillColor: (_, __) => charts.DesktopPalette.transparent,
      ),
    ];
  }
}

/// Sample ordinal data type.
@immutable
class OrdinalSales {
  const OrdinalSales(this.year, this.sales);

  final String year;
  final int sales;
}
