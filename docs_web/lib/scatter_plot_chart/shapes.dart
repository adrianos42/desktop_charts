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

class ShapesScatterPlotChartPage extends StatefulWidget {
  const ShapesScatterPlotChartPage({super.key});

  @override
  State<ShapesScatterPlotChartPage> createState() =>
      _ShapesScatterPlotChartPageState();
}

class _ShapesScatterPlotChartPageState
    extends State<ShapesScatterPlotChartPage> {
  bool _hasAnimation = true;

  void _updateRandomData() {
    _data = ShapesScatterPlotChart.createRandomData();
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
          title: ShapesScatterPlotChart.title,
          subtitle: ShapesScatterPlotChart.subtitle,
          body: (context) => ShapesScatterPlotChart(
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

class ShapesScatterPlotChartBuilder extends ExampleBuilder {
  const ShapesScatterPlotChartBuilder();

  @override
  Widget page([int? index, List<ExampleBuilder>? children]) =>
      const ShapesScatterPlotChartPage();

  @override
  String? get subtitle => ShapesScatterPlotChart.subtitle;

  @override
  String get title => ShapesScatterPlotChart.title;

  @override
  Widget withSampleData([bool animate = true]) =>
      ShapesScatterPlotChart.withSampleData(animate);
}

/// Example of a scatter plot chart using custom symbols for the points.
///
/// The series has been configured to draw each point as a square by default.
///
/// Some data will be drawn as a circle, indicated by defining a custom "circle"
/// value referenced by [pointSymbolRendererKey].
///
/// Some other data have will be drawn as a hollow circle. In addition to the
/// custom renderer key, these data also have stroke and fillColor values
/// defined. Configuring a separate fillColor will cause the center of the shape
/// to be filled in, with white in these examples. The border of the shape will
/// be color with the color of the data.
class ShapesScatterPlotChart extends StatelessWidget {
  const ShapesScatterPlotChart(
    this.seriesList, {
    this.animate = true,
    super.key,
  });

  /// Creates a [ScatterPlotChart] with sample data and no transition.
  factory ShapesScatterPlotChart.withSampleData([
    bool animate = true,
  ]) {
    return ShapesScatterPlotChart(
      createSampleData(),
      animate: animate,
    );
  }

  static String get title => 'Shapes';
  static String? get subtitle => 'With custom shapes';

  final List<charts.Series<dynamic, num>> seriesList;
  final bool animate;

  /// Create random data.
  static List<charts.Series<LinearSales, int>> createRandomData() {
    final random = Random();

    double makeRadius(int value) => (random.nextInt(value) + 2).toDouble();

    final data = [
      LinearSales(
        random.nextInt(100),
        random.nextInt(100),
        makeRadius(6),
        'circle',
        null,
        null,
      ),
      LinearSales(
        random.nextInt(100),
        random.nextInt(100),
        makeRadius(6),
        null,
        null,
        null,
      ),
      LinearSales(
        random.nextInt(100),
        random.nextInt(100),
        makeRadius(6),
        null,
        null,
        null,
      ),
      // Render a hollow circle, filled in with white.
      LinearSales(
        random.nextInt(100),
        random.nextInt(100),
        makeRadius(4) + 4,
        'circle',
        charts.DesktopPalette.foreground,
        2.0,
      ),
      LinearSales(
        random.nextInt(100),
        random.nextInt(100),
        makeRadius(6),
        null,
        null,
        null,
      ),
      LinearSales(
        random.nextInt(100),
        random.nextInt(100),
        makeRadius(6),
        null,
        null,
        null,
      ),
      LinearSales(
        random.nextInt(100),
        random.nextInt(100),
        makeRadius(6),
        'circle',
        null,
        null,
      ),
      LinearSales(
        random.nextInt(100),
        random.nextInt(100),
        makeRadius(6),
        null,
        null,
        null,
      ),
      LinearSales(
        random.nextInt(100),
        random.nextInt(100),
        makeRadius(6),
        null,
        null,
        null,
      ),
      // Render a hollow circle, filled in with white.
      LinearSales(
        random.nextInt(100),
        random.nextInt(100),
        makeRadius(4) + 4,
        'circle',
        charts.DesktopPalette.foreground,
        2.0,
      ),
      LinearSales(
        random.nextInt(100),
        random.nextInt(100),
        makeRadius(6),
        null,
        null,
        null,
      ),
      // Render a hollow square, filled in with white.
      LinearSales(
        random.nextInt(100),
        random.nextInt(100),
        makeRadius(4) + 4,
        null,
        charts.DesktopPalette.foreground,
        2.0,
      ),
    ];

    const maxMeasure = 100;

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
        measure: (LinearSales sales, _) => sales.sales,
        radius: (LinearSales sales, _) => sales.radius,
        fillColor: (LinearSales row, _) => row.fillColor,
        strokeWidth: (LinearSales row, _) => row.strokeWidth,
        data: data,
      )
        // Accessor function that associates each datum with a symbol renderer.
        ..setAttribute(
            charts.pointSymbolRendererFnKey, (int? index) => data[index!].shape)
        // Default symbol renderer ID for data that have no defined shape.
        ..setAttribute(charts.pointSymbolRendererIdKey, 'rect')
    ];
  }

  /// Create one series with sample hard coded data.
  static List<charts.Series<LinearSales, int>> createSampleData() {
    final data = [
      const LinearSales(0, 5, 3.0, 'circle', null, null),
      const LinearSales(10, 25, 5.0, null, null, null),
      const LinearSales(12, 75, 4.0, null, null, null),
      // Render a hollow circle, filled in with white.
      LinearSales(
          13, 225, 5.0, 'circle', charts.DesktopPalette.foreground, 2.0),
      const LinearSales(16, 50, 4.0, null, null, null),
      const LinearSales(24, 75, 3.0, null, null, null),
      const LinearSales(25, 100, 3.0, 'circle', null, null),
      const LinearSales(34, 150, 5.0, null, null, null),
      const LinearSales(37, 10, 4.5, null, null, null),
      // Render a hollow circle, filled in with white.
      LinearSales(
        45,
        300,
        8.0,
        'circle',
        charts.DesktopPalette.foreground,
        2.0,
      ),
      const LinearSales(52, 15, 4.0, null, null, null),
      // Render a hollow square, filled in with white.
      LinearSales(56, 200, 7.0, null, charts.DesktopPalette.foreground, 2.0),
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
        radius: (LinearSales sales, _) => sales.radius,
        fillColor: (LinearSales row, _) => row.fillColor,
        strokeWidth: (LinearSales row, _) => row.strokeWidth,
        data: data,
      )
        // Accessor function that associates each datum with a symbol renderer.
        ..setAttribute(
            charts.pointSymbolRendererFnKey, (int? index) => data[index!].shape)
        // Default symbol renderer ID for data that have no defined shape.
        ..setAttribute(charts.pointSymbolRendererIdKey, 'rect')
    ];
  }

  @override
  Widget build(BuildContext context) {
    return charts.ScatterPlotChart(
      seriesList,
      animate: animate,
      // Configure the point renderer to have a map of custom symbol
      // renderers.
      defaultRenderer: const charts.PointRendererConfig<num>(
        customSymbolRenderers: {
          'circle': charts.CircleSymbolRenderer(),
          'rect': charts.RectSymbolRenderer(),
        },
      ),
    );
  }
}

/// Sample linear data type.
@immutable
class LinearSales {
  const LinearSales(
    this.year,
    this.sales,
    this.radius,
    this.shape,
    this.fillColor,
    this.strokeWidth,
  );

  final int year;
  final int sales;
  final double radius;
  final String? shape;
  final Color? fillColor;
  final double? strokeWidth;
}
