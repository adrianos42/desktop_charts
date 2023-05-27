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

class GridlineDashPatternPage extends StatefulWidget {
  const GridlineDashPatternPage({super.key});

  @override
  State<GridlineDashPatternPage> createState() =>
      _GridlineDashPatternPageState();
}

class _GridlineDashPatternPageState extends State<GridlineDashPatternPage> {
  bool _hasAnimation = true;

  void _updateRandomData() {
    _data = GridlineDashPattern.createRandomData();
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
          title: GridlineDashPattern.title,
          subtitle: GridlineDashPattern.subtitle,
          body: (context) => GridlineDashPattern(
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

class GridlineDashPatternBuilder extends ExampleBuilder {
  const GridlineDashPatternBuilder();

  @override
  Widget page([int? index, List<ExampleBuilder>? children]) => const GridlineDashPatternPage();

  @override
  String? get subtitle => GridlineDashPattern.subtitle;

  @override
  String get title => GridlineDashPattern.title;

  @override
  Widget withSampleData([bool animate = true]) =>
      GridlineDashPattern.withSampleData(animate);
}

/// Example of time series chart with grid lines that have a dash pattern.
class GridlineDashPattern extends StatelessWidget {
  const GridlineDashPattern(
    this.seriesList, {
    this.animate = true,
    super.key,
  });

  /// Creates a [TimeSeriesChart] with sample data and no transition.
  factory GridlineDashPattern.withSampleData([bool animate = true]) {
    return GridlineDashPattern(
      createSampleData(),
      animate: animate,
    );
  }

  static String get title => 'Gridline dash pattern';
  static String? get subtitle =>
      'Time series with measure grid lines that have a dash pattern';

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

      /// Customize the grid lines to use a dash pattern.
      primaryMeasureAxis: const charts.NumericAxisSpec(
        renderSpec: charts.GridlineRendererSpec(
          lineStyle: charts.LineStyle(
            dashPattern: [4, 4],
          ),
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
