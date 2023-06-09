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

class HorizontalBarLabelCustomChartBuilder extends ExampleBuilder {
  const HorizontalBarLabelCustomChartBuilder();

  @override
  String get title => HorizontalBarLabelCustomChart.title;

  @override
  String? get subtitle => HorizontalBarLabelCustomChart.subtitle;

  @override
  Widget withSampleData([bool animate = true]) =>
      HorizontalBarLabelCustomChart.withSampleData(animate);

  @override
  Widget withData(dynamic data, [bool animate = true]) =>
      HorizontalBarLabelCustomChart(
        data as List<charts.Series<dynamic, String>>,
        animate: animate,
      );

  @override
  dynamic generateRandomData() =>
      HorizontalBarLabelCustomChart.createRandomData();

  @override
  bool get hasParent => true;

  @override
  String get parentTitle => 'Horizontal';
}

/// Horizontal bar chart with custom style for each datum in the bar label.
class HorizontalBarLabelCustomChart extends StatelessWidget {
  const HorizontalBarLabelCustomChart(
    this.seriesList, {
    this.animate = true,
    super.key,
  });

  static String get title => 'Custom Labels';
  static String? get subtitle => 'Bar labels with customized styling';

  final List<charts.Series<dynamic, String>> seriesList;
  final bool animate;

  /// Creates a [BarChart] with sample data and no transition.
  static HorizontalBarLabelCustomChart withSampleData([
    bool animate = true,
  ]) {
    return HorizontalBarLabelCustomChart(
      createSampleData(),
      animate: animate,
    );
  }

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
        domain: (OrdinalSales sales, _) => sales.year,
        measure: (OrdinalSales sales, _) => sales.sales,
        data: data,
        // Set a label accessor to control the text of the bar label.
        labelAccessor: (OrdinalSales sales, _) =>
            '${sales.year}: \$${sales.sales.toString()}',
        insideLabelStyleAccessor: (OrdinalSales sales, _) {
          final color = (sales.year == '2014')
              ? charts.DesktopPalette.red.shadeDefault
              : charts.DesktopPalette.yellow.shadeDefault.darker;
          return TextStyle(color: color);
        },
        outsideLabelStyleAccessor: (OrdinalSales sales, _) {
          final color = (sales.year == '2014')
              ? charts.DesktopPalette.red.shadeDefault
              : charts.DesktopPalette.yellow.shadeDefault.darker;
          return TextStyle(color: color);
        },
      ),
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
        domain: (OrdinalSales sales, _) => sales.year,
        measure: (OrdinalSales sales, _) => sales.sales,
        data: data,
        // Set a label accessor to control the text of the bar label.
        labelAccessor: (OrdinalSales sales, _) =>
            '${sales.year}: \$${sales.sales.toString()}',
        insideLabelStyleAccessor: (OrdinalSales sales, _) {
          final color = (sales.year == '2014')
              ? charts.DesktopPalette.red.shadeDefault
              : charts.DesktopPalette.yellow.shadeDefault.darker;
          return TextStyle(color: color);
        },
        outsideLabelStyleAccessor: (OrdinalSales sales, _) {
          final color = (sales.year == '2014')
              ? charts.DesktopPalette.red.shadeDefault
              : charts.DesktopPalette.yellow.shadeDefault.darker;
          return TextStyle(color: color);
        },
      ),
    ];
  }

  // The [BarLabelDecorator] has settings to set the text style for all labels
  // for inside the bar and outside the bar. To be able to control each datum's
  // style, set the style accessor functions on the series.
  @override
  Widget build(BuildContext context) {
    return charts.BarChart(
      seriesList,
      animate: animate,
      isVertical: false,
      barRendererDecorator: charts.BarLabelDecorator<String>(),
      // Hide domain axis.
      domainAxis: const charts.OrdinalAxisSpec(
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
