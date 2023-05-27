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

class LegendWithMeasuresBuilder extends ExampleBuilder {
  const LegendWithMeasuresBuilder();

  @override
  String? get subtitle => LegendWithMeasures.subtitle;

  @override
  String get title => LegendWithMeasures.title;

  @override
  Widget withSampleData([bool animate = true]) =>
      LegendWithMeasures.withSampleData(animate);

  @override
  Widget withData(dynamic data, [bool animate = true]) => LegendWithMeasures(
        data as List<charts.Series<dynamic, String>>,
        animate: animate,
      );

  @override
  dynamic generateRandomData() => LegendWithMeasures.createRandomData();

  @override
  bool get hasParent => true;

  @override
  String get parentTitle => 'Series';
}

/// Example that shows how to build a series legend that shows measure values
/// when a datum is selected.
///
/// Also shows the option to provide a custom measure formatter.
class LegendWithMeasures extends StatelessWidget {
  const LegendWithMeasures(
    this.seriesList, {
    this.animate = true,
    super.key,
  });

  factory LegendWithMeasures.withSampleData([bool animate = true]) {
    return LegendWithMeasures(
      createSampleData(),
      animate: animate,
    );
  }

  static String get title => 'Measures';
  static String? get subtitle =>
      'Series legend with measures and measure formatting';

  final List<charts.Series<dynamic, String>> seriesList;
  final bool animate;

  /// Create random data.
  static List<charts.Series<OrdinalSales, String>> createRandomData() {
    final random = Random();

    const desktopSalesData = [
      OrdinalSales('2020', 5),
      OrdinalSales('2021', 25),
      OrdinalSales('2022', 100),
      OrdinalSales('2023', 75),
    ];

    final tabletSalesData = [
      OrdinalSales('2020', random.nextInt(100)),
      OrdinalSales('2021', random.nextInt(100)),
      OrdinalSales('2022', random.nextInt(100)),
      OrdinalSales('2023', random.nextInt(100)),
    ];

    final mobileSalesData = [
      OrdinalSales('2020', random.nextInt(100)),
      OrdinalSales('2021', random.nextInt(100)),
      OrdinalSales('2022', random.nextInt(100)),
      OrdinalSales('2023', random.nextInt(100)),
    ];

    final otherSalesData = [
      OrdinalSales('2020', random.nextInt(100)),
      OrdinalSales('2021', random.nextInt(100)),
      OrdinalSales('2022', random.nextInt(100)),
      OrdinalSales('2023', random.nextInt(100)),
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
        data: tabletSalesData,
      ),
      charts.Series<OrdinalSales, String>(
        id: 'Mobile',
        domain: (OrdinalSales sales, _) => sales.year,
        measure: (OrdinalSales sales, _) => sales.sales,
        data: mobileSalesData,
      ),
      charts.Series<OrdinalSales, String>(
        id: 'Other',
        domain: (OrdinalSales sales, _) => sales.year,
        measure: (OrdinalSales sales, _) => sales.sales,
        data: otherSalesData,
      ),
    ];
  }

  /// Create series list with multiple series
  static List<charts.Series<OrdinalSales, String>> createSampleData() {
    const desktopSalesData = [
      OrdinalSales('2020', 5),
      OrdinalSales('2021', 25),
      OrdinalSales('2022', 100),
      OrdinalSales('2023', 75),
    ];

    const tabletSalesData = [
      OrdinalSales('2020', 25),
      OrdinalSales('2021', 50),
      // Purposely have a missing datum for 2022 to show the null measure format
      OrdinalSales('2023', 20),
    ];

    const mobileSalesData = [
      OrdinalSales('2020', 10),
      OrdinalSales('2021', 15),
      OrdinalSales('2022', 50),
      OrdinalSales('2023', 45),
    ];

    const otherSalesData = [
      OrdinalSales('2020', 20),
      OrdinalSales('2021', 35),
      OrdinalSales('2022', 15),
      OrdinalSales('2023', 10),
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
        data: tabletSalesData,
      ),
      charts.Series<OrdinalSales, String>(
        id: 'Mobile',
        domain: (OrdinalSales sales, _) => sales.year,
        measure: (OrdinalSales sales, _) => sales.sales,
        data: mobileSalesData,
      ),
      charts.Series<OrdinalSales, String>(
        id: 'Other',
        domain: (OrdinalSales sales, _) => sales.year,
        measure: (OrdinalSales sales, _) => sales.sales,
        data: otherSalesData,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return charts.BarChart(
      seriesList,
      animate: animate,
      barGroupingType: charts.BarGroupingType.grouped,
      // Add the legend behavior to the chart to turn on legends.
      // This example shows how to optionally show measure and provide a custom
      // formatter.
      behaviors: [
        // This section is excluded from being copied to the gallery.
        // This is added in order to generate the image for the gallery to show
        // an initial selection so that measure values are shown in the gallery.
        const charts.InitialSelection(
          selectedDataConfig: [
            charts.SeriesDatumConfig('Desktop', '2023'),
            charts.SeriesDatumConfig('Tablet', '2023'),
            charts.SeriesDatumConfig('Mobile', '2023'),
            charts.SeriesDatumConfig('Other', '2023'),
          ],
        ),
        charts.SeriesLegend(
          // Positions for "start" and "end" will be left and right respectively
          // for widgets with a build context that has directionality ltr.
          // For rtl, "start" and "end" will be right and left respectively.
          // Since this example has directionality of ltr, the legend is
          // positioned on the right side of the chart.
          position: charts.BehaviorPosition.end,
          // By default, if the position of the chart is on the left or right of
          // the chart, [horizontalFirst] is set to false. This means that the
          // legend entries will grow as rows first instead of a column.
          // TODO horizontalFirst: false,
          // This defines the padding around each legend entry.
          // TODO cellPadding: const EdgeInsets.only(right: 4.0, bottom: 4.0),
          // Set show measures to true to display measures in series legend,
          // when the datum is selected.
          showMeasures: true,
          // Optionally provide a measure formatter to format the measure value.
          // If none is specified the value is formatted as a decimal.
          measureFormatter: (num? value) {
            return value == null ? '-' : '${value}k';
          },
        ),
      ],
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
