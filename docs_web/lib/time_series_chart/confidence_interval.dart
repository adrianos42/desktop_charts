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

class TimeSeriesConfidenceIntervalPage extends StatefulWidget {
  const TimeSeriesConfidenceIntervalPage({super.key});

  @override
  State<TimeSeriesConfidenceIntervalPage> createState() =>
      _TimeSeriesConfidenceIntervalPageState();
}

class _TimeSeriesConfidenceIntervalPageState
    extends State<TimeSeriesConfidenceIntervalPage> {
  bool _hasAnimation = true;

  void _updateRandomData() {
    _data = TimeSeriesConfidenceInterval.createRandomData();
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
          title: TimeSeriesConfidenceInterval.title,
          subtitle: TimeSeriesConfidenceInterval.subtitle,
          body: (context) => TimeSeriesConfidenceInterval(
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

class TimeSeriesConfidenceIntervalBuilder extends ExampleBuilder {
  const TimeSeriesConfidenceIntervalBuilder();

  @override
  Widget page([int? index, List<ExampleBuilder>? children]) =>
      const TimeSeriesConfidenceIntervalPage();

  @override
  String? get subtitle => TimeSeriesConfidenceInterval.subtitle;

  @override
  String get title => TimeSeriesConfidenceInterval.title;

  @override
  Widget withSampleData([bool animate = true]) =>
      TimeSeriesConfidenceInterval.withSampleData(animate);
}

/// Example of a time series chart with a confidence interval.
///
/// Confidence interval is defined by specifying the upper and lower measure
/// bounds in the series.
class TimeSeriesConfidenceInterval extends StatelessWidget {
  const TimeSeriesConfidenceInterval(
    this.seriesList, {
    this.animate = true,
    super.key,
  });

  /// Creates a [TimeSeriesChart] with sample data and no transition.
  factory TimeSeriesConfidenceInterval.withSampleData([bool animate = true]) {
    return TimeSeriesConfidenceInterval(
      createSampleData(),
      animate: animate,
    );
  }

  static String get title => 'Confidence Interval';
  static String? get subtitle => 'Draws area around the confidence interval';

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
        // When the measureLowerBound and measureUpperBound is defined,
        // the line renderer will render the area around the bounds.
        measureLowerBound: (TimeSeriesSales sales, _) => sales.sales - 5,
        measureUpperBound: (TimeSeriesSales sales, _) => sales.sales + 5,
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
        // When the measureLowerBound and measureUpperBound is defined,
        // the line renderer will render the area around the bounds.
        measureLowerBound: (TimeSeriesSales sales, _) => sales.sales - 5,
        measureUpperBound: (TimeSeriesSales sales, _) => sales.sales + 5,
        data: data,
      )
    ];
  }

  @override
  Widget build(BuildContext context) {
    return charts.TimeSeriesChart(
      seriesList,
      animate: animate,
      // Optionally pass in a [DateTimeFactory] used by the chart. The factory
      // should create the same type of [DateTime] as the data provided. If none
      // specified, the default creates local date time.
      dateTimeFactory: const charts.LocalDateTimeFactory(),
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
