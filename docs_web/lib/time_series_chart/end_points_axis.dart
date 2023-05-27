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

class EndPointsAxisTimeSeriesChartPage extends StatefulWidget {
  const EndPointsAxisTimeSeriesChartPage({super.key});

  @override
  State<EndPointsAxisTimeSeriesChartPage> createState() =>
      _EndPointsAxisTimeSeriesChartPageState();
}

class _EndPointsAxisTimeSeriesChartPageState
    extends State<EndPointsAxisTimeSeriesChartPage> {
  bool _hasAnimation = true;

  void _updateRandomData() {
    _data = EndPointsAxisTimeSeriesChart.createRandomData();
  }

  void _refresh() {
    setState(() => _updateRandomData());
  }

  @override
  void initState() {
    super.initState();

    _updateRandomData();
  }

  late List<charts.Series<TimeSeriesSales, DateTime>> _data;

  @override
  Widget build(BuildContext context) {
    return Defaults(
      header: 'Time Series',
      items: [
        ItemTitle(
          title: EndPointsAxisTimeSeriesChart.title,
          subtitle: EndPointsAxisTimeSeriesChart.subtitle,
          body: (context) => EndPointsAxisTimeSeriesChart(
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

class EndPointsAxisTimeSeriesChartBuilder extends ExampleBuilder {
  const EndPointsAxisTimeSeriesChartBuilder();

  @override
  Widget page([int? index, List<ExampleBuilder>? children]) =>
      const EndPointsAxisTimeSeriesChartPage();

  @override
  String? get subtitle => EndPointsAxisTimeSeriesChart.subtitle;

  @override
  String get title => EndPointsAxisTimeSeriesChart.title;

  @override
  Widget withSampleData([bool animate = true]) =>
      EndPointsAxisTimeSeriesChart.withSampleData(animate);
}

/// Example of a time series chart with an end points domain axis.
///
/// An end points axis generates two ticks, one at each end of the axis range.
class EndPointsAxisTimeSeriesChart extends StatelessWidget {
  const EndPointsAxisTimeSeriesChart(
    this.seriesList, {
    this.animate = true,
    super.key,
  });

  /// Creates a [TimeSeriesChart] with sample data and no transition.
  factory EndPointsAxisTimeSeriesChart.withSampleData([bool animate = true]) {
    return EndPointsAxisTimeSeriesChart(
      createSampleData(),
      animate: animate,
    );
  }

  static String get title => 'End Points Axis';
  static String? get subtitle => 'Time series chart with an end points axis';

  final List<charts.Series<dynamic, DateTime>> seriesList;
  final bool animate;

  /// Create random data.
  static List<charts.Series<TimeSeriesSales, DateTime>> createRandomData() {
    final random = Random();

    final data = [
      TimeSeriesSales(DateTime(2017, 9, 19), random.nextInt(100)),
      TimeSeriesSales(DateTime(2017, 9, 26), random.nextInt(100)),
      TimeSeriesSales(DateTime(2017, 10, 3), random.nextInt(100)),
      TimeSeriesSales(DateTime(2017, 10, 10), random.nextInt(100)),
    ];

    return [
      charts.Series<TimeSeriesSales, DateTime>(
        id: 'Sales',
        color: (_, __) => charts.DesktopPalette.blue.shadeDefault,
        domain: (TimeSeriesSales sales, _) => sales.time,
        measure: (TimeSeriesSales sales, _) => sales.sales,
        data: data,
      )
    ];
  }

  /// Create one series with sample hard coded data.
  static List<charts.Series<TimeSeriesSales, DateTime>> createSampleData() {
    final data = [
      TimeSeriesSales(DateTime(2017, 9, 19), 5),
      TimeSeriesSales(DateTime(2017, 9, 26), 25),
      TimeSeriesSales(DateTime(2017, 10, 3), 100),
      TimeSeriesSales(DateTime(2017, 10, 10), 75),
    ];

    return [
      charts.Series<TimeSeriesSales, DateTime>(
        id: 'Sales',
        color: (_, __) => charts.DesktopPalette.blue.shadeDefault,
        domain: (TimeSeriesSales sales, _) => sales.time,
        measure: (TimeSeriesSales sales, _) => sales.sales,
        data: data,
      )
    ];
  }

  @override
  Widget build(BuildContext context) {
    return charts.TimeSeriesChart(
      seriesList,
      animate: animate,
      // Configures an axis spec that is configured to render one tick at each
      // end of the axis range, anchored "inside" the axis. The start tick label
      // will be left-aligned with its tick mark, and the end tick label will be
      // right-aligned with its tick mark.
      domainAxis: const charts.EndPointsTimeAxisSpec(),
    );
  }
}

/// Sample time series data type.
@immutable
class TimeSeriesSales {
  const TimeSeriesSales(this.time, this.sales);

  final DateTime time;
  final int sales;
}
