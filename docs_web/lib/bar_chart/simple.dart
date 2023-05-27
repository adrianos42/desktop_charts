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

class SimpleBarChartPage extends StatefulWidget {
  const SimpleBarChartPage({super.key});

  @override
  State<SimpleBarChartPage> createState() => _SimpleBarChartPageState();
}

class _SimpleBarChartPageState extends State<SimpleBarChartPage> {
  bool _hasAnimation = true;

  void _updateRandomData() {
    _data = SimpleBarChart.createRandomData();
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
      header: 'Bar',
      items: [
        ItemTitle(
          title: SimpleBarChart.title,
          subtitle: SimpleBarChart.subtitle,
          body: (context) => SimpleBarChart(
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

class SimpleBarChartBuilder extends ExampleBuilder {
  const SimpleBarChartBuilder();

  @override
  Widget page([int? index, List<ExampleBuilder>? children]) =>
      const SimpleBarChartPage();

  @override
  String? get subtitle => SimpleBarChart.subtitle;

  @override
  String get title => SimpleBarChart.title;

  @override
  Widget withSampleData([bool animate = true]) =>
      SimpleBarChart.withSampleData(animate);
}

/// Bar chart example
class SimpleBarChart extends StatelessWidget {
  const SimpleBarChart(
    this.seriesList, {
    this.animate = true,
    super.key,
  });

  factory SimpleBarChart.withSampleData([bool animate = true]) {
    return SimpleBarChart(
      createSampleData(),
      animate: animate,
    );
  }

  static String get title => 'Simple';
  static String? get subtitle => 'Simple bar chart with a single series';

  final List<charts.Series<dynamic, String>> seriesList;
  final bool animate;

  /// Create random data.
  static List<charts.Series<OrdinalSales, String>> createRandomData() {
    final random = Random();

    final data = [
      OrdinalSales('2014', random.nextInt(100)),
      OrdinalSales('2015', random.nextInt(100)),
      OrdinalSales('2016', random.nextInt(100)),
      OrdinalSales('2017', random.nextInt(100)),
    ];

    return [
      charts.Series<OrdinalSales, String>(
        id: 'Sales',
        color: (_, __) => charts.DesktopPalette.blue.shadeDefault,
        domain: (OrdinalSales sales, _) => sales.year,
        measure: (OrdinalSales sales, _) => sales.sales,
        data: data,
      )
    ];
  }

  /// Create one series with sample hard coded data.
  static List<charts.Series<OrdinalSales, String>> createSampleData() {
    const data = [
      OrdinalSales('2014', 5),
      OrdinalSales('2015', 25),
      OrdinalSales('2016', 100),
      OrdinalSales('2017', 75),
    ];

    return [
      charts.Series<OrdinalSales, String>(
        id: 'Sales',
        color: (_, __) => charts.DesktopPalette.blue.shadeDefault,
        domain: (OrdinalSales sales, _) => sales.year,
        measure: (OrdinalSales sales, _) => sales.sales,
        data: data,
      )
    ];
  }

  @override
  Widget build(BuildContext context) {
    return charts.BarChart(
      seriesList,
      animate: animate,
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
