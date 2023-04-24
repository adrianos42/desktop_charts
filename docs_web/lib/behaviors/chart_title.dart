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

/// This is a line chart with a title text in every margin.
///
/// A series of [ChartTitle] behaviors are used to render titles, one per
/// margin.
class ChartTitleLine extends StatelessWidget {
  const ChartTitleLine(
    this.seriesList, {
    this.animate = true,
    super.key,
  });

  /// Creates a [LineChart] with sample data and no transition.
  factory ChartTitleLine.withSampleData([bool animate = true]) {
    return ChartTitleLine(
      createSampleData(),
      animate: animate,
    );
  }

  // This section is excluded from being copied to the gallery.
  // It is used for creating random series data to demonstrate animation in
  // the example app only.
  factory ChartTitleLine.withRandomData([bool animate = true]) {
    return ChartTitleLine(
      createRandomData(),
      animate: animate,
    );
  }

  final List<charts.Series<dynamic, num>> seriesList;
  final bool animate;

  /// Create random data.
  static List<charts.Series<LinearSales, num>> createRandomData() {
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

  @override
  Widget build(BuildContext context) {
    return charts.LineChart(
      seriesList,
      animate: animate,
      // Configures four [ChartTitle] behaviors to render titles in each chart
      // margin. The top title has a sub-title, and is aligned to the left edge
      // of the chart. The other titles are aligned with the middle of the draw
      // area.
      behaviors: const [
        charts.ChartTitle(
          'Top title text',
          subtitle: 'Top sub-title text',
          position: charts.BehaviorPosition.top,
          titleOutsideJustification: charts.OutsideJustification.start,
          // Set a larger inner padding than the default (10) to avoid
          // rendering the text too close to the top measure axis tick label.
          // The top tick label may extend upwards into the top margin region
          // if it is located at the top of the draw area.
          innerPadding: 16,
        ),
        charts.ChartTitle(
          'Bottom title text',
          position: charts.BehaviorPosition.bottom,
          titleOutsideJustification: charts.OutsideJustification.middleDrawArea,
        ),
        charts.ChartTitle(
          'Start title',
          position: charts.BehaviorPosition.start,
          titleOutsideJustification: charts.OutsideJustification.middleDrawArea,
        ),
        charts.ChartTitle(
          'End title',
          position: charts.BehaviorPosition.end,
          titleOutsideJustification: charts.OutsideJustification.middleDrawArea,
        ),
      ],
    );
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
}

/// Sample linear data type.
@immutable
class LinearSales {
  const LinearSales(this.year, this.sales);

  final int year;
  final int sales;
}
