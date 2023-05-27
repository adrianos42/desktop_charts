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

class DonutAutoLabelChartPage extends StatefulWidget {
  const DonutAutoLabelChartPage({super.key});

  @override
  State<DonutAutoLabelChartPage> createState() =>
      _DonutAutoLabelChartPageState();
}

class _DonutAutoLabelChartPageState extends State<DonutAutoLabelChartPage> {
  bool _hasAnimation = true;

  void _updateRandomData() {
    _data = DonutAutoLabelChart.createRandomData();
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
          title: DonutAutoLabelChart.title,
          subtitle: DonutAutoLabelChart.subtitle,
          body: (context) => DonutAutoLabelChart(
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

class DonutAutoLabelChartBuilder extends ExampleBuilder {
  const DonutAutoLabelChartBuilder();

  @override
  Widget page([int? index, List<ExampleBuilder>? children]) =>
      const DonutAutoLabelChartPage();

  @override
  String? get subtitle => DonutAutoLabelChart.subtitle;

  @override
  String get title => DonutAutoLabelChart.title;

  @override
  Widget withSampleData([bool animate = true]) =>
      DonutAutoLabelChart.withSampleData(animate);
}

/// Donut chart with labels example. This is a simple pie chart with a hole in
/// the middle.
class DonutAutoLabelChart extends StatelessWidget {
  const DonutAutoLabelChart(
    this.seriesList, {
    this.animate = true,
    super.key,
  });

  /// Creates a [PieChart] with sample data and no transition.
  factory DonutAutoLabelChart.withSampleData([bool animate = true]) {
    return DonutAutoLabelChart(
      createSampleData(),
      animate: animate,
    );
  }

  static String get title => 'Auto Label Donut';
  static String? get subtitle =>
      'With a single series, a hole in the middle, and auto-positioned labels';

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
        // Set a label accessor to control the text of the arc label.
        labelAccessor: (LinearSales row, _) => '${row.year}: ${row.sales}',
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
        // Set a label accessor to control the text of the arc label.
        labelAccessor: (LinearSales row, _) => '${row.year}: ${row.sales}',
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
      //
      // [ArcLabelDecorator] will automatically position the label inside the
      // arc if the label will fit. If the label will not fit, it will draw
      // outside of the arc with a leader line. Labels can always display
      // inside or outside using [LabelPosition].
      //
      // Text style for inside / outside can be controlled independently by
      // setting [insideLabelStyleSpec] and [outsideLabelStyleSpec].
      //
      // Example configuring different styles for inside/outside:
      //       charts.ArcLabelDecorator(
      //          insideLabelStyleSpec: charts.TextStyleSpec(...),
      //          outsideLabelStyleSpec: charts.TextStyleSpec(...)),
      defaultRenderer: charts.ArcRendererConfig(
        arcWidth: 60,
        arcRendererDecorators: [
          charts.ArcLabelDecorator(),
        ],
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
