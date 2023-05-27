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

import 'dart:collection' show LinkedHashMap;
import 'dart:math';

import 'package:desktop/desktop.dart';
import 'package:desktop_charts/desktop_charts.dart' as charts;

import '../defaults.dart';

class DisjointMeasureAxisLineChartPage extends StatefulWidget {
  const DisjointMeasureAxisLineChartPage({super.key});

  @override
  State<DisjointMeasureAxisLineChartPage> createState() =>
      _DisjointMeasureAxisLineChartPageState();
}

class _DisjointMeasureAxisLineChartPageState
    extends State<DisjointMeasureAxisLineChartPage> {
  bool _hasAnimation = true;

  void _updateRandomData() {
    _data = DisjointMeasureAxisLineChart.createRandomData();
  }

  void _refresh() {
    setState(() => _updateRandomData());
  }

  @override
  void initState() {
    super.initState();

    _updateRandomData();
  }

  late List<charts.Series<LinearClicks, num>> _data;

  @override
  Widget build(BuildContext context) {
    return Defaults(
      header: 'Axes',
      items: [
        ItemTitle(
          title: DisjointMeasureAxisLineChart.title,
          subtitle: DisjointMeasureAxisLineChart.subtitle,
          body: (context) => DisjointMeasureAxisLineChart(
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

class DisjointMeasureAxisLineChartBuilder extends ExampleBuilder {
  const DisjointMeasureAxisLineChartBuilder();

  @override
  Widget page([int? index, List<ExampleBuilder>? children]) =>
      const DisjointMeasureAxisLineChartPage();

  @override
  String? get subtitle => DisjointMeasureAxisLineChart.subtitle;

  @override
  String get title => DisjointMeasureAxisLineChart.title;

  @override
  Widget withSampleData([bool animate = true]) =>
      DisjointMeasureAxisLineChart.withSampleData(animate);
}

/// Example of using disjoint measure axes to render 4 series of lines with
/// separate scales. The general use case for this type of chart is to show
/// differences in the trends of the data, without comparing their absolute
/// values.
///
/// Disjoint measure axes will be used to scale the series associated with them,
/// but they will not render any tick elements on either side of the chart.
class DisjointMeasureAxisLineChart extends StatelessWidget {
  const DisjointMeasureAxisLineChart(
    this.seriesList, {
    this.animate = true,
    super.key,
  });

  /// Creates a [LineChart] with sample data and no transition.
  factory DisjointMeasureAxisLineChart.withSampleData([bool animate = true]) {
    return DisjointMeasureAxisLineChart(
      createSampleData(),
      animate: animate,
    );
  }

  static String get title => 'Disjoint Measure Axes';
  static String? get subtitle => 'Line chart with disjoint measure axes';

  final List<charts.Series<dynamic, num>> seriesList;
  final bool animate;

  /// Create random data.
  static List<charts.Series<LinearClicks, num>> createRandomData() {
    final random = Random();

    // The first three series contain similar data with different magnitudes.
    // This demonstrates the ability to graph the trends in each series relative
    // to each other, without the largest magnitude series compressing the
    // smallest.
    final myFakeDesktopData = [
      LinearClicks(0, clickCount: random.nextInt(100)),
      LinearClicks(1, clickCount: random.nextInt(100)),
      LinearClicks(2, clickCount: random.nextInt(100)),
      LinearClicks(3, clickCount: random.nextInt(100)),
    ];

    final myFakeTabletData = [
      LinearClicks(0, clickCount: random.nextInt(100) * 100),
      LinearClicks(1, clickCount: random.nextInt(100) * 100),
      LinearClicks(2, clickCount: random.nextInt(100) * 100),
      LinearClicks(3, clickCount: random.nextInt(100) * 100),
    ];

    final myFakeMobileData = [
      LinearClicks(0, clickCount: random.nextInt(100) * 1000),
      LinearClicks(1, clickCount: random.nextInt(100) * 1000),
      LinearClicks(2, clickCount: random.nextInt(100) * 1000),
      LinearClicks(3, clickCount: random.nextInt(100) * 1000),
    ];

    // The fourth series renders with decimal values, representing a very
    // different sort ratio-based data. If this was on the same axis as any of
    // the other series, it would be squashed near zero.
    final myFakeClickRateData = [
      LinearClicks(0, clickRate: random.nextDouble()),
      LinearClicks(1, clickRate: random.nextDouble()),
      LinearClicks(2, clickRate: random.nextDouble()),
      LinearClicks(3, clickRate: random.nextDouble()),
    ];

    return [
      // We render an empty series on the primary measure axis to ensure that
      // the axis itself gets rendered. This helps us draw the grid lines on the
      // chart.
      charts.Series<LinearClicks, int>(
        id: 'Fake Series',
        domain: (LinearClicks clickCount, _) => clickCount.year,
        measure: (LinearClicks clickCount, _) => clickCount.clickCount,
        data: myFakeClickRateData,
      ),
      charts.Series<LinearClicks, int>(
        id: 'Desktop',
        color: (_, __) => charts.DesktopPalette.blue.shadeDefault,
        domain: (LinearClicks clickCount, _) => clickCount.year,
        measure: (LinearClicks clickCount, _) => clickCount.clickCount,
        data: myFakeDesktopData,
      )
        // Set the 'Desktop' series to use a disjoint axis.
        ..setAttribute(charts.measureAxisIdKey, 'axis 1'),
      charts.Series<LinearClicks, int>(
        id: 'Tablet',
        color: (_, __) => charts.DesktopPalette.red.shadeDefault,
        domain: (LinearClicks clickCount, _) => clickCount.year,
        measure: (LinearClicks clickCount, _) => clickCount.clickCount,
        data: myFakeTabletData,
      )
        // Set the 'Tablet' series to use a disjoint axis.
        ..setAttribute(charts.measureAxisIdKey, 'axis 2'),
      charts.Series<LinearClicks, int>(
        id: 'Mobile',
        color: (_, __) => charts.DesktopPalette.green.shadeDefault,
        domain: (LinearClicks clickCount, _) => clickCount.year,
        measure: (LinearClicks clickCount, _) => clickCount.clickCount,
        data: myFakeMobileData,
      )
        // Set the 'Mobile' series to use a disjoint axis.
        ..setAttribute(charts.measureAxisIdKey, 'axis 3'),
      charts.Series<LinearClicks, int>(
        id: 'Click Rate',
        color: (_, __) => charts.DesktopPalette.purple.shadeDefault,
        domain: (LinearClicks clickCount, _) => clickCount.year,
        measure: (LinearClicks clickCount, _) => clickCount.clickRate,
        data: myFakeClickRateData,
      )
        // Set the 'Click Rate' series to use a disjoint axis.
        ..setAttribute(charts.measureAxisIdKey, 'axis 4'),
    ];
  }

  /// Create one series with sample hard coded data.
  static List<charts.Series<LinearClicks, int>> createSampleData() {
    // The first three series contain similar data with different magnitudes.
    // This demonstrates the ability to graph the trends in each series relative
    // to each other, without the largest magnitude series compressing the
    // smallest.
    const myFakeDesktopData = [
      LinearClicks(0, clickCount: 25),
      LinearClicks(1, clickCount: 125),
      LinearClicks(2, clickCount: 920),
      LinearClicks(3, clickCount: 375),
    ];

    const myFakeTabletData = [
      LinearClicks(0, clickCount: 375),
      LinearClicks(1, clickCount: 1850),
      LinearClicks(2, clickCount: 9700),
      LinearClicks(3, clickCount: 5000),
    ];

    const myFakeMobileData = [
      LinearClicks(0, clickCount: 5000),
      LinearClicks(1, clickCount: 25000),
      LinearClicks(2, clickCount: 100000),
      LinearClicks(3, clickCount: 75000),
    ];

    // The fourth series renders with decimal values, representing a very
    // different sort ratio-based data. If this was on the same axis as any of
    // the other series, it would be squashed near zero.
    const myFakeClickRateData = [
      LinearClicks(0, clickRate: 0.25),
      LinearClicks(1, clickRate: 0.65),
      LinearClicks(2, clickRate: 0.50),
      LinearClicks(3, clickRate: 0.30),
    ];

    return [
      // We render an empty series on the primary measure axis to ensure that
      // the axis itself gets rendered. This helps us draw the grid lines on the
      // chart.
      charts.Series<LinearClicks, int>(
        id: 'Fake Series',
        domain: (LinearClicks clickCount, _) => clickCount.year,
        measure: (LinearClicks clickCount, _) => clickCount.clickCount,
        data: myFakeClickRateData,
      ),
      charts.Series<LinearClicks, int>(
        id: 'Desktop',
        color: (_, __) => charts.DesktopPalette.blue.shadeDefault,
        domain: (LinearClicks clickCount, _) => clickCount.year,
        measure: (LinearClicks clickCount, _) => clickCount.clickCount,
        data: myFakeDesktopData,
      )
        // Set the 'Desktop' series to use a disjoint axis.
        ..setAttribute(charts.measureAxisIdKey, 'axis 1'),
      charts.Series<LinearClicks, int>(
        id: 'Tablet',
        color: (_, __) => charts.DesktopPalette.red.shadeDefault,
        domain: (LinearClicks clickCount, _) => clickCount.year,
        measure: (LinearClicks clickCount, _) => clickCount.clickCount,
        data: myFakeTabletData,
      )
        // Set the 'Tablet' series to use a disjoint axis.
        ..setAttribute(charts.measureAxisIdKey, 'axis 2'),
      charts.Series<LinearClicks, int>(
        id: 'Mobile',
        color: (_, __) => charts.DesktopPalette.green.shadeDefault,
        domain: (LinearClicks clickCount, _) => clickCount.year,
        measure: (LinearClicks clickCount, _) => clickCount.clickCount,
        data: myFakeMobileData,
      )
        // Set the 'Mobile' series to use a disjoint axis.
        ..setAttribute(charts.measureAxisIdKey, 'axis 3'),
      charts.Series<LinearClicks, int>(
        id: 'Click Rate',
        color: (_, __) => charts.DesktopPalette.purple.shadeDefault,
        domain: (LinearClicks clickCount, _) => clickCount.year,
        measure: (LinearClicks clickCount, _) => clickCount.clickRate,
        data: myFakeClickRateData,
      )
        // Set the 'Click Rate' series to use a disjoint axis.
        ..setAttribute(charts.measureAxisIdKey, 'axis 4'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return charts.LineChart(
      seriesList,
      animate: animate,
      // Configure a primary measure axis that will render grid lines across
      // the chart. This axis uses fake ticks with no labels to ensure that we
      // get 5 grid lines.
      //
      // We do this because disjoint measure axes do not draw any tick
      // elements on the chart.
      primaryMeasureAxis: const charts.NumericAxisSpec(
        tickProviderSpec: charts.StaticNumericTickProviderSpec(
          // Create the ticks to be used the domain axis.
          <charts.TickSpec<num>>[
            charts.TickSpec(0, label: ''),
            charts.TickSpec(1, label: ''),
            charts.TickSpec(2, label: ''),
            charts.TickSpec(3, label: ''),
            charts.TickSpec(4, label: ''),
          ],
        ),
      ),
      behaviors: const [charts.PanAndZoomBehavior()],
      // Create one disjoint measure axis per series on the chart.
      //
      // Disjoint measure axes will be used to scale the rendered data,
      // without drawing any tick elements on either side of the chart.
      disjointMeasureAxes: const {
        'axis 1': charts.NumericAxisSpec(),
        'axis 2': charts.NumericAxisSpec(),
        'axis 3': charts.NumericAxisSpec(),
        'axis 4': charts.NumericAxisSpec(),
      },
    );
  }
}

/// Sample linear data type.
@immutable
class LinearClicks {
  const LinearClicks(this.year, {this.clickCount, this.clickRate});

  final int year;
  final int? clickCount;
  final double? clickRate;
}
