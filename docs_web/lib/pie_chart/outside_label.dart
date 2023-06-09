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

class PieOutsideLabelChartPage extends StatefulWidget {
  const PieOutsideLabelChartPage({super.key});

  @override
  State<PieOutsideLabelChartPage> createState() =>
      _PieOutsideLabelChartPageState();
}

class _PieOutsideLabelChartPageState extends State<PieOutsideLabelChartPage> {
  bool _hasAnimation = true;

  void _updateRandomData() {
    _data = PieOutsideLabelChart.createRandomData();
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
          title: PieOutsideLabelChart.title,
          subtitle: PieOutsideLabelChart.subtitle,
          body: (context) => PieOutsideLabelChart(
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

class PieOutsideLabelChartBuilder extends ExampleBuilder {
  const PieOutsideLabelChartBuilder();

  @override
  Widget page([int? index, List<ExampleBuilder>? children]) =>
      const PieOutsideLabelChartPage();

  @override
  String? get subtitle => PieOutsideLabelChart.subtitle;

  @override
  String get title => PieOutsideLabelChart.title;

  @override
  Widget withSampleData([bool animate = true]) =>
      PieOutsideLabelChart.withSampleData(animate);
}

/// Simple pie chart with outside labels example.
class PieOutsideLabelChart extends StatelessWidget {
  const PieOutsideLabelChart(
    this.seriesList, {
    this.animate = true,
    super.key,
  });

  /// Creates a [PieChart] with sample data and no transition.
  factory PieOutsideLabelChart.withSampleData([bool animate = true]) {
    return PieOutsideLabelChart(
      createSampleData(),
      animate: animate,
    );
  }

  static String get title => 'Outside Label';
  static String? get subtitle =>
      'With a single series and labels outside the arcs';

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
      // Add an [ArcLabelDecorator] configured to render labels outside of the
      // arc with a leader line.
      //
      // Text style for inside / outside can be controlled independently by
      // setting [insideLabelStyleSpec] and [outsideLabelStyleSpec].
      //
      // Example configuring different styles for inside/outside:
      //       charts.ArcLabelDecorator(
      //          insideLabelStyleSpec: charts.TextStyleSpec(...),
      //          outsideLabelStyleSpec: charts.TextStyleSpec(...)),
      defaultRenderer: charts.ArcRendererConfig(
        arcRendererDecorators: [
          charts.ArcLabelDecorator(
            labelPosition: charts.ArcLabelPosition.outside,
          )
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
