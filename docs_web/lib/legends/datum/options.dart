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

class DatumLegendOptionsBuilder extends ExampleBuilder {
  const DatumLegendOptionsBuilder();

  @override
  String? get subtitle => DatumLegendOptions.subtitle;

  @override
  String get title => DatumLegendOptions.title;

  @override
  Widget withSampleData([bool animate = true]) =>
      DatumLegendOptions.withSampleData(animate);

  @override
  Widget withData(dynamic data, [bool animate = true]) => DatumLegendOptions(
        data as List<charts.Series<dynamic, num>>,
        animate: animate,
      );

  @override
  dynamic generateRandomData() => DatumLegendOptions.createRandomData();

  @override
  bool get hasParent => true;

  @override
  String get parentTitle => 'Datum';
}

/// Pie chart with example of a legend with customized position, justification,
/// desired max rows, padding, and entry text styles. These options are shown as
/// an example of how to use the customizations, they do not necessary have to
/// be used together in this way. Choosing [end] as the position does not
/// require the justification to also be [endDrawArea].
class DatumLegendOptions extends StatelessWidget {
  const DatumLegendOptions(
    this.seriesList, {
    this.animate = true,
    super.key,
  });

  factory DatumLegendOptions.withSampleData([bool animate = true]) {
    return DatumLegendOptions(
      createSampleData(),
      animate: animate,
    );
  }

  static String get title => 'Options';
  static String? get subtitle =>
      'A datum legend with custom positioning and spacing for a pie chart';

  final List<charts.Series<dynamic, num>> seriesList;
  final bool animate;

  /// Create random data.
  static List<charts.Series<LinearSales, int>> createRandomData() {
    final random = Random();

    final data = [
      LinearSales(0, random.nextInt(100)),
      LinearSales(1, random.nextInt(100)),
      LinearSales(2, random.nextInt(100)),
      LinearSales(3, random.nextInt(100)),
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

  /// Create series list with one series
  static List<charts.Series<LinearSales, int>> createSampleData() {
    const data = [
      LinearSales(0, 100),
      LinearSales(1, 75),
      LinearSales(2, 25),
      LinearSales(3, 5),
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
    return charts.PieChart(
      seriesList,
      animate: animate,
      // Add the legend behavior to the chart to turn on legends.
      // This example shows how to change the position and justification of
      // the legend, in addition to altering the max rows and padding.
      behaviors: [
        charts.DatumLegend(
          // Positions for "start" and "end" will be left and right respectively
          // for widgets with a build context that has directionality ltr.
          // For rtl, "start" and "end" will be right and left respectively.
          // Since this example has directionality of ltr, the legend is
          // positioned on the right side of the chart.
          position: charts.BehaviorPosition.end,
          // For a legend that is positioned on the left or right of the chart,
          // setting the justification for [endDrawArea] is aligned to the
          // bottom of the chart draw area.
          outsideJustification: charts.OutsideJustification.endDrawArea,
          // By default, if the position of the chart is on the left or right of
          // the chart, [horizontalFirst] is set to false. This means that the
          // legend entries will grow as rows first instead of a column.
          // TODO horizontalFirst: false,
          // By setting this value to 2, the legend entries will grow up to two
          // rows before adding a column.
          // TODO desiredMaxRows: 2,
          // This defines the padding around each legend entry.
          // TODO cellPadding: const EdgeInsets.only(right: 4.0, bottom: 4.0),
          // Render the legend entry text with custom styles.
          entryTextStyle: TextStyle(
            color: PrimaryColors.violet.primaryColor
                .withBrightness(Theme.brightnessOf(context))[60],
            fontFamily: 'Georgia',
            fontSize: 16,
          ),
        )
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
