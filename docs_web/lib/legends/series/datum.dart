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

class SimpleDatumLegendBuilder extends ExampleBuilder {
  const SimpleDatumLegendBuilder();

  @override
  String? get subtitle => SimpleDatumLegend.subtitle;

  @override
  String get title => SimpleDatumLegend.title;

  @override
  Widget withSampleData([bool animate = true]) =>
      SimpleDatumLegend.withSampleData(animate);

  @override
  Widget withData(dynamic data, [bool animate = true]) =>
      SimpleDatumLegend(
        data as List<charts.Series<dynamic, num>>,
        animate: animate,
      );

  @override
  dynamic generateRandomData() => SimpleDatumLegend.createRandomData();

  @override
  bool get hasParent => true;

  @override
  String get parentTitle => 'Series';
}

/// Bar chart with series legend example
class SimpleDatumLegend extends StatelessWidget {
  const SimpleDatumLegend(
    this.seriesList, {
    this.animate = true,
    super.key,
  });

  factory SimpleDatumLegend.withSampleData([bool animate = true]) {
    return SimpleDatumLegend(
      createSampleData(),
      animate: animate,
    );
  }

  static String get title => 'Datum';
  static String? get subtitle =>
      'A datum legend for a pie chart with default settings';

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
      // Add the series legend behavior to the chart to turn on series legends.
      // By default the legend will display above the chart.
      behaviors: const [charts.DatumLegend()],
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
