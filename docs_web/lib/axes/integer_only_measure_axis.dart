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

class IntegerOnlyMeasureAxisPage extends StatefulWidget {
  const IntegerOnlyMeasureAxisPage({super.key});

  @override
  State<IntegerOnlyMeasureAxisPage> createState() =>
      _IntegerOnlyMeasureAxisPageState();
}

class _IntegerOnlyMeasureAxisPageState
    extends State<IntegerOnlyMeasureAxisPage> {
  bool _hasAnimation = true;

  void _updateRandomData() {
    _data = IntegerOnlyMeasureAxis.createRandomData();
  }

  void _refresh() {
    setState(() => _updateRandomData());
  }

  @override
  void initState() {
    super.initState();

    _updateRandomData();
  }

  late List<charts.Series<MyRow, DateTime>> _data;

  @override
  Widget build(BuildContext context) {
    return Defaults(
      header: 'Axes',
      items: [
        ItemTitle(
          title: IntegerOnlyMeasureAxis.title,
          subtitle: IntegerOnlyMeasureAxis.subtitle,
          body: (context) => IntegerOnlyMeasureAxis(
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

class IntegerOnlyMeasureAxisBuilder extends ExampleBuilder {
  const IntegerOnlyMeasureAxisBuilder();

  @override
  Widget page([int? index, List<ExampleBuilder>? children]) =>
      const IntegerOnlyMeasureAxisPage();

  @override
  String? get subtitle => IntegerOnlyMeasureAxis.subtitle;

  @override
  String get title => IntegerOnlyMeasureAxis.title;

  @override
  Widget withSampleData([bool animate = true]) =>
      IntegerOnlyMeasureAxis.withSampleData(animate);
}

/// Example of time series chart forcing the measure axis to have whole number
/// ticks. This is useful if the measure units don't make sense to present as
/// fractional.
///
/// This is done by customizing the measure axis and setting
/// [dataIsInWholeNumbers] on the tick provider.
class IntegerOnlyMeasureAxis extends StatelessWidget {
  const IntegerOnlyMeasureAxis(
    this.seriesList, {
    this.animate = true,
    super.key,
  });

  /// Creates a [TimeSeriesChart] with sample data and no transition.
  factory IntegerOnlyMeasureAxis.withSampleData([bool animate = true]) {
    return IntegerOnlyMeasureAxis(
      createSampleData(),
      animate: animate,
    );
  }

  static String get title => 'Integer Measure Ticks';
  static String? get subtitle =>
      'Time series with only whole number measure axis ticks';

  final List<charts.Series<dynamic, DateTime>> seriesList;
  final bool animate;

  /// Create random data.
  static List<charts.Series<MyRow, DateTime>> createRandomData() {
    final random = Random();

    final data = [
      MyRow(DateTime(2017, 9, 25), random.nextDouble().round()),
      MyRow(DateTime(2017, 9, 26), random.nextDouble().round()),
      MyRow(DateTime(2017, 9, 27), random.nextDouble().round()),
      MyRow(DateTime(2017, 9, 28), random.nextDouble().round()),
      MyRow(DateTime(2017, 9, 29), random.nextDouble().round()),
      MyRow(DateTime(2017, 9, 30), random.nextDouble().round()),
      MyRow(DateTime(2017, 10, 01), random.nextDouble().round()),
      MyRow(DateTime(2017, 10, 02), random.nextDouble().round()),
      MyRow(DateTime(2017, 10, 03), random.nextDouble().round()),
      MyRow(DateTime(2017, 10, 04), random.nextDouble().round()),
      MyRow(DateTime(2017, 10, 05), random.nextDouble().round()),
    ];

    return [
      charts.Series<MyRow, DateTime>(
        id: 'Headcount',
        domain: (MyRow row, _) => row.timeStamp,
        measure: (MyRow row, _) => row.headcount,
        data: data,
      )
    ];
  }

  /// Create one series with sample hard coded data.
  static List<charts.Series<MyRow, DateTime>> createSampleData() {
    final data = [
      MyRow(DateTime(2017, 9, 25), 0),
      MyRow(DateTime(2017, 9, 26), 0),
      MyRow(DateTime(2017, 9, 27), 0),
      MyRow(DateTime(2017, 9, 28), 0),
      MyRow(DateTime(2017, 9, 29), 0),
      MyRow(DateTime(2017, 9, 30), 0),
      MyRow(DateTime(2017, 10, 01), 1),
      MyRow(DateTime(2017, 10, 02), 1),
      MyRow(DateTime(2017, 10, 03), 1),
      MyRow(DateTime(2017, 10, 04), 1),
      MyRow(DateTime(2017, 10, 05), 1),
    ];

    return [
      charts.Series<MyRow, DateTime>(
        id: 'Headcount',
        domain: (MyRow row, _) => row.timeStamp,
        measure: (MyRow row, _) => row.headcount,
        data: data,
      )
    ];
  }

  @override
  Widget build(BuildContext context) {
    return charts.TimeSeriesChart(
      seriesList,
      animate: animate,
      // Provides a custom axis ensuring that the ticks are in whole numbers.
      primaryMeasureAxis: const charts.NumericAxisSpec(
        tickProviderSpec: charts.BasicNumericTickProviderSpec(
          // Make sure we don't have values less than 1 as ticks
          // (ie: counts).
          dataIsInWholeNumbers: true,
          // Fixed tick count to highlight the integer only behavior
          // generating ticks [0, 1, 2, 3, 4].
          desiredTickCount: 5,
        ),
      ),
    );
  }
}

/// Sample time series data type.
@immutable
class MyRow {
  const MyRow(this.timeStamp, this.headcount);

  final DateTime timeStamp;
  final int headcount;
}
