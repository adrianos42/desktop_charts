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

class SimpleSunburstChartPage extends StatefulWidget {
  const SimpleSunburstChartPage({super.key});

  @override
  State<SimpleSunburstChartPage> createState() =>
      _SimpleSunburstChartPageState();
}

class _SimpleSunburstChartPageState extends State<SimpleSunburstChartPage> {
  bool _hasAnimation = true;

  void _updateRandomData() {
    _data = SimpleSunburstChart.createRandomData();
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
      header: 'Sunburst',
      items: [
        ItemTitle(
          title: SimpleSunburstChart.title,
          subtitle: SimpleSunburstChart.subtitle,
          body: (context) => SimpleSunburstChart(
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

class SimpleSunburstChartBuilder extends ExampleBuilder {
  const SimpleSunburstChartBuilder();

  @override
  Widget page([int? index, List<ExampleBuilder>? children]) =>
      const SimpleSunburstChartPage();

  @override
  String? get subtitle => SimpleSunburstChart.subtitle;

  @override
  String get title => SimpleSunburstChart.title;

  @override
  Widget withSampleData([bool animate = true]) =>
      SimpleSunburstChart.withSampleData(animate);
}

/// Simple pie chart example.
class SimpleSunburstChart extends StatelessWidget {
  const SimpleSunburstChart(
    this.seriesList, {
    this.animate = true,
    super.key,
  });

  /// Creates a [SunburstChart] with sample data and no transition.
  factory SimpleSunburstChart.withSampleData([bool animate = true]) {
    return SimpleSunburstChart(createSampleData(), animate: animate);
  }

  static String get title => 'Simple Sunburst Chart';
  static String? get subtitle => 'With a single series';

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
    // return charts.SunburstChart(
    //   [],
    //   animate: animate,
    //   defaultInteractions: true,
    // );
    return SizedBox();
  }
}

/// Sample linear data type.
@immutable
class LinearSales {
  const LinearSales(this.year, this.sales);

  final int year;
  final int sales;
}
