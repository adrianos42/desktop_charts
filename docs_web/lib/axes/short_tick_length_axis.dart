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

class ShortTickLengthAxisPage extends StatefulWidget {
  const ShortTickLengthAxisPage({super.key});

  @override
  State<ShortTickLengthAxisPage> createState() =>
      _ShortTickLengthAxisPageState();
}

class _ShortTickLengthAxisPageState extends State<ShortTickLengthAxisPage> {
  bool _hasAnimation = true;

  void _updateRandomData() {
    _data = ShortTickLengthAxis.createRandomData();
  }

  void _refresh() {
    setState(() => _updateRandomData());
  }

  @override
  void initState() {
    super.initState();

    _updateRandomData();
  }

  late List<charts.Series<OrdinalSales, String>> _data;

  @override
  Widget build(BuildContext context) {
    return Defaults(
      header: 'Axes',
      items: [
        ItemTitle(
          title: ShortTickLengthAxis.title,
          subtitle: ShortTickLengthAxis.subtitle,
          body: (context) => ShortTickLengthAxis(
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

class ShortTickLengthAxisBuilder extends ExampleBuilder {
  const ShortTickLengthAxisBuilder();

  @override
  Widget page([int? index, List<ExampleBuilder>? children]) =>
      const ShortTickLengthAxisPage();

  @override
  String? get subtitle => ShortTickLengthAxis.subtitle;

  @override
  String get title => ShortTickLengthAxis.title;

  @override
  Widget withSampleData([bool animate = true]) =>
      ShortTickLengthAxis.withSampleData(animate);
}

/// Custom Tick Style Example
///
/// Example of using a custom primary measure axis replacing the default
/// gridline rendering with a short tick rendering. It also turns on the axis
/// line so that the ticks have something to line up against.
///
/// There are many axis styling options in the SmallTickRenderer allowing you
/// to customize the font, tick lengths, and offsets.
class ShortTickLengthAxis extends StatelessWidget {
  const ShortTickLengthAxis(
    this.seriesList, {
    this.animate = true,
    super.key,
  });

  factory ShortTickLengthAxis.withSampleData([bool animate = true]) {
    return ShortTickLengthAxis(
      createSampleData(),
      animate: animate,
    );
  }

  static String get title => 'Short Ticks Axis';
  static String? get subtitle =>
      'Bar chart with the primary measure axis having short ticks';

  final List<charts.Series<dynamic, String>> seriesList;
  final bool animate;

  /// Create random data.
  static List<charts.Series<OrdinalSales, String>> createRandomData() {
    final random = Random();

    final globalSalesData = [
      OrdinalSales('2014', random.nextInt(100) * 100),
      OrdinalSales('2015', random.nextInt(100) * 100),
      OrdinalSales('2016', random.nextInt(100) * 100),
      OrdinalSales('2017', random.nextInt(100) * 100),
    ];

    return [
      charts.Series<OrdinalSales, String>(
        id: 'Global Revenue',
        domain: (OrdinalSales sales, _) => sales.year,
        measure: (OrdinalSales sales, _) => sales.sales,
        data: globalSalesData,
      ),
    ];
  }

  /// Create series list with single series
  static List<charts.Series<OrdinalSales, String>> createSampleData() {
    const globalSalesData = [
      OrdinalSales('2014', 5000),
      OrdinalSales('2015', 25000),
      OrdinalSales('2016', 100000),
      OrdinalSales('2017', 750000),
    ];

    return [
      charts.Series<OrdinalSales, String>(
        id: 'Global Revenue',
        domain: (OrdinalSales sales, _) => sales.year,
        measure: (OrdinalSales sales, _) => sales.sales,
        data: globalSalesData,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return charts.BarChart(
      seriesList,
      animate: animate,

      /// Customize the primary measure axis using a small tick renderer.
      /// Note: use String instead of num for ordinal domain axis
      /// (typically bar charts).
      primaryMeasureAxis: const charts.NumericAxisSpec(
        renderSpec: charts.SmallTickRendererSpec(
            // Tick and Label styling here.
            ),
      ),
    );
  }
}

/// Sample ordinal data type.
@immutable
class OrdinalSales {
  const OrdinalSales(this.year, this.sales);

  final String year;
  final int sales;
}
