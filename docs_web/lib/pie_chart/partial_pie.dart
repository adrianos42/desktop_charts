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

class PartialPieChartPage extends StatefulWidget {
  const PartialPieChartPage({super.key});

  @override
  State<PartialPieChartPage> createState() => _PartialPieChartPageState();
}

class _PartialPieChartPageState extends State<PartialPieChartPage> {
  bool _hasAnimation = true;

  void _updateRandomData() {
    _data = PartialPieChart.createRandomData();
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
          title: PartialPieChart.title,
          subtitle: PartialPieChart.subtitle,
          body: (context) => PartialPieChart(
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

class PartialPieChartBuilder extends ExampleBuilder {
  const PartialPieChartBuilder();

  @override
  Widget page([int? index, List<ExampleBuilder>? children]) =>
      const PartialPieChartPage();

  @override
  String? get subtitle => PartialPieChart.subtitle;

  @override
  String get title => PartialPieChart.title;

  @override
  Widget withSampleData([bool animate = true]) =>
      PartialPieChart.withSampleData(animate);
}

/// Partial pie chart example, where the data does not cover a full revolution
/// in the chart.
class PartialPieChart extends StatelessWidget {
  const PartialPieChart(
    this.seriesList, {
    this.animate = true,
    super.key,
  });

  /// Creates a [PieChart] with sample data and no transition.
  factory PartialPieChart.withSampleData([bool animate = true]) {
    return PartialPieChart(
      createSampleData(),
      animate: animate,
    );
  }

  static String get title => 'Partial';
  static String? get subtitle => 'That doesn\'t cover a full revolution';

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
    // Configure the pie to display the data across only 3/4 instead of the full
    // revolution.
    return charts.PieChart(
      seriesList,
      animate: animate,
      defaultRenderer: const charts.ArcRendererConfig(
        arcLength: 3 / 2 * pi,
      ),
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
