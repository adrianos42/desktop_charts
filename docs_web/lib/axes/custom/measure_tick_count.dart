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

class CustomMeasureTickCountBuilder extends ExampleBuilder {
  const CustomMeasureTickCountBuilder();

  @override
  String? get subtitle => CustomMeasureTickCount.subtitle;

  @override
  String get title => CustomMeasureTickCount.title;

  @override
  Widget withSampleData([bool animate = true]) =>
      CustomMeasureTickCount.withSampleData(animate);

  @override
  Widget withData(dynamic data, [bool animate = true]) =>
      CustomMeasureTickCount(
        data as List<charts.Series<dynamic, DateTime>>,
        animate: animate,
      );

  @override
  dynamic generateRandomData() => CustomMeasureTickCount.createRandomData();

  @override
  bool get hasParent => true;

  @override
  String get parentTitle => 'Custom';
}

/// Example of time series chart with a custom number of ticks
///
/// The tick count can be set by setting the [desiredMinTickCount] and
/// [desiredMaxTickCount] for automatically adjusted tick counts (based on
/// how 'nice' the ticks are) or [desiredTickCount] for a fixed tick count.
class CustomMeasureTickCount extends StatelessWidget {
  const CustomMeasureTickCount(
    this.seriesList, {
    this.animate = true,
    super.key,
  });

  /// Creates a [TimeSeriesChart] with sample data and no transition.
  factory CustomMeasureTickCount.withSampleData([bool animate = true]) {
    return CustomMeasureTickCount(
      createSampleData(),
      animate: animate,
    );
  }

  static String get title => 'Tick Count';
  static String? get subtitle =>
      'Time series with custom measure axis tick count';

  final List<charts.Series<dynamic, DateTime>> seriesList;
  final bool animate;

  /// Create random data.
  static List<charts.Series<MyRow, DateTime>> createRandomData() {
    final random = Random();

    final data = [
      MyRow(DateTime(2017, 9, 25), random.nextInt(100)),
      MyRow(DateTime(2017, 9, 26), random.nextInt(100)),
      MyRow(DateTime(2017, 9, 27), random.nextInt(100)),
      MyRow(DateTime(2017, 9, 28), random.nextInt(100)),
      MyRow(DateTime(2017, 9, 29), random.nextInt(100)),
      MyRow(DateTime(2017, 9, 30), random.nextInt(100)),
      MyRow(DateTime(2017, 10, 01), random.nextInt(100)),
      MyRow(DateTime(2017, 10, 02), random.nextInt(100)),
      MyRow(DateTime(2017, 10, 03), random.nextInt(100)),
      MyRow(DateTime(2017, 10, 04), random.nextInt(100)),
      MyRow(DateTime(2017, 10, 05), random.nextInt(100)),
    ];

    return [
      charts.Series<MyRow, DateTime>(
        id: 'Cost',
        domain: (MyRow row, _) => row.timeStamp,
        measure: (MyRow row, _) => row.cost,
        data: data,
      )
    ];
  }

  /// Create one series with sample hard coded data.
  static List<charts.Series<MyRow, DateTime>> createSampleData() {
    final data = [
      MyRow(DateTime(2017, 9, 25), 6),
      MyRow(DateTime(2017, 9, 26), 8),
      MyRow(DateTime(2017, 9, 27), 6),
      MyRow(DateTime(2017, 9, 28), 9),
      MyRow(DateTime(2017, 9, 29), 11),
      MyRow(DateTime(2017, 9, 30), 15),
      MyRow(DateTime(2017, 10, 01), 25),
      MyRow(DateTime(2017, 10, 02), 33),
      MyRow(DateTime(2017, 10, 03), 27),
      MyRow(DateTime(2017, 10, 04), 31),
      MyRow(DateTime(2017, 10, 05), 23),
    ];

    return [
      charts.Series<MyRow, DateTime>(
        id: 'Cost',
        domain: (MyRow row, _) => row.timeStamp,
        measure: (MyRow row, _) => row.cost,
        data: data,
      )
    ];
  }

  @override
  Widget build(BuildContext context) {
    return charts.TimeSeriesChart(
      seriesList,
      animate: animate,

      /// Customize the measure axis to have 2 ticks,
      primaryMeasureAxis: const charts.NumericAxisSpec(
        tickProviderSpec: charts.BasicNumericTickProviderSpec(
          desiredTickCount: 2,
        ),
      ),
    );
  }
}

/// Sample time series data type.
@immutable
class MyRow {
  const MyRow(this.timeStamp, this.cost);

  final DateTime timeStamp;
  final int cost;
}
