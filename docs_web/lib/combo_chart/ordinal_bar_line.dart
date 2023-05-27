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

class OrdinalComboBarLineChartPage extends StatefulWidget {
  const OrdinalComboBarLineChartPage({super.key});

  @override
  State<OrdinalComboBarLineChartPage> createState() =>
      _OrdinalComboBarLineChartPageState();
}

class _OrdinalComboBarLineChartPageState
    extends State<OrdinalComboBarLineChartPage> {
  bool _hasAnimation = true;

  void _updateRandomData() {
    _data = OrdinalComboBarLineChart.createRandomData();
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
      header: 'Combo',
      items: [
        ItemTitle(
          title: OrdinalComboBarLineChart.title,
          subtitle: OrdinalComboBarLineChart.subtitle,
          body: (context) => OrdinalComboBarLineChart(
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

class OrdinalComboBarLineChartBuilder extends ExampleBuilder {
  const OrdinalComboBarLineChartBuilder();

  @override
  Widget page([int? index, List<ExampleBuilder>? children]) =>
      const OrdinalComboBarLineChartPage();

  @override
  String? get subtitle => OrdinalComboBarLineChart.subtitle;

  @override
  String get title => OrdinalComboBarLineChart.title;

  @override
  Widget withSampleData([bool animate = true]) =>
      OrdinalComboBarLineChart.withSampleData(animate);
}

/// Example of an ordinal combo chart with two series rendered as bars, and a
/// third rendered as a line.
class OrdinalComboBarLineChart extends StatelessWidget {
  const OrdinalComboBarLineChart(
    this.seriesList, {
    this.animate = true,
    super.key,
  });

  factory OrdinalComboBarLineChart.withSampleData([bool animate = true]) {
    return OrdinalComboBarLineChart(
      createSampleData(),
      animate: animate,
    );
  }

  static String get title => 'Ordinal';
  static String? get subtitle => 'Ordinal combo chart with bars and lines';

  final List<charts.Series<dynamic, String>> seriesList;
  final bool animate;

  /// Create random data.
  static List<charts.Series<OrdinalSales, String>> createRandomData() {
    final random = Random();

    final desktopSalesData = [
      OrdinalSales('2014', random.nextInt(100)),
      OrdinalSales('2015', random.nextInt(100)),
      OrdinalSales('2016', random.nextInt(100)),
      OrdinalSales('2017', random.nextInt(100)),
    ];

    final tableSalesData = [
      OrdinalSales('2014', random.nextInt(100)),
      OrdinalSales('2015', random.nextInt(100)),
      OrdinalSales('2016', random.nextInt(100)),
      OrdinalSales('2017', random.nextInt(100)),
    ];

    final mobileSalesData = [
      OrdinalSales('2014', random.nextInt(100)),
      OrdinalSales('2015', random.nextInt(100)),
      OrdinalSales('2016', random.nextInt(100)),
      OrdinalSales('2017', random.nextInt(100)),
    ];

    return [
      charts.Series<OrdinalSales, String>(
        id: 'Desktop',
        color: (_, __) => charts.DesktopPalette.blue.shadeDefault,
        domain: (OrdinalSales sales, _) => sales.year,
        measure: (OrdinalSales sales, _) => sales.sales,
        data: desktopSalesData,
      ),
      charts.Series<OrdinalSales, String>(
        id: 'Tablet',
        color: (_, __) => charts.DesktopPalette.red.shadeDefault,
        domain: (OrdinalSales sales, _) => sales.year,
        measure: (OrdinalSales sales, _) => sales.sales,
        data: tableSalesData,
      ),
      charts.Series<OrdinalSales, String>(
        id: 'Mobile',
        color: (_, __) => charts.DesktopPalette.green.shadeDefault,
        domain: (OrdinalSales sales, _) => sales.year,
        measure: (OrdinalSales sales, _) => sales.sales,
        data: mobileSalesData,
      )
        // Configure our custom line renderer for this series.
        ..setAttribute(charts.rendererIdKey, 'customLine'),
    ];
  }

  /// Create series list with multiple series
  static List<charts.Series<OrdinalSales, String>> createSampleData() {
    const desktopSalesData = [
      OrdinalSales('2014', 5),
      OrdinalSales('2015', 25),
      OrdinalSales('2016', 100),
      OrdinalSales('2017', 75),
    ];

    const tableSalesData = [
      OrdinalSales('2014', 5),
      OrdinalSales('2015', 25),
      OrdinalSales('2016', 100),
      OrdinalSales('2017', 75),
    ];

    const mobileSalesData = [
      OrdinalSales('2014', 10),
      OrdinalSales('2015', 50),
      OrdinalSales('2016', 200),
      OrdinalSales('2017', 150),
    ];

    return [
      charts.Series<OrdinalSales, String>(
        id: 'Desktop',
        color: (_, __) => charts.DesktopPalette.blue.shadeDefault,
        domain: (OrdinalSales sales, _) => sales.year,
        measure: (OrdinalSales sales, _) => sales.sales,
        data: desktopSalesData,
      ),
      charts.Series<OrdinalSales, String>(
        id: 'Tablet',
        color: (_, __) => charts.DesktopPalette.red.shadeDefault,
        domain: (OrdinalSales sales, _) => sales.year,
        measure: (OrdinalSales sales, _) => sales.sales,
        data: tableSalesData,
      ),
      charts.Series<OrdinalSales, String>(
        id: 'Mobile ',
        color: (_, __) => charts.DesktopPalette.green.shadeDefault,
        domain: (OrdinalSales sales, _) => sales.year,
        measure: (OrdinalSales sales, _) => sales.sales,
        data: mobileSalesData,
      )
        // Configure our custom line renderer for this series.
        ..setAttribute(charts.rendererIdKey, 'customLine'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return charts.OrdinalCartesianChart(
      seriesList,
      animate: animate,
      // Configure the default renderer as a bar renderer.
      defaultRenderer: const charts.BarRendererConfig(
        groupingType: charts.BarGroupingType.grouped,
      ),
      // Custom renderer configuration for the line series. This will be used for
      // any series that does not define a rendererIdKey.
      customSeriesRenderers: const [
        charts.LineRendererConfig(
          // ID used to link series to this renderer.
          customRendererId: 'customLine',
        ),
      ],
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
