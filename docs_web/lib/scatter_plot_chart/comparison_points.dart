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

class ComparisonPointsScatterPlotChartPage extends StatefulWidget {
  const ComparisonPointsScatterPlotChartPage({super.key});

  @override
  State<ComparisonPointsScatterPlotChartPage> createState() =>
      _ComparisonPointsScatterPlotChartPageState();
}

class _ComparisonPointsScatterPlotChartPageState
    extends State<ComparisonPointsScatterPlotChartPage> {
  bool _hasAnimation = true;

  void _updateRandomData() {
    _data = ComparisonPointsScatterPlotChart.createRandomData();
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
      header: 'Scatter Plot',
      items: [
        ItemTitle(
          title: ComparisonPointsScatterPlotChart.title,
          subtitle: ComparisonPointsScatterPlotChart.subtitle,
          body: (context) => ComparisonPointsScatterPlotChart(
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

class ComparisonPointsScatterPlotChartBuilder extends ExampleBuilder {
  const ComparisonPointsScatterPlotChartBuilder();

  @override
  Widget page([int? index, List<ExampleBuilder>? children]) =>
      const ComparisonPointsScatterPlotChartPage();

  @override
  String? get subtitle => ComparisonPointsScatterPlotChart.subtitle;

  @override
  String get title => ComparisonPointsScatterPlotChart.title;

  @override
  Widget withSampleData([bool animate = true]) =>
      ComparisonPointsScatterPlotChart.withSampleData(animate);
}

/// Line chart example
class ComparisonPointsScatterPlotChart extends StatelessWidget {
  const ComparisonPointsScatterPlotChart(
    this.seriesList, {
    this.animate = true,
    super.key,
  });

  /// Creates a [ScatterPlotChart] with sample data and no transition.
  factory ComparisonPointsScatterPlotChart.withSampleData([
    bool animate = true,
  ]) {
    return ComparisonPointsScatterPlotChart(
      createSampleData(),
      animate: animate,
    );
  }

  static String get title => 'Comparison Points';
  static String? get subtitle => 'Scatter plot chart with comparison points';

  final List<charts.Series<dynamic, num>> seriesList;
  final bool animate;

  /// Create random data.
  static List<charts.Series<LinearSales, int>> createRandomData() {
    final random = Random();

    const maxMeasure = 100;

    final data = [
      _makeRandomDatum(maxMeasure, random),
      _makeRandomDatum(maxMeasure, random),
      _makeRandomDatum(maxMeasure, random),
      _makeRandomDatum(maxMeasure, random),
      _makeRandomDatum(maxMeasure, random),
      _makeRandomDatum(maxMeasure, random),
    ];

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
        domainLowerBound: (LinearSales sales, _) => sales.yearLower,
        domainUpperBound: (LinearSales sales, _) => sales.yearUpper,
        measure: (LinearSales sales, _) => sales.sales,
        measureLowerBound: (LinearSales sales, _) => sales.salesLower,
        measureUpperBound: (LinearSales sales, _) => sales.salesUpper,
        radius: (LinearSales sales, _) => sales.radius,
        data: data,
      )
    ];
  }

  static LinearSales _makeRandomDatum(int max, Random random) {
    double makeRadius(int value) => (random.nextInt(value) + 6).toDouble();

    final year = random.nextInt(max);
    final yearLower = (year * 0.8).round();
    final yearUpper = year;
    final sales = random.nextInt(max);
    final salesLower = (sales * 0.8).round();
    final salesUpper = sales;

    return LinearSales(
      year,
      yearLower,
      yearUpper,
      sales,
      salesLower,
      salesUpper,
      makeRadius(4),
    );
  }

  /// Create one series with sample hard coded data.
  static List<charts.Series<LinearSales, int>> createSampleData() {
    const data = [
      LinearSales(10, 7, 10, 25, 20, 25, 5.0),
      LinearSales(13, 11, 13, 225, 205, 225, 5.0),
      LinearSales(34, 34, 24, 150, 150, 130, 5.0),
      LinearSales(37, 37, 57, 10, 10, 12, 6.5),
      LinearSales(45, 35, 45, 260, 300, 260, 8.0),
      LinearSales(56, 46, 56, 200, 170, 200, 7.0),
    ];

    const maxMeasure = 300;

    return [
      charts.Series<LinearSales, int>(
        id: 'Sales',
        // Providing a color function is optional.
        color: (LinearSales sales, _) {
          // Bucket the measure column value into 3 distinct colors.
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
        domainLowerBound: (LinearSales sales, _) => sales.yearLower,
        domainUpperBound: (LinearSales sales, _) => sales.yearUpper,
        measure: (LinearSales sales, _) => sales.sales,
        measureLowerBound: (LinearSales sales, _) => sales.salesLower,
        measureUpperBound: (LinearSales sales, _) => sales.salesUpper,
        // Providing a radius function is optional.
        radius: (LinearSales sales, _) => sales.radius,
        data: data,
      )
    ];
  }

  @override
  Widget build(BuildContext context) {
    return charts.ScatterPlotChart(
      seriesList,
      animate: animate,
      defaultRenderer: const charts.PointRendererConfig(
        pointRendererDecorators: [
          charts.ComparisonPointsDecorator(
              symbolRenderer: charts.CylinderSymbolRenderer())
        ],
      ),
    );
  }
}

/// Sample linear data type.
@immutable
class LinearSales {
  const LinearSales(
    this.year,
    this.yearLower,
    this.yearUpper,
    this.sales,
    this.salesLower,
    this.salesUpper,
    this.radius,
  );

  final int year;
  final int yearLower;
  final int yearUpper;
  final int sales;
  final int salesLower;
  final int salesUpper;
  final double radius;
}
