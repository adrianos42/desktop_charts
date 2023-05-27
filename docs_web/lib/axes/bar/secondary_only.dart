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

import '../../defaults.dart';

class BarChartWithSecondaryAxisOnlyBuilder extends ExampleBuilder {
  const BarChartWithSecondaryAxisOnlyBuilder();

  @override
  String? get subtitle => BarChartWithSecondaryAxisOnly.subtitle;

  @override
  String get title => BarChartWithSecondaryAxisOnly.title;

  @override
  Widget withSampleData([bool animate = true]) =>
      BarChartWithSecondaryAxisOnly.withSampleData(animate);

  @override
  Widget withData(dynamic data, [bool animate = true]) =>
      BarChartWithSecondaryAxisOnly(
        data as List<charts.Series<dynamic, String>>,
        animate: animate,
      );

  @override
  dynamic generateRandomData() =>
      BarChartWithSecondaryAxisOnly.createRandomData();

  @override
  bool get hasParent => true;

  @override
  String get parentTitle => 'Bar';
}

/// Bar chart example
///
/// Example of using only a secondary axis (on the right) for a set of grouped
/// bars.
///
/// Both series plots using the secondary axis due to the measureAxisId of
/// secondaryMeasureAxisId.
///
/// Note: secondary may flip left and right positioning when
/// RTL.flipAxisLocations is set.
class BarChartWithSecondaryAxisOnly extends StatelessWidget {
  const BarChartWithSecondaryAxisOnly(
    this.seriesList, {
    this.animate = true,
    super.key,
  });

  factory BarChartWithSecondaryAxisOnly.withSampleData([bool animate = true]) {
    return BarChartWithSecondaryAxisOnly(
      createSampleData(),
      animate: animate,
    );
  }

  static String get title => 'Secondary Measure Axis only';
  static String? get subtitle =>
      'Bar chart with both series using secondary measure axis';

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

    return [
      charts.Series<OrdinalSales, String>(
        id: 'Global Revenue',
        domain: (OrdinalSales sales, _) => sales.year,
        measure: (OrdinalSales sales, _) => sales.sales,
        data: globalSalesData,
      )
        // Set series to use the secondary measure axis.
        ..setAttribute(charts.measureAxisIdKey, secondaryMeasureAxisId),
    ];
  }

  /// Create series list with multiple series
  static List<charts.Series<OrdinalSales, String>> createSampleData() {
    const globalSalesData = [
      OrdinalSales('2014', 500),
      OrdinalSales('2015', 2500),
      OrdinalSales('2016', 1000),
      OrdinalSales('2017', 7500),
    ];

    return [
      charts.Series<OrdinalSales, String>(
        id: 'Global Revenue',
        domain: (OrdinalSales sales, _) => sales.year,
        measure: (OrdinalSales sales, _) => sales.sales,
        data: globalSalesData,
      )
        // Set series to use the secondary measure axis.
        ..setAttribute(charts.measureAxisIdKey, secondaryMeasureAxisId),
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
