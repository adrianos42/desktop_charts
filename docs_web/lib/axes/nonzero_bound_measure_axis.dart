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

/// Example of time series chart that has a measure axis that does NOT include
/// zero. It starts at 100 and goes to 140.

import 'dart:math';

import 'package:desktop/desktop.dart';
import 'package:desktop_charts/desktop_charts.dart' as charts;

class NonzeroBoundMeasureAxis extends StatelessWidget {
  const NonzeroBoundMeasureAxis(
    this.seriesList, {
    this.animate = true,
    super.key,
  });

  /// Creates a [TimeSeriesChart] with sample data and no transition.
  factory NonzeroBoundMeasureAxis.withSampleData([bool animate = true]) {
    return NonzeroBoundMeasureAxis(
      createSampleData(),
      animate: animate,
    );
  }

  // This section is excluded from being copied to the gallery.
  // It is used for creating random series data to demonstrate animation in
  // the example app only.
  factory NonzeroBoundMeasureAxis.withRandomData([bool animate = true]) {
    return NonzeroBoundMeasureAxis(
      createRandomData(),
      animate: animate,
    );
  }

  final List<charts.Series<dynamic, DateTime>> seriesList;
  final bool animate;

  /// Create random data.
  static List<charts.Series<MyRow, DateTime>> createRandomData() {
    final random = Random();

    final data = [
      MyRow(DateTime(2017, 9, 25), random.nextInt(100) + 100),
      MyRow(DateTime(2017, 9, 26), random.nextInt(100) + 100),
      MyRow(DateTime(2017, 9, 27), random.nextInt(100) + 100),
      MyRow(DateTime(2017, 9, 28), random.nextInt(100) + 100),
      MyRow(DateTime(2017, 9, 29), random.nextInt(100) + 100),
      MyRow(DateTime(2017, 9, 30), random.nextInt(100) + 100),
      MyRow(DateTime(2017, 10, 01), random.nextInt(100) + 100),
      MyRow(DateTime(2017, 10, 02), random.nextInt(100) + 100),
      MyRow(DateTime(2017, 10, 03), random.nextInt(100) + 100),
      MyRow(DateTime(2017, 10, 04), random.nextInt(100) + 100),
      MyRow(DateTime(2017, 10, 05), random.nextInt(100) + 100),
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
      // Provide a tickProviderSpec which does NOT require that zero is
      // included.
      primaryMeasureAxis: const charts.NumericAxisSpec(
        tickProviderSpec: charts.BasicNumericTickProviderSpec(
          zeroBound: false,
        ),
      ),
    );
  }

  /// Create one series with sample hard coded data.
  static List<charts.Series<MyRow, DateTime>> createSampleData() {
    final data = [
      MyRow(DateTime(2017, 9, 25), 106),
      MyRow(DateTime(2017, 9, 26), 108),
      MyRow(DateTime(2017, 9, 27), 106),
      MyRow(DateTime(2017, 9, 28), 109),
      MyRow(DateTime(2017, 9, 29), 111),
      MyRow(DateTime(2017, 9, 30), 115),
      MyRow(DateTime(2017, 10, 01), 125),
      MyRow(DateTime(2017, 10, 02), 133),
      MyRow(DateTime(2017, 10, 03), 127),
      MyRow(DateTime(2017, 10, 04), 131),
      MyRow(DateTime(2017, 10, 05), 123),
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
}

/// Sample time series data type.
@immutable
class MyRow {
  const MyRow(this.timeStamp, this.headcount);

  final DateTime timeStamp;
  final int headcount;
}
