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

class SimpleLineChartBuilder extends ExampleBuilder {
  const SimpleLineChartBuilder();

  @override
  String? get subtitle => SimpleLineChart.subtitle;

  @override
  String get title => SimpleLineChart.title;

  @override
  Widget withSampleData([bool animate = true]) =>
      SimpleLineChart.withSampleData(animate);

  @override
  Widget withData(dynamic data, [bool animate = true]) => SimpleLineChart(
        data as List<charts.Series<dynamic, num>>,
        animate: animate,
      );

  @override
  dynamic generateRandomData() => SimpleLineChart.createRandomData();

  @override
  bool get hasParent => true;

  @override
  String get parentTitle => 'Simple';
}

/// Example of a simple line chart.
@immutable
class SimpleLineChart extends StatelessWidget {
  const SimpleLineChart(
    this.seriesList, {
    this.animate = true,
    super.key,
  });

  /// Creates a [LineChart] with sample data and no transition.
  factory SimpleLineChart.withSampleData([bool animate = true]) {
    return SimpleLineChart(
      createSampleData(),
      animate: animate,
    );
  }

  static String get title => 'Simple';
  static String? get subtitle =>
      'With a single series and default line point highlighter';

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
        color: (_, __) => charts.DesktopPalette.blue.shadeDefault,
        domain: (LinearSales sales, _) => sales.year,
        measure: (LinearSales sales, _) => sales.sales,
        data: data,
      )
    ];
  }

  /// Create one series with sample hard coded data.
  static List<charts.Series<LinearSales, int>> createSampleData() {
    const data = [
      LinearSales(0, 0),
      LinearSales(1, 2),
      LinearSales(2, 199),
      LinearSales(3, 75),
    ];

    return [
      charts.Series<LinearSales, int>(
        id: 'Sales',
        color: (_, __) => charts.DesktopPalette.blue.shadeDefault,
        domain: (LinearSales sales, _) => sales.year,
        measure: (LinearSales sales, _) => sales.sales,
        data: data,
      )
    ];
  }

  @override
  Widget build(BuildContext context) {
    return charts.LineChart(seriesList, animate: animate, behaviors: const [
      charts.PanAndZoomBehavior(),
    ]);
  }
}

/// Sample linear data type.
@immutable
class LinearSales {
  const LinearSales(this.year, this.sales);

  final int year;
  final int sales;
}
