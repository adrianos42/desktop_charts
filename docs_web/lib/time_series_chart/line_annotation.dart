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

class TimeSeriesLineAnnotationChartPage extends StatefulWidget {
  const TimeSeriesLineAnnotationChartPage({super.key});

  @override
  State<TimeSeriesLineAnnotationChartPage> createState() =>
      _TimeSeriesLineAnnotationChartPageState();
}

class _TimeSeriesLineAnnotationChartPageState
    extends State<TimeSeriesLineAnnotationChartPage> {
  bool _hasAnimation = true;

  void _updateRandomData() {
    _data = TimeSeriesLineAnnotationChart.createRandomData();
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
          title: TimeSeriesLineAnnotationChart.title,
          subtitle: TimeSeriesLineAnnotationChart.subtitle,
          body: (context) => TimeSeriesLineAnnotationChart(
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

class TimeSeriesLineAnnotationChartBuilder extends ExampleBuilder {
  const TimeSeriesLineAnnotationChartBuilder();

  @override
  Widget page([int? index, List<ExampleBuilder>? children]) =>
      const TimeSeriesLineAnnotationChartPage();

  @override
  String? get subtitle => TimeSeriesLineAnnotationChart.subtitle;

  @override
  String get title => TimeSeriesLineAnnotationChart.title;

  @override
  Widget withSampleData([bool animate = true]) =>
      TimeSeriesLineAnnotationChart.withSampleData(animate);
}

/// Time series chart with line annotation example
///
/// The example future range annotation extends beyond the range of the series
/// data, demonstrating the effect of the [Charts.RangeAnnotation.extendAxis]
/// flag. This can be set to false to disable range extension.
///
/// Additional annotations may be added simply by adding additional
/// [Charts.RangeAnnotationSegment] items to the list.
class TimeSeriesLineAnnotationChart extends StatelessWidget {
  const TimeSeriesLineAnnotationChart(
    this.seriesList, {
    this.animate = true,
    super.key,
  });

  /// Creates a [TimeSeriesChart] with sample data and no transition.
  factory TimeSeriesLineAnnotationChart.withSampleData([bool animate = true]) {
    return TimeSeriesLineAnnotationChart(
      createSampleData(),
      animate: animate,
    );
  }

  static String get title => 'Line Annotation';
  static String? get subtitle =>
      'Time series chart with future line annotation';

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
      behaviors: [
        charts.RangeAnnotation(
          [
            charts.LineAnnotationSegment(
              DateTime(2017, 10, 4),
              charts.RangeAnnotationAxisType.domain,
              startLabel: 'Oct 4',
            ),
            charts.LineAnnotationSegment(
              DateTime(2017, 10, 15),
              charts.RangeAnnotationAxisType.domain,
              endLabel: 'Oct 15',
            ),
          ],
        ),
      ],
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
