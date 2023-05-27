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

class CustomFontSizeAndColorBuilder extends ExampleBuilder {
  const CustomFontSizeAndColorBuilder();

  @override
  String? get subtitle => CustomFontSizeAndColor.subtitle;

  @override
  String get title => CustomFontSizeAndColor.title;

  @override
  Widget withSampleData([bool animate = true]) =>
      CustomFontSizeAndColor.withSampleData(animate);

  @override
  Widget withData(dynamic data, [bool animate = true]) =>
      CustomFontSizeAndColor(
        data as List<charts.Series<dynamic, String>>,
        animate: animate,
      );

  @override
  dynamic generateRandomData() => CustomFontSizeAndColor.createRandomData();

  @override
  bool get hasParent => true;

  @override
  String get parentTitle => 'Custom';
}

/// Custom Font Style Example
///
/// Example of using a custom primary measure and domain axis replacing the
/// renderSpec with one with a custom font size and a custom color.
///
/// There are many axis styling options in the SmallTickRenderer allowing you
/// to customize the font, tick lengths, and offsets.
class CustomFontSizeAndColor extends StatelessWidget {
  const CustomFontSizeAndColor(
    this.seriesList, {
    this.animate = true,
    super.key,
  });

  factory CustomFontSizeAndColor.withSampleData([bool animate = true]) {
    return CustomFontSizeAndColor(
      createSampleData(),
      animate: animate,
    );
  }

  static String get title => 'Axis Fonts';
  static String? get subtitle =>
      'Bar chart with custom axis font size and color';

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

      /// Assign a custom style for the domain axis.
      ///
      /// This is an OrdinalAxisSpec to match up with BarChart's default
      /// ordinal domain axis (use NumericAxisSpec or DateTimeAxisSpec for
      /// other charts).
      domainAxis: charts.OrdinalAxisSpec(
        renderSpec: charts.SmallTickRendererSpec(
          // Tick and Label styling here.
          labelStyle: TextStyle(
            fontSize: 18, // size in Pts.
            color: Theme.of(context).colorScheme.primary[70],
          ),

          // Change the line colors to match text color.
          lineStyle: charts.LineStyle(
            color: Theme.of(context).colorScheme.primary[70],
          ),
        ),
      ),

      /// Assign a custom style for the measure axis.
      primaryMeasureAxis: charts.NumericAxisSpec(
        renderSpec: charts.GridlineRendererSpec(
          // Tick and Label styling here.
          labelStyle: TextStyle(
            fontSize: 18,
            color: Theme.of(context).colorScheme.primary[70],
          ),

          // Change the line colors to match text color.
          lineStyle: charts.LineStyle(
            color: Theme.of(context).colorScheme.primary[70],
          ),
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
