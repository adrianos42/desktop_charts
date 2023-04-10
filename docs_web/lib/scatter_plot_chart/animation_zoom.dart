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

/// Example of a line chart with pan and zoom enabled via
/// [Charts.PanAndZoomBehavior].

import 'dart:math';

import 'package:desktop/desktop.dart';
import 'package:desktop_charts/desktop_charts.dart' as charts;

class ScatterPlotAnimationZoomChart extends StatelessWidget {
  const ScatterPlotAnimationZoomChart(
    this.seriesList, {
    this.animate = true,
    super.key,
  });

  /// Creates a [ScatterPlotChart] with sample data and no transition.
  factory ScatterPlotAnimationZoomChart.withSampleData([bool animate = true]) {
    return ScatterPlotAnimationZoomChart(
      createSampleData(),
      animate: animate,
    );
  }

  // This section is excluded from being copied to the gallery.
  // It is used for creating random series data to demonstrate animation in
  // the example app only.
  factory ScatterPlotAnimationZoomChart.withRandomData([bool animate = true]) {
    return ScatterPlotAnimationZoomChart(
      createRandomData(),
      animate: animate,
    );
  }

  final List<charts.Series<dynamic, num>> seriesList;
  final bool animate;

  /// Create random data.
  static List<charts.Series<LinearSales, int>> createRandomData() {
    final random = Random();

    final data = <LinearSales>[];

    double makeRadius(int value) => (random.nextInt(value) + 2).toDouble();

    for (var i = 0; i < 100; i++) {
      data.add(LinearSales(i, random.nextInt(100), makeRadius(4)));
    }

    const maxMeasure = 100;

    return [
      charts.Series<LinearSales, int>(
        id: 'Sales',
        color: (LinearSales sales, _) {
          // Color bucket the measure column value into 3 distinct colors.
          final bucket = sales.sales / maxMeasure;

          if (bucket < 1 / 3) {
            return charts.DesktopPalette.blue.shadeDefault;
          } else if (bucket < 2 / 3) {
            return charts.DesktopPalette.red.shadeDefault;
          } else {
            return charts.DesktopPalette.green.shadeDefault;
          }
        },
        domain: (LinearSales sales, _) => sales.year,
        measure: (LinearSales sales, _) => sales.sales,
        radius: (LinearSales sales, _) => sales.radius,
        data: data,
      )
    ];
  }

  @override
  Widget build(BuildContext context) {
    return charts.ScatterPlotChart(seriesList, animate: animate, behaviors: [
      // TODO charts.PanAndZoomBehavior(),
    ]);
  }

  /// Create one series with sample hard coded data.
  static List<charts.Series<LinearSales, int>> createSampleData() {
    const data = [
      LinearSales(0, 5, 3.0),
      LinearSales(10, 25, 5.0),
      LinearSales(12, 75, 4.0),
      LinearSales(13, 225, 5.0),
      LinearSales(16, 50, 4.0),
      LinearSales(24, 75, 3.0),
      LinearSales(25, 100, 3.0),
      LinearSales(34, 150, 5.0),
      LinearSales(37, 10, 4.5),
      LinearSales(45, 300, 8.0),
      LinearSales(52, 15, 4.0),
      LinearSales(56, 200, 7.0),
    ];

    const maxMeasure = 300;

    return [
      charts.Series<LinearSales, int>(
        id: 'Sales',
        color: (LinearSales sales, _) {
          // Color bucket the measure column value into 3 distinct colors.
          final bucket = sales.sales / maxMeasure;

          if (bucket < 1 / 3) {
            return charts.DesktopPalette.blue.shadeDefault;
          } else if (bucket < 2 / 3) {
            return charts.DesktopPalette.red.shadeDefault;
          } else {
            return charts.DesktopPalette.green.shadeDefault;
          }
        },
        domain: (LinearSales sales, _) => sales.year,
        measure: (LinearSales sales, _) => sales.sales,
        radius: (LinearSales sales, _) => sales.radius,
        data: data,
      )
    ];
  }
}

/// Sample linear data type.
@immutable
class LinearSales {
  const LinearSales(this.year, this.sales, this.radius);

  final int year;
  final int sales;
  final double radius;
}
