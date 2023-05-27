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

class FlippedVerticalAxisPage extends StatefulWidget {
  const FlippedVerticalAxisPage({super.key});

  @override
  State<FlippedVerticalAxisPage> createState() =>
      _FlippedVerticalAxisPageState();
}

class _FlippedVerticalAxisPageState extends State<FlippedVerticalAxisPage> {
  bool _hasAnimation = true;

  void _updateRandomData() {
    _data = FlippedVerticalAxis.createRandomData();
  }

  void _refresh() {
    setState(() => _updateRandomData());
  }

  @override
  void initState() {
    super.initState();

    _updateRandomData();
  }

  late List<charts.Series<RunnerRank, String>> _data;

  @override
  Widget build(BuildContext context) {
    return Defaults(
      header: 'Axes',
      items: [
        ItemTitle(
          title: FlippedVerticalAxis.title,
          subtitle: FlippedVerticalAxis.subtitle,
          body: (context) => FlippedVerticalAxis(
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

class FlippedVerticalAxisBuilder extends ExampleBuilder {
  const FlippedVerticalAxisBuilder();

  @override
  Widget page([int? index, List<ExampleBuilder>? children]) =>
      const FlippedVerticalAxisPage();

  @override
  String? get subtitle => FlippedVerticalAxis.subtitle;

  @override
  String get title => FlippedVerticalAxis.title;

  @override
  Widget withSampleData([bool animate = true]) =>
      FlippedVerticalAxis.withSampleData(animate);
}

/// Bar chart example
///
/// Example of flipping the vertical measure axis direction so that larger
/// values render downward instead of the usual rendering up.
///
/// flipVerticalAxis, when set, flips the vertical axis from its default
/// direction.
///
/// Note: primary and secondary may flip left and right positioning when
/// RTL.flipAxisLocations is set.
class FlippedVerticalAxis extends StatelessWidget {
  const FlippedVerticalAxis(
    this.seriesList, {
    this.animate = true,
    super.key,
  });

  factory FlippedVerticalAxis.withSampleData([bool animate = true]) {
    return FlippedVerticalAxis(
      createSampleData(),
      animate: animate,
    );
  }

  static String get title => throw UnimplementedError();
  static String? get subtitle => throw UnimplementedError();

  final List<charts.Series<dynamic, String>> seriesList;
  final bool animate;

  /// Create random data.
  static List<charts.Series<RunnerRank, String>> createRandomData() {
    final random = Random();

    const runners = ['Smith', 'Jones', 'Brown', 'Doe'];

    // Randomly assign runners, but leave the order of the places.
    final raceData = [
      RunnerRank(runners.removeAt(random.nextInt(runners.length)), 1),
      RunnerRank(runners.removeAt(random.nextInt(runners.length)), 2),
      RunnerRank(runners.removeAt(random.nextInt(runners.length)), 3),
      RunnerRank(runners.removeAt(random.nextInt(runners.length)), 4),
    ];

    return [
      charts.Series<RunnerRank, String>(
        id: 'Race Results',
        domain: (RunnerRank row, _) => row.name,
        measure: (RunnerRank row, _) => row.place,
        data: raceData,
      ),
    ];
  }

  /// Create series list with multiple series
  static List<charts.Series<RunnerRank, String>> createSampleData() {
    const raceData = [
      RunnerRank('Smith', 1),
      RunnerRank('Jones', 2),
      RunnerRank('Brown', 3),
      RunnerRank('Doe', 4),
    ];

    return [
      charts.Series<RunnerRank, String>(
          id: 'Race Results',
          domain: (RunnerRank row, _) => row.name,
          measure: (RunnerRank row, _) => row.place,
          data: raceData),
    ];
  }

  // Known Issue, the bar chart cannot render negative direction bars at this
  // time so the result is an empty chart.
  // TODO: Remove this comment
  @override
  Widget build(BuildContext context) {
    return charts.BarChart(
      seriesList,
      animate: animate,
      flipVerticalAxis: true,
    );
  }
}

/// Datum/Row for the chart.
@immutable
class RunnerRank {
  const RunnerRank(this.name, this.place);

  final String name;
  final int place;
}
