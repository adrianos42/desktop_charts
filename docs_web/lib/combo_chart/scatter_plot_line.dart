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

class ScatterPlotComboLineChartPage extends StatefulWidget {
  const ScatterPlotComboLineChartPage({super.key});

  @override
  State<ScatterPlotComboLineChartPage> createState() =>
      _ScatterPlotComboLineChartPageState();
}

class _ScatterPlotComboLineChartPageState
    extends State<ScatterPlotComboLineChartPage> {
  bool _hasAnimation = true;

  void _updateRandomData() {
    _data = ScatterPlotComboLineChart.createRandomData();
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
          title: ScatterPlotComboLineChart.title,
          subtitle: ScatterPlotComboLineChart.subtitle,
          body: (context) => ScatterPlotComboLineChart(
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

class ScatterPlotComboLineChartBuilder extends ExampleBuilder {
  const ScatterPlotComboLineChartBuilder();

  @override
  Widget page([int? index, List<ExampleBuilder>? children]) =>
      const ScatterPlotComboLineChartPage();

  @override
  String? get subtitle => ScatterPlotComboLineChart.subtitle;

  @override
  String get title => ScatterPlotComboLineChart.title;

  @override
  Widget withSampleData([bool animate = true]) =>
      ScatterPlotComboLineChart.withSampleData(animate);
}

/// Example of a combo scatter plot chart with a second series rendered as a
/// line.
class ScatterPlotComboLineChart extends StatelessWidget {
  const ScatterPlotComboLineChart(
    this.seriesList, {
    this.animate = true,
    super.key,
  });

  /// Creates a [ScatterPlotChart] with sample data and no transition.
  factory ScatterPlotComboLineChart.withSampleData([bool animate = true]) {
    return ScatterPlotComboLineChart(
      createSampleData(),
      animate: animate,
    );
  }

  static String get title => 'Scatter Plot';
  static String? get subtitle => 'Scatter plot combo chart with a line';

  final List<charts.Series<dynamic, num>> seriesList;
  final bool animate;

  /// Create random data.
  static List<charts.Series<LinearSales, num>> createRandomData() {
    final random = Random();

    double makeRadius(int value) => (random.nextInt(value) + 2).toDouble();

    final desktopSalesData = [
      LinearSales(random.nextInt(100), random.nextInt(100), makeRadius(6)),
      LinearSales(random.nextInt(100), random.nextInt(100), makeRadius(6)),
      LinearSales(random.nextInt(100), random.nextInt(100), makeRadius(6)),
      LinearSales(random.nextInt(100), random.nextInt(100), makeRadius(6)),
      LinearSales(random.nextInt(100), random.nextInt(100), makeRadius(6)),
      LinearSales(random.nextInt(100), random.nextInt(100), makeRadius(6)),
      LinearSales(random.nextInt(100), random.nextInt(100), makeRadius(6)),
      LinearSales(random.nextInt(100), random.nextInt(100), makeRadius(6)),
      LinearSales(random.nextInt(100), random.nextInt(100), makeRadius(6)),
      LinearSales(random.nextInt(100), random.nextInt(100), makeRadius(6)),
      LinearSales(random.nextInt(100), random.nextInt(100), makeRadius(6)),
      LinearSales(random.nextInt(100), random.nextInt(100), makeRadius(6)),
    ];

    final myRegressionData = [
      LinearSales(0, desktopSalesData[0].sales, 3.5),
      LinearSales(
          100, desktopSalesData[desktopSalesData.length - 1].sales, 7.5),
    ];

    const maxMeasure = 100;

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
        measure: (LinearSales sales, _) => sales.sales,
        // Providing a radius function is optional.
        radius: (LinearSales sales, _) => sales.radius,
        data: desktopSalesData,
      ),
      charts.Series<LinearSales, int>(
        id: 'Mobile',
        color: (_, __) => charts.DesktopPalette.purple.shadeDefault,
        domain: (LinearSales sales, _) => sales.year,
        measure: (LinearSales sales, _) => sales.sales,
        data: myRegressionData,
      )
        // Configure our custom line renderer for this series.
        ..setAttribute(charts.rendererIdKey, 'customLine'),
    ];
  }

  /// Create one series with sample hard coded data.
  static List<charts.Series<LinearSales, int>> createSampleData() {
    const desktopSalesData = [
      LinearSales(0, 5, 3.0),
      LinearSales(10, 25, 5.0),
      LinearSales(12, 75, 4.0),
      LinearSales(13, 225, 5.0),
      LinearSales(16, 50, 4.0),
      LinearSales(24, 75, 3.0),
      LinearSales(25, 100, 3.0),
      LinearSales(34, 150, 5.0),
      LinearSales(37, 10, 4.5),
      LinearSales(45, 300, 8.0),
      LinearSales(52, 15, 4.0),
      LinearSales(56, 200, 7.0),
    ];

    const myRegressionData = [
      LinearSales(0, 5, 3.5),
      LinearSales(56, 240, 3.5),
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
        measure: (LinearSales sales, _) => sales.sales,
        // Providing a radius function is optional.
        radius: (LinearSales sales, _) => sales.radius,
        data: desktopSalesData,
      ),
      charts.Series<LinearSales, int>(
        id: 'Mobile',
        color: (_, __) => charts.DesktopPalette.purple.shadeDefault,
        domain: (LinearSales sales, _) => sales.year,
        measure: (LinearSales sales, _) => sales.sales,
        data: myRegressionData,
      )
        // Configure our custom line renderer for this series.
        ..setAttribute(charts.rendererIdKey, 'customLine'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return charts.ScatterPlotChart(
      seriesList,
      animate: animate,
      // Configure the default renderer as a point renderer. This will be used
      // for any series that does not define a rendererIdKey.
      //
      // This is the default configuration, but is shown here for
      // illustration.
      defaultRenderer: const charts.PointRendererConfig(),
      // Custom renderer configuration for the line series.
      customSeriesRenderers: const [
        charts.LineRendererConfig(
          // ID used to link series to this renderer.
          customRendererId: 'customLine',
        ),
      ],
    );
  }
}

/// Sample linear data type.
@immutable
class LinearSales {
  const LinearSales(this.year, this.sales, this.radius);

  final int year;
  final int sales;
  final double radius;
}
