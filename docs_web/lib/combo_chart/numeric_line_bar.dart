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

class NumericComboLineBarChartPage extends StatefulWidget {
  const NumericComboLineBarChartPage({super.key});

  @override
  State<NumericComboLineBarChartPage> createState() =>
      _NumericComboLineBarChartPageState();
}

class _NumericComboLineBarChartPageState
    extends State<NumericComboLineBarChartPage> {
  bool _hasAnimation = true;

  void _updateRandomData() {
    _data = NumericComboLineBarChart.createRandomData();
  }

  void _refresh() {
    setState(() => _updateRandomData());
  }

  @override
  void initState() {
    super.initState();

    _updateRandomData();
  }

  late List<charts.Series<LinearSales, num>> _data;

  @override
  Widget build(BuildContext context) {
    return Defaults(
      header: 'Combo',
      items: [
        ItemTitle(
          title: NumericComboLineBarChart.title,
          subtitle: NumericComboLineBarChart.subtitle,
          body: (context) => NumericComboLineBarChart(
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

class NumericComboLineBarChartBuilder extends ExampleBuilder {
  const NumericComboLineBarChartBuilder();

  @override
  Widget page([int? index, List<ExampleBuilder>? children]) =>
      const NumericComboLineBarChartPage();

  @override
  String? get subtitle => NumericComboLineBarChart.subtitle;

  @override
  String get title => NumericComboLineBarChart.title;

  @override
  Widget withSampleData([bool animate = true]) =>
      NumericComboLineBarChart.withSampleData(animate);
}

/// Example of a numeric combo chart with two series rendered as bars, and a
/// third rendered as a line.
class NumericComboLineBarChart extends StatelessWidget {
  const NumericComboLineBarChart(
    this.seriesList, {
    this.animate = true,
    super.key,
  });

  /// Creates a [LineChart] with sample data and no transition.
  factory NumericComboLineBarChart.withSampleData([bool animate = true]) {
    return NumericComboLineBarChart(
      createSampleData(),
      animate: animate,
    );
  }

  static String get title => 'Numeric Line Bar';
  static String? get subtitle => 'Numeric combo chart with lines and bars';

  final List<charts.Series<dynamic, num>> seriesList;
  final bool animate;

  /// Create random data.
  static List<charts.Series<LinearSales, num>> createRandomData() {
    final random = Random();

    final desktopSalesData = [
      LinearSales(0, random.nextInt(100)),
      LinearSales(1, random.nextInt(100)),
      LinearSales(2, random.nextInt(100)),
      LinearSales(3, random.nextInt(100)),
    ];

    final tableSalesData = [
      LinearSales(0, desktopSalesData[0].sales),
      LinearSales(1, desktopSalesData[1].sales),
      LinearSales(2, desktopSalesData[2].sales),
      LinearSales(3, desktopSalesData[3].sales),
    ];

    final mobileSalesData = [
      LinearSales(0, tableSalesData[0].sales * 2),
      LinearSales(1, tableSalesData[1].sales * 2),
      LinearSales(2, tableSalesData[2].sales * 2),
      LinearSales(3, tableSalesData[3].sales * 2),
    ];

    return [
      charts.Series<LinearSales, int>(
        id: 'Desktop',
        color: (_, __) => charts.DesktopPalette.blue.shadeDefault,
        domain: (LinearSales sales, _) => sales.year,
        measure: (LinearSales sales, _) => sales.sales,
        data: desktopSalesData,
      )
        // Configure our custom bar renderer for this series.
        ..setAttribute(charts.rendererIdKey, 'customBar'),
      charts.Series<LinearSales, int>(
        id: 'Tablet',
        color: (_, __) => charts.DesktopPalette.red.shadeDefault,
        domain: (LinearSales sales, _) => sales.year,
        measure: (LinearSales sales, _) => sales.sales,
        data: tableSalesData,
      )
        // Configure our custom bar renderer for this series.
        ..setAttribute(charts.rendererIdKey, 'customBar'),
      charts.Series<LinearSales, int>(
        id: 'Mobile',
        color: (_, __) => charts.DesktopPalette.green.shadeDefault,
        domain: (LinearSales sales, _) => sales.year,
        measure: (LinearSales sales, _) => sales.sales,
        data: mobileSalesData,
      ),
    ];
  }

  /// Create one series with sample hard coded data.
  static List<charts.Series<LinearSales, int>> createSampleData() {
    const desktopSalesData = [
      LinearSales(0, 5),
      LinearSales(1, 25),
      LinearSales(2, 100),
      LinearSales(3, 75),
    ];

    const tableSalesData = [
      LinearSales(0, 5),
      LinearSales(1, 25),
      LinearSales(2, 100),
      LinearSales(3, 75),
    ];

    const mobileSalesData = [
      LinearSales(0, 10),
      LinearSales(1, 50),
      LinearSales(2, 200),
      LinearSales(3, 150),
    ];

    return [
      charts.Series<LinearSales, int>(
        id: 'Desktop',
        color: (_, __) => charts.DesktopPalette.blue.shadeDefault,
        domain: (LinearSales sales, _) => sales.year,
        measure: (LinearSales sales, _) => sales.sales,
        data: desktopSalesData,
      )
        // Configure our custom bar renderer for this series.
        ..setAttribute(charts.rendererIdKey, 'customBar'),
      charts.Series<LinearSales, int>(
        id: 'Tablet',
        color: (_, __) => charts.DesktopPalette.red.shadeDefault,
        domain: (LinearSales sales, _) => sales.year,
        measure: (LinearSales sales, _) => sales.sales,
        data: tableSalesData,
      )
        // Configure our custom bar renderer for this series.
        ..setAttribute(charts.rendererIdKey, 'customBar'),
      charts.Series<LinearSales, int>(
        id: 'Mobile',
        color: (_, __) => charts.DesktopPalette.green.shadeDefault,
        domain: (LinearSales sales, _) => sales.year,
        measure: (LinearSales sales, _) => sales.sales,
        data: mobileSalesData,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return charts.NumericCartesianChart(
      seriesList,
      animate: animate,
      // Configure the default renderer as a line renderer. This will be used
      // for any series that does not define a rendererIdKey.
      defaultRenderer: const charts.LineRendererConfig(),
      // Custom renderer configuration for the bar series.
      customSeriesRenderers: const [
        charts.BarRendererConfig(
          // ID used to link series to this renderer.
          customRendererId: 'customBar',
        ),
      ],
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
