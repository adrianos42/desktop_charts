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

/// Bar chart with example of a legend with customized position, justification,
/// desired max rows, and padding. These options are shown as an example of how
/// to use the customizations, they do not necessary have to be used together in
/// this way. Choosing [end] as the position does not require the justification
/// to also be [endDrawArea].

import 'dart:math';

import 'package:desktop/desktop.dart';
import 'package:desktop_charts/desktop_charts.dart' as charts;

/// Example that shows how to build a datum legend that shows measure values.
///
/// Also shows the option to provide a custom measure formatter.
class DatumLegendWithMeasures extends StatelessWidget {
  const DatumLegendWithMeasures(
    this.seriesList, {
    this.animate = true,
    super.key,
  });

  factory DatumLegendWithMeasures.withSampleData([bool animate = true]) {
    return DatumLegendWithMeasures(
      createSampleData(),
      animate: animate,
    );
  }

  // This section is excluded from being copied to the gallery.
  // It is used for creating random series data to demonstrate animation in
  // the example app only.
  factory DatumLegendWithMeasures.withRandomData([bool animate = true]) {
    return DatumLegendWithMeasures(
      createRandomData(),
      animate: animate,
    );
  }

  final List<charts.Series<dynamic, int>> seriesList;
  final bool animate;

  /// Create random data.
  static List<charts.Series<LinearSales, int>> createRandomData() {
    final random = Random();

    final data = [
      LinearSales(2014, random.nextInt(100)),
      LinearSales(2015, random.nextInt(100)),
      LinearSales(2016, random.nextInt(100)),
      LinearSales(2017, random.nextInt(100)),
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
    return charts.PieChart<int>(
      seriesList,
      animate: animate,
      // Add the legend behavior to the chart to turn on legends.
      // This example shows how to optionally show measure and provide a custom
      // formatter.
      behaviors: [
        // This section is excluded from being copied to the gallery.
        // This is added in order to generate the image for the gallery to show
        // an initial selection so that measure values are shown in the gallery.
        charts.InitialSelection(
          selectedDataConfig: [
            const charts.SeriesDatumConfig('Sales', 0),
          ],
        ),
        // TODO charts.DatumLegend(
        //   // Positions for "start" and "end" will be left and right respectively
        //   // for widgets with a build context that has directionality ltr.
        //   // For rtl, "start" and "end" will be right and left respectively.
        //   // Since this example has directionality of ltr, the legend is
        //   // positioned on the right side of the chart.
        //   position: charts.BehaviorPosition.end,
        //   // By default, if the position of the chart is on the left or right of
        //   // the chart, [horizontalFirst] is set to false. This means that the
        //   // legend entries will grow as rows first instead of a column.
        //   horizontalFirst: false,
        //   // This defines the padding around each legend entry.
        //   cellPadding: const EdgeInsets.only(right: 4.0, bottom: 4.0),
        //   // Set [showMeasures] to true to display measures in series legend.
        //   showMeasures: true,
        //   // Configure the measure value to be shown by default in the legend.
        //   legendDefaultMeasure: charts.LegendDefaultMeasure.firstValue,
        //   // Optionally provide a measure formatter to format the measure value.
        //   // If none is specified the value is formatted as a decimal.
        //   measureFormatter: (num? value) {
        //     return value == null ? '-' : '${value}k';
        //   },
        // ),
      ],
    );
  }

  /// Create series list with one series
  static List<charts.Series<LinearSales, int>> createSampleData() {
    const data = [
      LinearSales(2014, 100),
      LinearSales(2015, 75),
      LinearSales(2016, 25),
      LinearSales(2017, 5),
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
}

/// Sample linear data type.
@immutable
class LinearSales {
  const LinearSales(this.year, this.sales);

  final int year;
  final int sales;
}
