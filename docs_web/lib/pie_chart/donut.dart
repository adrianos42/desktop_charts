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

class DonutPieChartPage extends StatefulWidget {
  const DonutPieChartPage({super.key});

  @override
  State<DonutPieChartPage> createState() => _DonutPieChartPageState();
}

class _DonutPieChartPageState extends State<DonutPieChartPage> {
  bool _hasAnimation = true;

  void _updateRandomData() {
    _data = DonutPieChart.createRandomData();
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
      header: 'Pie',
      items: [
        ItemTitle(
          title: DonutPieChart.title,
          subtitle: DonutPieChart.subtitle,
          body: (context) => DonutPieChart(
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

class DonutPieChartBuilder extends ExampleBuilder {
  const DonutPieChartBuilder();

  @override
  Widget page([int? index, List<ExampleBuilder>? children]) =>
      const DonutPieChartPage();

  @override
  String? get subtitle => DonutPieChart.subtitle;

  @override
  String get title => DonutPieChart.title;

  @override
  Widget withSampleData([bool animate = true]) =>
      DonutPieChart.withSampleData(animate);
}

/// Donut chart example. This is a simple pie chart with a hole in the middle.
class DonutPieChart extends StatelessWidget {
  const DonutPieChart(
    this.seriesList, {
    this.animate = true,
    super.key,
  });

  /// Creates a [PieChart] with sample data and no transition.
  factory DonutPieChart.withSampleData([bool animate = true]) {
    return DonutPieChart(
      createSampleData(),
      animate: animate,
    );
  }

  static String get title => 'Simple Donut';
  static String? get subtitle =>
      'With a single series and a hole in the middle';

  final List<charts.Series<dynamic, int>> seriesList;
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

  /// Create one series with sample hard coded data.
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
      // Configure the width of the pie slices to 60px. The remaining space in
      // the chart will be left as a hole in the center.
      defaultRenderer: const charts.ArcRendererConfig(arcWidth: 60.0),
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
