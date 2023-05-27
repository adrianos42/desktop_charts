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

class SimpleNullsLineChartBuilder extends ExampleBuilder {
  const SimpleNullsLineChartBuilder();

  @override
  String? get subtitle => SimpleNullsLineChart.subtitle;

  @override
  String get title => SimpleNullsLineChart.title;

  @override
  Widget withSampleData([bool animate = true]) =>
      SimpleNullsLineChart.withSampleData(animate);

  @override
  Widget withData(dynamic data, [bool animate = true]) =>
      SimpleNullsLineChart(
        data as List<charts.Series<dynamic, num>>,
        animate: animate,
      );

  @override
  dynamic generateRandomData() => SimpleNullsLineChart.createRandomData();

  @override
  bool get hasParent => true;

  @override
  String get parentTitle => 'Simple';
}

/// Example of a line chart with null measure values.
///
/// Null values will be visible as gaps in lines and area skirts. Any data
/// points that exist between two nulls in a line will be rendered as an
/// isolated point, as seen in the green series.
@immutable
class SimpleNullsLineChart extends StatelessWidget {
  const SimpleNullsLineChart(
    this.seriesList, {
    this.animate = true,
    super.key,
  });

  /// Creates a [LineChart] with sample data and no transition.
  factory SimpleNullsLineChart.withSampleData([bool animate = true]) {
    return SimpleNullsLineChart(
      createSampleData(),
      animate: animate,
    );
  }

  static String get title => 'Null Data';
  static String? get subtitle => 'With a single series and null measure values';

  final List<charts.Series<dynamic, num>> seriesList;
  final bool animate;

  /// Create random data.
  static List<charts.Series<LinearSales, int>> createRandomData() {
    final random = Random();

    final myFakeDesktopData = [
      LinearSales(0, random.nextInt(100)),
      LinearSales(1, random.nextInt(100)),
      const LinearSales(2, null),
      LinearSales(3, random.nextInt(100)),
      LinearSales(4, random.nextInt(100)),
      LinearSales(5, random.nextInt(100)),
      LinearSales(6, random.nextInt(100)),
    ];

    final myFakeTabletData = [
      LinearSales(0, random.nextInt(100)),
      LinearSales(1, random.nextInt(100)),
      LinearSales(2, random.nextInt(100)),
      LinearSales(3, random.nextInt(100)),
      LinearSales(4, random.nextInt(100)),
      LinearSales(5, random.nextInt(100)),
      LinearSales(6, random.nextInt(100)),
    ];

    final myFakeMobileData = [
      LinearSales(0, random.nextInt(100)),
      LinearSales(1, random.nextInt(100)),
      const LinearSales(2, null),
      LinearSales(3, random.nextInt(100)),
      const LinearSales(4, null),
      LinearSales(5, random.nextInt(100)),
      LinearSales(6, random.nextInt(100)),
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

  /// Create one series with sample hard coded data.
  static List<charts.Series<LinearSales, int>> createSampleData() {
    const myFakeDesktopData = [
      LinearSales(0, 5),
      LinearSales(1, 15),
      LinearSales(2, null),
      LinearSales(3, 75),
      LinearSales(4, 100),
      LinearSales(5, 90),
      LinearSales(6, 75),
    ];

    const myFakeTabletData = [
      LinearSales(0, 10),
      LinearSales(1, 30),
      LinearSales(2, 50),
      LinearSales(3, 150),
      LinearSales(4, 200),
      LinearSales(5, 180),
      LinearSales(6, 150),
    ];

    const myFakeMobileData = [
      LinearSales(0, 15),
      LinearSales(1, 45),
      LinearSales(2, null),
      LinearSales(3, 225),
      LinearSales(4, null),
      LinearSales(5, 270),
      LinearSales(6, 225),
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
    return charts.LineChart(seriesList, animate: animate);
  }
}

/// Sample linear data type.
@immutable
class LinearSales {
  const LinearSales(this.year, this.sales);

  final int year;
  final int? sales;
}
