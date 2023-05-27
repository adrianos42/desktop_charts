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

class TimeSeriesBarPage extends StatefulWidget {
  const TimeSeriesBarPage({super.key});

  @override
  State<TimeSeriesBarPage> createState() => _TimeSeriesBarPageState();
}

class _TimeSeriesBarPageState extends State<TimeSeriesBarPage> {
  bool _hasAnimation = true;

  void _updateRandomData() {
    _data = TimeSeriesBar.createRandomData();
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
          title: TimeSeriesBar.title,
          subtitle: TimeSeriesBar.subtitle,
          body: (context) => TimeSeriesBar(
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

class TimeSeriesBarBuilder extends ExampleBuilder {
  const TimeSeriesBarBuilder();

  @override
  Widget page([int? index, List<ExampleBuilder>? children]) =>
      const TimeSeriesBarPage();

  @override
  String? get subtitle => TimeSeriesBar.subtitle;

  @override
  String get title => TimeSeriesBar.title;

  @override
  Widget withSampleData([bool animate = true]) =>
      TimeSeriesBar.withSampleData(animate);
}

/// Example of a time series chart using a bar renderer.
class TimeSeriesBar extends StatelessWidget {
  const TimeSeriesBar(
    this.seriesList, {
    this.animate = true,
    super.key,
  });

  /// Creates a [TimeSeriesChart] with sample data and no transition.
  factory TimeSeriesBar.withSampleData([bool animate = true]) {
    return TimeSeriesBar(
      createSampleData(),
      animate: animate,
    );
  }

  static String get title => 'Bars';
  static String? get subtitle => 'Time series chart using the bar renderer';

  final List<charts.Series<TimeSeriesSales, DateTime>> seriesList;
  final bool animate;

  /// Create random data.
  static List<charts.Series<TimeSeriesSales, DateTime>> createRandomData() {
    final random = Random();

    final data = [
      TimeSeriesSales(DateTime(2017, 9, 1), random.nextInt(100)),
      TimeSeriesSales(DateTime(2017, 9, 2), random.nextInt(100)),
      TimeSeriesSales(DateTime(2017, 9, 3), random.nextInt(100)),
      TimeSeriesSales(DateTime(2017, 9, 4), random.nextInt(100)),
      TimeSeriesSales(DateTime(2017, 9, 5), random.nextInt(100)),
      TimeSeriesSales(DateTime(2017, 9, 6), random.nextInt(100)),
      TimeSeriesSales(DateTime(2017, 9, 7), random.nextInt(100)),
      TimeSeriesSales(DateTime(2017, 9, 8), random.nextInt(100)),
      TimeSeriesSales(DateTime(2017, 9, 9), random.nextInt(100)),
      TimeSeriesSales(DateTime(2017, 9, 10), random.nextInt(100)),
      TimeSeriesSales(DateTime(2017, 9, 11), random.nextInt(100)),
      TimeSeriesSales(DateTime(2017, 9, 12), random.nextInt(100)),
      TimeSeriesSales(DateTime(2017, 9, 13), random.nextInt(100)),
      TimeSeriesSales(DateTime(2017, 9, 14), random.nextInt(100)),
      TimeSeriesSales(DateTime(2017, 9, 15), random.nextInt(100)),
      TimeSeriesSales(DateTime(2017, 9, 16), random.nextInt(100)),
      TimeSeriesSales(DateTime(2017, 9, 17), random.nextInt(100)),
      TimeSeriesSales(DateTime(2017, 9, 18), random.nextInt(100)),
      TimeSeriesSales(DateTime(2017, 9, 19), random.nextInt(100)),
      TimeSeriesSales(DateTime(2017, 9, 20), random.nextInt(100)),
      TimeSeriesSales(DateTime(2017, 9, 21), random.nextInt(100)),
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
      TimeSeriesSales(DateTime(2017, 9, 1), 5),
      TimeSeriesSales(DateTime(2017, 9, 2), 5),
      TimeSeriesSales(DateTime(2017, 9, 3), 25),
      TimeSeriesSales(DateTime(2017, 9, 4), 100),
      TimeSeriesSales(DateTime(2017, 9, 5), 75),
      TimeSeriesSales(DateTime(2017, 9, 6), 88),
      TimeSeriesSales(DateTime(2017, 9, 7), 65),
      TimeSeriesSales(DateTime(2017, 9, 8), 91),
      TimeSeriesSales(DateTime(2017, 9, 9), 100),
      TimeSeriesSales(DateTime(2017, 9, 10), 111),
      TimeSeriesSales(DateTime(2017, 9, 11), 90),
      TimeSeriesSales(DateTime(2017, 9, 12), 50),
      TimeSeriesSales(DateTime(2017, 9, 13), 40),
      TimeSeriesSales(DateTime(2017, 9, 14), 30),
      TimeSeriesSales(DateTime(2017, 9, 15), 40),
      TimeSeriesSales(DateTime(2017, 9, 16), 50),
      TimeSeriesSales(DateTime(2017, 9, 17), 30),
      TimeSeriesSales(DateTime(2017, 9, 18), 35),
      TimeSeriesSales(DateTime(2017, 9, 19), 40),
      TimeSeriesSales(DateTime(2017, 9, 20), 32),
      TimeSeriesSales(DateTime(2017, 9, 21), 31),
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
      // Set the default renderer to a bar renderer.
      // This can also be one of the custom renderers of the time series chart.
      defaultRenderer: const charts.BarRendererConfig<DateTime>(),
      // It is recommended that default interactions be turned off if using bar
      // renderer, because the line point highlighter is the default for time
      // series chart.
      defaultInteractions: false,
      // If default interactions were removed, optionally add select nearest
      // and the domain highlighter that are typical for bar charts.
      behaviors: const [
        charts.SelectNearest(),
        charts.DomainHighlighter(),
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
