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

/// Example of a stacked area chart.

import 'dart:math';

import 'package:desktop/desktop.dart';
import 'package:desktop_charts/desktop_charts.dart' as charts;

class StackedAreaLineChart extends StatelessWidget {
  const StackedAreaLineChart(
    this.seriesList, {
    this.animate = true,
    super.key,
  });

  /// Creates a [LineChart] with sample data and no transition.
  factory StackedAreaLineChart.withSampleData([bool animate = true]) {
    return StackedAreaLineChart(
      createSampleData(),
      animate: animate,
    );
  }

  // This section is excluded from being copied to the gallery.
  // It is used for creating random series data to demonstrate animation in
  // the example app only.
  factory StackedAreaLineChart.withRandomData([bool animate = true]) {
    return StackedAreaLineChart(
      createRandomData(),
      animate: animate,
    );
  }

  final List<charts.Series<dynamic, num>> seriesList;
  final bool animate;

  /// Create random data.
  static List<charts.Series<LinearSales, int>> createRandomData() {
    final random = Random();

    final myFakeDesktopData = [
      LinearSales(0, random.nextInt(100)),
      LinearSales(1, random.nextInt(100)),
      LinearSales(2, random.nextInt(100)),
      LinearSales(3, random.nextInt(100)),
    ];

    final myFakeTabletData = [
      LinearSales(0, random.nextInt(100)),
      LinearSales(1, random.nextInt(100)),
      LinearSales(2, random.nextInt(100)),
      LinearSales(3, random.nextInt(100)),
    ];

    final myFakeMobileData = [
      LinearSales(0, random.nextInt(100)),
      LinearSales(1, random.nextInt(100)),
      LinearSales(2, random.nextInt(100)),
      LinearSales(3, random.nextInt(100)),
    ];

    return [
      charts.Series<LinearSales, int>(
        id: 'Desktop',
        color: (_, __) => charts.DesktopPalette.blue.shadeDefault,
        domain: (LinearSales sales, _) => sales.year,
        measure: (LinearSales sales, _) => sales.sales,
        data: myFakeDesktopData,
      ),
      charts.Series<LinearSales, int>(
        id: 'Tablet',
        color: (_, __) => charts.DesktopPalette.red.shadeDefault,
        domain: (LinearSales sales, _) => sales.year,
        measure: (LinearSales sales, _) => sales.sales,
        data: myFakeTabletData,
      ),
      charts.Series<LinearSales, int>(
        id: 'Mobile',
        color: (_, __) => charts.DesktopPalette.green.shadeDefault,
        domain: (LinearSales sales, _) => sales.year,
        measure: (LinearSales sales, _) => sales.sales,
        data: myFakeMobileData,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return charts.LineChart(seriesList,
        defaultRenderer:
            charts.LineRendererConfig(includeArea: true, stacked: true),
        animate: animate);
  }

  /// Create one series with sample hard coded data.
  static List<charts.Series<LinearSales, int>> createSampleData() {
    const myFakeDesktopData = [
      LinearSales(0, 5),
      LinearSales(1, 25),
      LinearSales(2, 100),
      LinearSales(3, 75),
    ];

    const myFakeTabletData = [
      LinearSales(0, 10),
      LinearSales(1, 50),
      LinearSales(2, 200),
      LinearSales(3, 150),
    ];

    const myFakeMobileData = [
      LinearSales(0, 15),
      LinearSales(1, 75),
      LinearSales(2, 300),
      LinearSales(3, 225),
    ];

    return [
      charts.Series<LinearSales, int>(
        id: 'Desktop',
        color: (_, __) => charts.DesktopPalette.blue.shadeDefault,
        domain: (LinearSales sales, _) => sales.year,
        measure: (LinearSales sales, _) => sales.sales,
        data: myFakeDesktopData,
      ),
      charts.Series<LinearSales, int>(
        id: 'Tablet',
        color: (_, __) => charts.DesktopPalette.red.shadeDefault,
        domain: (LinearSales sales, _) => sales.year,
        measure: (LinearSales sales, _) => sales.sales,
        data: myFakeTabletData,
      ),
      charts.Series<LinearSales, int>(
        id: 'Mobile',
        color: (_, __) => charts.DesktopPalette.green.shadeDefault,
        domain: (LinearSales sales, _) => sales.year,
        measure: (LinearSales sales, _) => sales.sales,
        data: myFakeMobileData,
      ),
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
