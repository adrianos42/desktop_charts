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

class NumericInitialViewportPage extends StatefulWidget {
  const NumericInitialViewportPage({super.key});

  @override
  State<NumericInitialViewportPage> createState() =>
      _NumericInitialViewportPageState();
}

class _NumericInitialViewportPageState
    extends State<NumericInitialViewportPage> {
  bool _hasAnimation = true;

  void _updateRandomData() {
    _data = NumericInitialViewport.createRandomData();
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
      header: 'Axes',
      items: [
        ItemTitle(
          title: NumericInitialViewport.title,
          subtitle: NumericInitialViewport.subtitle,
          body: (context) => NumericInitialViewport(
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

class NumericInitialViewportBuilder extends ExampleBuilder {
  const NumericInitialViewportBuilder();

  @override
  Widget page([int? index, List<ExampleBuilder>? children]) =>
      const NumericInitialViewportPage();

  @override
  String? get subtitle => NumericInitialViewport.subtitle;

  @override
  String get title => NumericInitialViewport.title;

  @override
  Widget withSampleData([bool animate = true]) =>
      NumericInitialViewport.withSampleData(animate);
}

/// Example of setting an initial viewport for ordinal axis.
///
/// This allows for specifying the specific range of data to show that differs
/// from what was provided in the series list.
///
/// In this example, the series list has numeric data from 0 to 10, but we
/// want to show from 3 to 7.
/// We can do this by specifying an [NumericExtents] in [NumericAxisSpec].
class NumericInitialViewport extends StatelessWidget {
  const NumericInitialViewport(
    this.seriesList, {
    this.animate = true,
    super.key,
  });

  /// Creates a [LineChart] with sample data and no transition.
  factory NumericInitialViewport.withSampleData([bool animate = true]) {
    return NumericInitialViewport(
      createSampleData(),
      animate: animate,
    );
  }

  static String get title => 'Numeric axis with initial viewport';
  static String? get subtitle =>
      'Initial viewport is set to a subset of the data';

  final List<charts.Series<dynamic, num>> seriesList;
  final bool animate;

  /// Create random data.
  static List<charts.Series<LinearSales, num>> createRandomData() {
    final random = Random();

    final data = [
      LinearSales(0, random.nextInt(100)),
      LinearSales(1, random.nextInt(100)),
      LinearSales(2, random.nextInt(100)),
      LinearSales(3, random.nextInt(100)),
      LinearSales(4, random.nextInt(100)),
      LinearSales(5, random.nextInt(100)),
      LinearSales(6, random.nextInt(100)),
      LinearSales(7, random.nextInt(100)),
      LinearSales(8, random.nextInt(100)),
      LinearSales(9, random.nextInt(100)),
      LinearSales(10, random.nextInt(100)),
    ];

    return [
      charts.Series<LinearSales, int>(
        id: 'Sales',
        color: (_, __) => charts.DesktopPalette.blue.shadeDefault,
        domain: (LinearSales sales, _) => sales.year,
        measure: (LinearSales sales, _) => sales.sales,
        data: data,
      )
    ];
  }

  /// Create one series with sample hard coded data.
  static List<charts.Series<LinearSales, int>> createSampleData() {
    const data = [
      LinearSales(0, 5),
      LinearSales(1, 25),
      LinearSales(2, 100),
      LinearSales(3, 75),
      LinearSales(4, 55),
      LinearSales(5, 66),
      LinearSales(6, 110),
      LinearSales(7, 70),
      LinearSales(8, 20),
      LinearSales(9, 25),
      LinearSales(10, 45),
    ];

    return [
      charts.Series<LinearSales, int>(
        id: 'Sales',
        color: (_, __) => charts.DesktopPalette.blue.shadeDefault,
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
      domainAxis: const charts.NumericAxisSpec(
        // Set the initial viewport by providing a AxisSpec with the
        // desired viewport, in NumericExtents.
        viewport: charts.NumericExtents(3.0, 7.0),
      ),
      // Optionally add a pan or pan and zoom behavior.
      // If pan/zoom is not added, the viewport specified remains the viewport.
      behaviors: const [charts.PanAndZoomBehavior()],
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
