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

class LineAnimationZoomChartPage extends StatefulWidget {
  const LineAnimationZoomChartPage({super.key});

  @override
  State<LineAnimationZoomChartPage> createState() =>
      _LineAnimationZoomChartPageState();
}

class _LineAnimationZoomChartPageState
    extends State<LineAnimationZoomChartPage> {
  bool _hasAnimation = true;

  void _updateRandomData() {
    _data = LineAnimationZoomChart.createRandomData();
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
          title: LineAnimationZoomChart.title,
          subtitle: LineAnimationZoomChart.subtitle,
          body: (context) => LineAnimationZoomChart(
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

class LineAnimationZoomChartBuilder extends ExampleBuilder {
  const LineAnimationZoomChartBuilder();

  @override
  Widget page([int? index, List<ExampleBuilder>? children]) =>
      const LineAnimationZoomChartPage();

  @override
  String? get subtitle => LineAnimationZoomChart.subtitle;

  @override
  String get title => LineAnimationZoomChart.title;

  @override
  Widget withSampleData([bool animate = true]) =>
      LineAnimationZoomChart.withSampleData(animate);
}

/// Example of a line chart with pan and zoom enabled via
/// [Charts.PanAndZoomBehavior].
@immutable
class LineAnimationZoomChart extends StatelessWidget {
  const LineAnimationZoomChart(
    this.seriesList, {
    this.animate = true,
    super.key,
  });

  /// Creates a [LineChart] with sample data and no transition.
  factory LineAnimationZoomChart.withSampleData([bool animate = true]) {
    return LineAnimationZoomChart(
      createSampleData(),
      animate: animate,
    );
  }

  static String get title => 'Pan and Zoom';
  static String? get subtitle =>
      'Simple line chart pan and zoom behaviors enabled';

  final List<charts.Series<dynamic, num>> seriesList;
  final bool animate;

  /// Create random data.
  static List<charts.Series<LinearSales, int>> createRandomData() {
    final random = Random();

    final data = List<LinearSales>.generate(
      100,
      (index) => LinearSales(index, random.nextInt(100)),
    );

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
    const values = [
      42,
      90,
      17,
      11,
      64,
      13,
      45,
      86,
      48,
      40,
      85,
      14,
      77,
      89,
      47,
      41,
      18,
      73,
      53,
      69,
      2,
      55,
      5,
      50,
      90,
      91,
      20,
      69,
      84,
      46,
      50,
      13,
      98,
      13,
      54,
      36,
      80,
      69,
      41,
      26,
      31,
      20,
      99,
      29,
      21,
      53,
      80,
      81,
      27,
      91,
      30,
      69,
      97,
      22,
      66,
      20,
      47,
      31,
      39,
      26,
      19,
      89,
      11,
      40,
      42,
      31,
      96,
      65,
      11,
      3,
      50,
      66,
      64,
      69,
      82,
      2,
      86,
      25,
      77,
      70,
      6,
      18,
      21,
      67,
      31,
      89,
      38,
      90,
      19,
      55,
      55,
      2,
      17,
      50,
      59,
      66,
      58,
      11,
      77,
      21,
    ];

    final data = List<LinearSales>.generate(
      100,
      (index) => LinearSales(index, values[index]),
    );

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
    return charts.LineChart(
      seriesList,
      animate: animate,
      behaviors: const [
        charts.PanAndZoomBehavior(),
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
