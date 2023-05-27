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

class HorizontalBarChartWithSecondaryAxisPage extends StatefulWidget {
  const HorizontalBarChartWithSecondaryAxisPage({super.key});

  @override
  State<HorizontalBarChartWithSecondaryAxisPage> createState() =>
      _HorizontalBarChartWithSecondaryAxisPageState();
}

class _HorizontalBarChartWithSecondaryAxisPageState
    extends State<HorizontalBarChartWithSecondaryAxisPage> {
  bool _hasAnimation = true;

  void _updateRandomData() {
    _data = HorizontalBarChartWithSecondaryAxis.createRandomData();
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
          title: HorizontalBarChartWithSecondaryAxis.title,
          subtitle: HorizontalBarChartWithSecondaryAxis.subtitle,
          body: (context) => HorizontalBarChartWithSecondaryAxis(
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

class HorizontalBarChartWithSecondaryAxisBuilder extends ExampleBuilder {
  const HorizontalBarChartWithSecondaryAxisBuilder();

  @override
  Widget page([int? index, List<ExampleBuilder>? children]) =>
      const HorizontalBarChartWithSecondaryAxisPage();

  @override
  String? get subtitle => HorizontalBarChartWithSecondaryAxis.subtitle;

  @override
  String get title => HorizontalBarChartWithSecondaryAxis.title;

  @override
  Widget withSampleData([bool animate = true]) =>
      HorizontalBarChartWithSecondaryAxis.withSampleData(animate);
}

/// Bar chart example
///
/// Example of using a primary and secondary axis (left & right respectively)
/// for a set of grouped bars. This is useful for comparing Series that have
/// different units (revenue vs clicks by region), or different magnitudes (2017
/// revenue vs 1/1/2017 revenue by region).
///
/// The first series plots using the primary axis to position its measure
/// values (bar height). This is the default axis used if the measureAxisId is
/// not set.
///
/// The second series plots using the secondary axis due to the measureAxisId of
/// secondaryMeasureAxisId.
///
/// Note: primary and secondary may flip left and right positioning when
/// RTL.flipAxisLocations is set.
class HorizontalBarChartWithSecondaryAxis extends StatelessWidget {
  const HorizontalBarChartWithSecondaryAxis(
    this.seriesList, {
    this.animate = true,
    super.key,
  });

  factory HorizontalBarChartWithSecondaryAxis.withSampleData(
      [bool animate = true]) {
    return HorizontalBarChartWithSecondaryAxis(
      createSampleData(),
      animate: animate,
    );
  }

  static String get title => 'Horizontal bar chart with Secondary Measure Axis';
  static String? get subtitle =>
      'Horizontal Bar chart with a series using secondary measure axis';

  static const secondaryMeasureAxisId = 'secondaryMeasureAxisId';

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

    final losAngelesSalesData = [
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
      charts.Series<OrdinalSales, String>(
        id: 'Los Angeles Revenue',
        domain: (OrdinalSales sales, _) => sales.year,
        measure: (OrdinalSales sales, _) => sales.sales,
        data: losAngelesSalesData,
      )..setAttribute(charts.measureAxisIdKey, secondaryMeasureAxisId)
      // Set the 'Los Angeles Revenue' series to use the secondary measure axis.
      // All series that have this set will use the secondary measure axis.
      // All other series will use the primary measure axis.
    ];
  }

  /// Create series list with multiple series
  static List<charts.Series<OrdinalSales, String>> createSampleData() {
    const globalSalesData = [
      OrdinalSales('2014', 5000),
      OrdinalSales('2015', 25000),
      OrdinalSales('2016', 100000),
      OrdinalSales('2017', 750000),
    ];

    const losAngelesSalesData = [
      OrdinalSales('2014', 25),
      OrdinalSales('2015', 50),
      OrdinalSales('2016', 10),
      OrdinalSales('2017', 20),
    ];

    return [
      charts.Series<OrdinalSales, String>(
        id: 'Global Revenue',
        domain: (OrdinalSales sales, _) => sales.year,
        measure: (OrdinalSales sales, _) => sales.sales,
        data: globalSalesData,
      ),
      charts.Series<OrdinalSales, String>(
        id: 'Los Angeles Revenue',
        domain: (OrdinalSales sales, _) => sales.year,
        measure: (OrdinalSales sales, _) => sales.sales,
        data: losAngelesSalesData,
      )..setAttribute(charts.measureAxisIdKey, secondaryMeasureAxisId)
      // Set the 'Los Angeles Revenue' series to use the secondary measure axis.
      // All series that have this set will use the secondary measure axis.
      // All other series will use the primary measure axis.
    ];
  }

  @override
  Widget build(BuildContext context) {
    // For horizontal bar charts, set the [vertical] flag to false.
    return charts.BarChart(
      seriesList,
      animate: animate,
      barGroupingType: charts.BarGroupingType.grouped,
      isVertical: false,
      // It is important when using both primary and secondary axes to choose
      // the same number of ticks for both sides to get the grid lines to line
      // up.
      primaryMeasureAxis: const charts.NumericAxisSpec(
        tickProviderSpec: charts.BasicNumericTickProviderSpec(
          desiredTickCount: 3,
        ),
      ),
      secondaryMeasureAxis: const charts.NumericAxisSpec(
        tickProviderSpec: charts.BasicNumericTickProviderSpec(
          desiredTickCount: 3,
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
