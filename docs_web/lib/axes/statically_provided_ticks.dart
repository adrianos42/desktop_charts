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

class StaticallyProvidedTicksPage extends StatefulWidget {
  const StaticallyProvidedTicksPage({super.key});

  @override
  State<StaticallyProvidedTicksPage> createState() =>
      _StaticallyProvidedTicksPageState();
}

class _StaticallyProvidedTicksPageState
    extends State<StaticallyProvidedTicksPage> {
  bool _hasAnimation = true;

  void _updateRandomData() {
    _data = StaticallyProvidedTicks.createRandomData();
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
          title: StaticallyProvidedTicks.title,
          subtitle: StaticallyProvidedTicks.subtitle,
          body: (context) => StaticallyProvidedTicks(
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

class StaticallyProvidedTicksBuilder extends ExampleBuilder {
  const StaticallyProvidedTicksBuilder();

  @override
  Widget page([int? index, List<ExampleBuilder>? children]) =>
      const StaticallyProvidedTicksPage();

  @override
  String? get subtitle => StaticallyProvidedTicks.subtitle;

  @override
  String get title => StaticallyProvidedTicks.title;

  @override
  Widget withSampleData([bool animate = true]) =>
      StaticallyProvidedTicks.withSampleData(animate);
}

/// Example of axis using statically provided ticks.
///
/// Example of specifying a custom set of ticks to be used on the domain axis.
///
/// Specifying custom set of ticks allows specifying exactly what ticks are
/// used in the axis. Each tick is also allowed to have a different style set.
///
/// For an ordinal axis, the [StaticOrdinalTickProviderSpec] is shown in this
/// example defining ticks to be used with [TickSpec] of String.
///
/// For numeric axis, the [StaticNumericTickProviderSpec] can be used by passing
/// in a list of ticks defined with [TickSpec] of num.
///
/// For date time axis, the [StaticDateTimeTickProviderSpec] can be used by
/// passing in a list of ticks defined with [TickSpec] of date time.
class StaticallyProvidedTicks extends StatelessWidget {
  const StaticallyProvidedTicks(
    this.seriesList, {
    this.animate = true,
    super.key,
  });

  factory StaticallyProvidedTicks.withSampleData([bool animate = true]) {
    return StaticallyProvidedTicks(
      createSampleData(),
      animate: animate,
    );
  }

  static String get title => 'Statically Provided Ticks';
  static String? get subtitle => 'Bar chart with statically provided ticks';

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
    // Create the ticks to be used the domain axis.
    final staticTicks = <charts.TickSpec<String>>[
      const charts.TickSpec(
          // Value must match the domain value.
          '2014',
          // Optional label for this tick, defaults to domain value if not set.
          label: 'Year 2014',
          // The styling for this tick.
          style: TextStyle(color: Color(0xff4CAF50))),
      // If no text style is specified - the style from renderSpec will be used
      // if one is specified.
      const charts.TickSpec('2015'),
      const charts.TickSpec('2016'),
      const charts.TickSpec('2017'),
    ];

    return charts.BarChart(
      seriesList,
      animate: animate,
      domainAxis: charts.OrdinalAxisSpec(
        tickProviderSpec: charts.StaticOrdinalTickProviderSpec(staticTicks),
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
