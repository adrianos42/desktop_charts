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

class SegmentsLineChartPage extends StatefulWidget {
  const SegmentsLineChartPage({super.key});

  @override
  State<SegmentsLineChartPage> createState() => _SegmentsLineChartPageState();
}

class _SegmentsLineChartPageState extends State<SegmentsLineChartPage> {
  bool _hasAnimation = true;

  void _updateRandomData() {
    _data = SegmentsLineChart.createRandomData();
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
          title: SegmentsLineChart.title,
          subtitle: SegmentsLineChart.subtitle,
          body: (context) => SegmentsLineChart(
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

class SegmentsLineChartBuilder extends ExampleBuilder {
  const SegmentsLineChartBuilder();

  @override
  Widget page([int? index, List<ExampleBuilder>? children]) =>
      const SegmentsLineChartPage();

  @override
  String? get subtitle => SegmentsLineChart.subtitle;

  @override
  String get title => SegmentsLineChart.title;

  @override
  Widget withSampleData([bool animate = true]) =>
      SegmentsLineChart.withSampleData(animate);
}

/// Example of a stacked area chart with changing styles within each line.
///
/// Each series of data in this example contains different values for color,
/// dashPattern, or strokeWidthPx between each datum. The line and area skirt
/// will be rendered in segments, with the styling of the series changing when
/// these data attributes change.
///
/// Note that if a dashPattern or strokeWidth value is not found for a
/// particular datum, then the chart will fall back to use the value defined in
/// the [charts.LineRendererConfig]. This could be used, for example, to define
/// a default dash pattern for the series, with only a specific datum called out
/// with a different pattern.
@immutable
class SegmentsLineChart extends StatelessWidget {
  const SegmentsLineChart(
    this.seriesList, {
    this.animate = true,
    super.key,
  });

  /// Creates a [LineChart] with sample data and no transition.
  factory SegmentsLineChart.withSampleData([bool animate = true]) {
    return SegmentsLineChart(
      createSampleData(),
      animate: animate,
    );
  }

  static String get title => 'Segments';
  static String? get subtitle =>
      'Line chart with changes of style for each line';

  final List<charts.Series<dynamic, num>> seriesList;
  final bool animate;

  /// Create random data.
  static List<charts.Series<LinearSales, int>> createRandomData() {
    final random = Random();

    // Series of data with static dash pattern and stroke width. The color
    // accessor will colorize each datum (for all three series).
    final colorChangeData = [
      LinearSales(0, random.nextInt(100), null, 2.0),
      LinearSales(1, random.nextInt(100), null, 2.0),
      LinearSales(2, random.nextInt(100), null, 2.0),
      LinearSales(3, random.nextInt(100), null, 2.0),
      LinearSales(4, random.nextInt(100), null, 2.0),
      LinearSales(5, random.nextInt(100), null, 2.0),
      LinearSales(6, random.nextInt(100), null, 2.0),
    ];

    // Series of data with changing color and dash pattern.
    final dashPatternChangeData = [
      LinearSales(0, random.nextInt(100), const [2, 2], 2.0),
      LinearSales(1, random.nextInt(100), const [2, 2], 2.0),
      LinearSales(2, random.nextInt(100), const [4, 4], 2.0),
      LinearSales(3, random.nextInt(100), const [4, 4], 2.0),
      LinearSales(4, random.nextInt(100), const [4, 4], 2.0),
      LinearSales(5, random.nextInt(100), const [8, 3, 2, 3], 2.0),
      LinearSales(6, random.nextInt(100), const [8, 3, 2, 3], 2.0),
    ];

    // Series of data with changing color and stroke width.
    final strokeWidthChangeData = [
      LinearSales(0, random.nextInt(100), null, 2.0),
      LinearSales(1, random.nextInt(100), null, 2.0),
      LinearSales(2, random.nextInt(100), null, 4.0),
      LinearSales(3, random.nextInt(100), null, 4.0),
      LinearSales(4, random.nextInt(100), null, 4.0),
      LinearSales(5, random.nextInt(100), null, 6.0),
      LinearSales(6, random.nextInt(100), null, 6.0),
    ];

    // Generate 2 shades of each color so that we can style the line segments.
    final blue = charts.DesktopPalette.blue.makeShades(2);
    final red = charts.DesktopPalette.red.makeShades(2);
    final green = charts.DesktopPalette.green.makeShades(2);

    return [
      charts.Series<LinearSales, int>(
        id: 'Color Change',
        // Light shade for even years, dark shade for odd.
        color: (LinearSales sales, _) => sales.year.isEven ? blue[1] : blue[0],
        dashPattern: (LinearSales sales, _) => sales.dashPattern,
        strokeWidth: (LinearSales sales, _) => sales.strokeWidth,
        domain: (LinearSales sales, _) => sales.year,
        measure: (LinearSales sales, _) => sales.sales,
        data: colorChangeData,
      ),
      charts.Series<LinearSales, int>(
        id: 'Dash Pattern Change',
        // Light shade for even years, dark shade for odd.
        color: (LinearSales sales, _) => sales.year.isEven ? red[1] : red[0],
        dashPattern: (LinearSales sales, _) => sales.dashPattern,
        strokeWidth: (LinearSales sales, _) => sales.strokeWidth,
        domain: (LinearSales sales, _) => sales.year,
        measure: (LinearSales sales, _) => sales.sales,
        data: dashPatternChangeData,
      ),
      charts.Series<LinearSales, int>(
        id: 'Stroke Width Change',
        // Light shade for even years, dark shade for odd.
        color: (LinearSales sales, _) =>
            sales.year.isEven ? green[1] : green[0],
        dashPattern: (LinearSales sales, _) => sales.dashPattern,
        strokeWidth: (LinearSales sales, _) => sales.strokeWidth,
        domain: (LinearSales sales, _) => sales.year,
        measure: (LinearSales sales, _) => sales.sales,
        data: strokeWidthChangeData,
      ),
    ];
  }

  /// Create one series with sample hard coded data.
  static List<charts.Series<LinearSales, int>> createSampleData() {
    // Series of data with static dash pattern and stroke width. The color
    // accessor will colorize each datum (for all three series).
    const colorChangeData = [
      LinearSales(0, 5, null, 2.0),
      LinearSales(1, 15, null, 2.0),
      LinearSales(2, 25, null, 2.0),
      LinearSales(3, 75, null, 2.0),
      LinearSales(4, 100, null, 2.0),
      LinearSales(5, 90, null, 2.0),
      LinearSales(6, 75, null, 2.0),
    ];

    // Series of data with changing color and dash pattern.
    const dashPatternChangeData = [
      LinearSales(0, 5, [2, 2], 2.0),
      LinearSales(1, 15, [2, 2], 2.0),
      LinearSales(2, 25, [4, 4], 2.0),
      LinearSales(3, 75, [4, 4], 2.0),
      LinearSales(4, 100, [4, 4], 2.0),
      LinearSales(5, 90, [8, 3, 2, 3], 2.0),
      LinearSales(6, 75, [8, 3, 2, 3], 2.0),
    ];

    // Series of data with changing color and stroke width.
    const strokeWidthChangeData = [
      LinearSales(0, 5, null, 2.0),
      LinearSales(1, 15, null, 2.0),
      LinearSales(2, 25, null, 4.0),
      LinearSales(3, 75, null, 4.0),
      LinearSales(4, 100, null, 4.0),
      LinearSales(5, 90, null, 6.0),
      LinearSales(6, 75, null, 6.0),
    ];

    // Generate 2 shades of each color so that we can style the line segments.
    final blue = charts.DesktopPalette.blue.makeShades(2);
    final red = charts.DesktopPalette.red.makeShades(2);
    final green = charts.DesktopPalette.green.makeShades(2);

    return [
      charts.Series<LinearSales, int>(
        id: 'Color Change',
        // Light shade for even years, dark shade for odd.
        color: (LinearSales sales, _) => sales.year.isEven ? blue[1] : blue[0],
        dashPattern: (LinearSales sales, _) => sales.dashPattern,
        strokeWidth: (LinearSales sales, _) => sales.strokeWidth,
        domain: (LinearSales sales, _) => sales.year,
        measure: (LinearSales sales, _) => sales.sales,
        data: colorChangeData,
      ),
      charts.Series<LinearSales, int>(
        id: 'Dash Pattern Change',
        // Light shade for even years, dark shade for odd.
        color: (LinearSales sales, _) => sales.year.isEven ? red[1] : red[0],
        dashPattern: (LinearSales sales, _) => sales.dashPattern,
        strokeWidth: (LinearSales sales, _) => sales.strokeWidth,
        domain: (LinearSales sales, _) => sales.year,
        measure: (LinearSales sales, _) => sales.sales,
        data: dashPatternChangeData,
      ),
      charts.Series<LinearSales, int>(
        id: 'Stroke Width Change',
        // Light shade for even years, dark shade for odd.
        color: (LinearSales sales, _) =>
            sales.year.isEven ? green[1] : green[0],
        dashPattern: (LinearSales sales, _) => sales.dashPattern,
        strokeWidth: (LinearSales sales, _) => sales.strokeWidth,
        domain: (LinearSales sales, _) => sales.year,
        measure: (LinearSales sales, _) => sales.sales,
        data: strokeWidthChangeData,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return charts.LineChart(
      seriesList,
      defaultRenderer: const charts.LineRendererConfig(
        includeArea: true,
        stacked: true,
      ),
      animate: animate,
    );
  }
}

/// Sample linear data type.
@immutable
class LinearSales {
  const LinearSales(this.year, this.sales, this.dashPattern, this.strokeWidth);

  final int year;
  final int sales;
  final List<int>? dashPattern;
  final double strokeWidth;
}
