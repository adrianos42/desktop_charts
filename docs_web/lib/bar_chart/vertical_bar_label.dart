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

class VerticalBarLabelChartPage extends StatefulWidget {
  const VerticalBarLabelChartPage({super.key});

  @override
  State<VerticalBarLabelChartPage> createState() =>
      _VerticalBarLabelChartPageState();
}

class _VerticalBarLabelChartPageState extends State<VerticalBarLabelChartPage> {
  bool _hasAnimation = true;

  void _updateRandomData() {
    _data = VerticalBarLabelChart.createRandomData();
  }

  void _refresh() {
    setState(() => _updateRandomData());
  }

  @override
  void initState() {
    super.initState();

    _updateRandomData();
  }

  late List<charts.Series<dynamic, String>> _data;

  @override
  Widget build(BuildContext context) {
    return Defaults(
      header: 'Bar',
      items: [
        ItemTitle(
          title: VerticalBarLabelChart.title,
          subtitle: VerticalBarLabelChart.subtitle,
          body: (context) => VerticalBarLabelChart(
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

/// Vertical bar chart with bar label renderer example.
class VerticalBarLabelChartBuilder extends ExampleBuilder {
  const VerticalBarLabelChartBuilder();

  @override
  Widget page([int? index, List<ExampleBuilder>? children]) =>
      const VerticalBarLabelChartPage();

  @override
  String? get subtitle => VerticalBarLabelChart.subtitle;

  @override
  String get title => VerticalBarLabelChart.title;

  @override
  Widget withSampleData([bool animate = true]) =>
      VerticalBarLabelChart.withSampleData(animate);
}

class VerticalBarLabelChart extends StatelessWidget {
  const VerticalBarLabelChart(
    this.seriesList, {
    this.animate = true,
    super.key,
  });

  /// Creates a [BarChart] with sample data and no transition.
  factory VerticalBarLabelChart.withSampleData([bool animate = true]) {
    return VerticalBarLabelChart(
      createSampleData(),
      animate: animate,
    );
  }

  static String get title => 'Vertical with Labels';
  static String? get subtitle =>
      'Vertical bar chart with a single series and bar labels';

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
          domain: (OrdinalSales sales, _) => sales.year,
          measure: (OrdinalSales sales, _) => sales.sales,
          data: data,
          // Set a label accessor to control the text of the bar label.
          labelAccessor: (OrdinalSales sales, _) => sales.sales.toString())
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
              '\$${sales.sales.toString()}')
    ];
  }

  // [BarLabelDecorator] will automatically position the label
  // inside the bar if the label will fit. If the label will not fit,
  // it will draw outside of the bar.
  // Labels can always display inside or outside using [LabelPosition].
  //
  // Text style for inside / outside can be controlled independently by setting
  // [insideLabelStyleSpec] and [outsideLabelStyleSpec].
  @override
  Widget build(BuildContext context) {
    return charts.BarChart(
      seriesList,
      animate: animate,
      // Set a bar label decorator.
      // Example configuring different styles for inside/outside:
      //       barRendererDecorator: charts.BarLabelDecorator(
      //          insideLabelStyleSpec: charts.TextStyleSpec(...),
      //          outsideLabelStyleSpec: charts.TextStyleSpec(...)),
      barRendererDecorator: charts.BarLabelDecorator<String>(),
      domainAxis: const charts.OrdinalAxisSpec(),
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
