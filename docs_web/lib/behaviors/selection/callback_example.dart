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

class SelectionCallbackExampleBuilder extends ExampleBuilder {
  const SelectionCallbackExampleBuilder();

  @override
  String? get subtitle => SelectionCallbackExample.subtitle;

  @override
  String get title => SelectionCallbackExample.title;

  @override
  Widget withSampleData([bool animate = true]) =>
      SelectionCallbackExample.withSampleData(animate);

  @override
  Widget withData(dynamic data, [bool animate = true]) =>
      SelectionCallbackExample(
        data as List<charts.Series<dynamic, DateTime>>,
        animate: animate,
      );

  @override
  dynamic generateRandomData() => SelectionCallbackExample.createRandomData();

  @override
  bool get hasParent => true;

  @override
  String get parentTitle => 'Selection';
}

/// Time series chart with example of updating external state based on selection.
///
/// A SelectionModelConfig can be provided for each of the different
/// [SelectionModel] (currently info and action).
///
/// [SelectionModelType.info] is the default selection chart exploration type
/// initiated by some tap event. This is a different model from
/// [SelectionModelType.action] which is typically used to select some value as
/// an input to some other UI component. This allows dual state of exploring
/// and selecting data via different touch events.
///
/// See [SelectNearest] behavior on setting the different ways of triggering
/// [SelectionModel] updates from hover & click events.
class SelectionCallbackExample extends StatefulWidget {
  const SelectionCallbackExample(
    this.seriesList, {
    this.animate = true,
    super.key,
  });

  /// Creates a [charts.TimeSeriesChart] with sample data and no transition.
  factory SelectionCallbackExample.withSampleData([bool animate = true]) {
    return SelectionCallbackExample(
      createSampleData(),
      animate: animate,
    );
  }

  static String get title => 'Callback Example';
  static String? get subtitle =>
      'Timeseries that updates external components on selection';

  final List<charts.Series<dynamic, DateTime>> seriesList;
  final bool animate;

  /// Create random data.
  static List<charts.Series<TimeSeriesSales, DateTime>> createRandomData() {
    final random = Random();

    final usData = [
      TimeSeriesSales(DateTime(2017, 9, 19), random.nextInt(100)),
      TimeSeriesSales(DateTime(2017, 9, 26), random.nextInt(100)),
      TimeSeriesSales(DateTime(2017, 10, 3), random.nextInt(100)),
      TimeSeriesSales(DateTime(2017, 10, 10), random.nextInt(100)),
    ];

    final ukData = [
      TimeSeriesSales(DateTime(2017, 9, 19), random.nextInt(100)),
      TimeSeriesSales(DateTime(2017, 9, 26), random.nextInt(100)),
      TimeSeriesSales(DateTime(2017, 10, 3), random.nextInt(100)),
      TimeSeriesSales(DateTime(2017, 10, 10), random.nextInt(100)),
    ];

    return [
      charts.Series<TimeSeriesSales, DateTime>(
        id: 'US Sales',
        domain: (TimeSeriesSales sales, _) => sales.time,
        measure: (TimeSeriesSales sales, _) => sales.sales,
        data: usData,
      ),
      charts.Series<TimeSeriesSales, DateTime>(
        id: 'UK Sales',
        domain: (TimeSeriesSales sales, _) => sales.time,
        measure: (TimeSeriesSales sales, _) => sales.sales,
        data: ukData,
      )
    ];
  }

  /// Create one series with sample hard coded data.
  static List<charts.Series<TimeSeriesSales, DateTime>> createSampleData() {
    final usData = [
      TimeSeriesSales(DateTime(2017, 9, 19), 5),
      TimeSeriesSales(DateTime(2017, 9, 26), 25),
      TimeSeriesSales(DateTime(2017, 10, 3), 78),
      TimeSeriesSales(DateTime(2017, 10, 10), 54),
    ];

    final ukData = [
      TimeSeriesSales(DateTime(2017, 9, 19), 15),
      TimeSeriesSales(DateTime(2017, 9, 26), 33),
      TimeSeriesSales(DateTime(2017, 10, 3), 68),
      TimeSeriesSales(DateTime(2017, 10, 10), 48),
    ];

    return [
      charts.Series<TimeSeriesSales, DateTime>(
        id: 'US Sales',
        domain: (TimeSeriesSales sales, _) => sales.time,
        measure: (TimeSeriesSales sales, _) => sales.sales,
        data: usData,
      ),
      charts.Series<TimeSeriesSales, DateTime>(
        id: 'UK Sales',
        domain: (TimeSeriesSales sales, _) => sales.time,
        measure: (TimeSeriesSales sales, _) => sales.sales,
        data: ukData,
      )
    ];
  }

  // We need a Stateful widget to build the selection details with the current
  // selection as the state.
  @override
  State<StatefulWidget> createState() => _SelectionCallbackState();
}

class _SelectionCallbackState extends State<SelectionCallbackExample> {
  DateTime? _time;
  Map<String, num> _measures = {};

  // Listens to the underlying selection changes, and updates the information
  // relevant to building the primitive legend like information under the
  // chart.
  void _onSelectionChanged(charts.SelectionModel model) {
    final selectedDatum = model.selectedDatum;

    DateTime? time;
    final measures = <String, num>{};

    // We get the model that updated with a list of [SeriesDatum] which is
    // simply a pair of series & datum.
    //
    // Walk the selection updating the measures map, storing off the sales and
    // series name for each selection point.
    if (selectedDatum.isNotEmpty) {
      time = selectedDatum.first.datum.time;
      for (final charts.SeriesDatum datumPair in selectedDatum) {
        measures[datumPair.series.displayName!] = datumPair.datum.sales;
      }
    }

    // Request a build.
    setState(() {
      _time = time;
      _measures = measures;
    });
  }

  @override
  Widget build(BuildContext context) {
    final children = [];
    // If there is a selection, then include the details.
    _measures.forEach((String series, num value) {
      children.add(Text('$series: $value'));
    });

    return Column(children: [
      Expanded(
        child: charts.TimeSeriesChart(
          widget.seriesList,
          animate: widget.animate,
          selectionModels: [
            charts.SelectionModelConfig(
              type: charts.SelectionModelType.info,
              changedListener: _onSelectionChanged,
            )
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Text(
          _time?.toString() ?? '',
        ),
      ),
      ...children,
    ]);
  }
}

/// Sample time series data type.
@immutable
class TimeSeriesSales {
  const TimeSeriesSales(this.time, this.sales);

  final DateTime time;
  final int sales;
}
