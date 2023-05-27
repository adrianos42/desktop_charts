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

class SparkBarPage extends StatefulWidget {
  const SparkBarPage({super.key});

  @override
  State<SparkBarPage> createState() => _SparkBarPageState();
}

class _SparkBarPageState extends State<SparkBarPage> {
  bool _hasAnimation = true;

  void _updateRandomData() {
    _data = SparkBar.createRandomData();
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
          title: SparkBar.title,
          subtitle: SparkBar.subtitle,
          body: (context) => SparkBar(
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

class SparkBarBuilder extends ExampleBuilder {
  const SparkBarBuilder();

  @override
  Widget page([int? index, List<ExampleBuilder>? children]) =>
      const SparkBarPage();

  @override
  String? get subtitle => SparkBar.subtitle;

  @override
  String get title => SparkBar.title;

  @override
  Widget withSampleData([bool animate = true]) =>
      SparkBar.withSampleData(animate);
}

/// Spark Bar Example
///
/// Example of a Spark Bar by hiding both axis, reducing the chart margins.
class SparkBar extends StatelessWidget {
  const SparkBar(
    this.seriesList, {
    this.animate = true,
    super.key,
  });

  factory SparkBar.withSampleData([bool animate = true]) {
    return SparkBar(
      createSampleData(),
      animate: animate,
    );
  }

  static String get title => 'Spark';
  static String? get subtitle => null;

  final List<charts.Series<dynamic, String>> seriesList;
  final bool animate;

  /// Create random data.
  static List<charts.Series<OrdinalSales, String>> createRandomData() {
    final random = Random();

    final globalSalesData = [
      OrdinalSales('2007', random.nextInt(100)),
      OrdinalSales('2008', random.nextInt(100)),
      OrdinalSales('2009', random.nextInt(100)),
      OrdinalSales('2010', random.nextInt(100)),
      OrdinalSales('2011', random.nextInt(100)),
      OrdinalSales('2012', random.nextInt(100)),
      OrdinalSales('2013', random.nextInt(100)),
      OrdinalSales('2014', random.nextInt(100)),
      OrdinalSales('2015', random.nextInt(100)),
      OrdinalSales('2016', random.nextInt(100)),
      OrdinalSales('2017', random.nextInt(100)),
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
      OrdinalSales('2007', 3100),
      OrdinalSales('2008', 3500),
      OrdinalSales('2009', 5000),
      OrdinalSales('2010', 2500),
      OrdinalSales('2011', 3200),
      OrdinalSales('2012', 4500),
      OrdinalSales('2013', 4400),
      OrdinalSales('2014', 5000),
      OrdinalSales('2015', 5000),
      OrdinalSales('2016', 4500),
      OrdinalSales('2017', 4300),
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

      /// Assign a custom style for the measure axis.
      ///
      /// The NoneRenderSpec only draws an axis line (and even that can be hidden
      /// with showAxisLine=false).
      primaryMeasureAxis: const charts.NumericAxisSpec(
        renderSpec: charts.NoneRenderSpec(),
      ),

      /// This is an OrdinalAxisSpec to match up with BarChart's default
      /// ordinal domain axis (use NumericAxisSpec or DateTimeAxisSpec for
      /// other charts).
      domainAxis: const charts.OrdinalAxisSpec(
        // Make sure that we draw the domain axis line.
        showAxisLine: true,
        // But don't draw anything else.
        renderSpec: charts.NoneRenderSpec(),
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
