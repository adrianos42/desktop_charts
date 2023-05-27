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

import '../defaults.dart';

class DashPatternLineChartPage extends StatefulWidget {
  const DashPatternLineChartPage({super.key});

  @override
  State<DashPatternLineChartPage> createState() =>
      _DashPatternLineChartPageState();
}

class _DashPatternLineChartPageState extends State<DashPatternLineChartPage> {
  bool _hasAnimation = true;

  void _updateRandomData() {
    _data = DashPatternLineChart.createRandomData();
  }

  void _refresh() {
    setState(() => _updateRandomData());
  }

  @override
  void initState() {
    super.initState();

    _updateRandomData();
  }

  late List<charts.Series<LinearSales, int>> _data;

  @override
  Widget build(BuildContext context) {
    return Defaults(
      header: 'Line',
      items: [
        ItemTitle(
          title: DashPatternLineChart.title,
          subtitle: DashPatternLineChart.subtitle,
          body: (context) => DashPatternLineChart(
            _data,
            animate: _hasAnimation,
          ),
          options: [
            Button.icon(
              Icons.animation,
              onPressed: () => setState(() => _hasAnimation = !_hasAnimation),
              active: _hasAnimation,
            ),
            Button.icon(Icons.refresh, onPressed: _refresh),
          ],
        ),
      ],
    );
  }
}

class DashPatternLineChartBuilder extends ExampleBuilder {
  const DashPatternLineChartBuilder();

  @override
  Widget page([int? index, List<ExampleBuilder>? children]) =>
      const DashPatternLineChartPage();

  @override
  String? get subtitle => DashPatternLineChart.subtitle;

  @override
  String get title => DashPatternLineChart.title;

  @override
  Widget withSampleData([bool animate = true]) =>
      DashPatternLineChart.withSampleData(animate);
}

/// Dash pattern line chart example
/// Example of a line chart rendered with dash patterns.
@immutable
class DashPatternLineChart extends StatelessWidget {
  const DashPatternLineChart(
    this.seriesList, {
    this.animate = true,
    super.key,
  });

  /// Creates a [LineChart] with sample data and no transition.
  factory DashPatternLineChart.withSampleData([bool animate = true]) {
    return DashPatternLineChart(
      createSampleData(),
      animate: animate,
    );
  }

  static String get title => 'Dash Pattern';
  static String? get subtitle => 'Line chart with dash patterns';

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
        dashPattern: (_, __) => [2, 2],
        domain: (LinearSales sales, _) => sales.year,
        measure: (LinearSales sales, _) => sales.sales,
        data: myFakeTabletData,
      ),
      charts.Series<LinearSales, int>(
        id: 'Mobile',
        color: (_, __) => charts.DesktopPalette.green.shadeDefault,
        dashPattern: (_, __) => [8, 3, 2, 3],
        domain: (LinearSales sales, _) => sales.year,
        measure: (LinearSales sales, _) => sales.sales,
        data: myFakeMobileData,
      )
    ];
  }

  /// Create three series with sample hard coded data.
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
        dashPattern: (_, __) => [2, 2],
        domain: (LinearSales sales, _) => sales.year,
        measure: (LinearSales sales, _) => sales.sales,
        data: myFakeTabletData,
      ),
      charts.Series<LinearSales, int>(
        id: 'Mobile',
        color: (_, __) => charts.DesktopPalette.green.shadeDefault,
        dashPattern: (_, __) => [8, 3, 2, 3],
        domain: (LinearSales sales, _) => sales.year,
        measure: (LinearSales sales, _) => sales.sales,
        data: myFakeMobileData,
      )
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
  final int sales;
}
