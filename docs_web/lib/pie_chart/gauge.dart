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

class GaugeChartPage extends StatefulWidget {
  const GaugeChartPage({super.key});

  @override
  State<GaugeChartPage> createState() => _GaugeChartPageState();
}

class _GaugeChartPageState extends State<GaugeChartPage> {
  bool _hasAnimation = true;

  void _updateRandomData() {
    _data = GaugeChart.createRandomData();
  }

  void _refresh() {
    setState(() => _updateRandomData());
  }

  @override
  void initState() {
    super.initState();

    _updateRandomData();
  }

  late List<charts.Series<GaugeSegment, String>> _data;

  @override
  Widget build(BuildContext context) {
    return Defaults(
      header: 'Pie',
      items: [
        ItemTitle(
          title: GaugeChart.title,
          subtitle: GaugeChart.subtitle,
          body: (context) => GaugeChart(
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

class GaugeChartBuilder extends ExampleBuilder {
  const GaugeChartBuilder();

  @override
  Widget page([int? index, List<ExampleBuilder>? children]) => const GaugeChartPage();

  @override
  String? get subtitle => GaugeChart.subtitle;

  @override
  String get title => GaugeChart.title;

  @override
  Widget withSampleData([bool animate = true]) =>
      GaugeChart.withSampleData(animate);
}

/// Gauge chart example, where the data does not cover a full revolution in the
/// chart.
class GaugeChart extends StatelessWidget {
  const GaugeChart(
    this.seriesList, {
    this.animate = true,
    super.key,
  });

  /// Creates a [PieChart] with sample data and no transition.
  factory GaugeChart.withSampleData([bool animate = true]) {
    return GaugeChart(
      createSampleData(),
      animate: animate,
    );
  }

  static String get title => 'Gauge';
  static String? get subtitle => 'That doesn\'t cover a full revolution';

  final List<charts.Series<dynamic, String>> seriesList;
  final bool animate;

  /// Create random data.
  static List<charts.Series<GaugeSegment, String>> createRandomData() {
    final random = Random();

    final data = [
      GaugeSegment('Low', random.nextInt(100)),
      GaugeSegment('Acceptable', random.nextInt(100)),
      GaugeSegment('High', random.nextInt(100)),
      GaugeSegment('Highly Unusual', random.nextInt(100)),
    ];

    return [
      charts.Series<GaugeSegment, String>(
        id: 'Segments',
        domain: (GaugeSegment segment, _) => segment.segment,
        measure: (GaugeSegment segment, _) => segment.size,
        data: data,
      )
    ];
  }

  /// Create one series with sample hard coded data.
  static List<charts.Series<GaugeSegment, String>> createSampleData() {
    const data = [
      GaugeSegment('Low', 75),
      GaugeSegment('Acceptable', 100),
      GaugeSegment('High', 50),
      GaugeSegment('Highly Unusual', 5),
    ];

    return [
      charts.Series<GaugeSegment, String>(
        id: 'Segments',
        domain: (GaugeSegment segment, _) => segment.segment,
        measure: (GaugeSegment segment, _) => segment.size,
        data: data,
      )
    ];
  }

   @override
  Widget build(BuildContext context) {
    return charts.PieChart(
      seriesList,
      animate: animate,
      // Configure the width of the pie slices to 30px. The remaining space in
      // the chart will be left as a hole in the center. Adjust the start
      // angle and the arc length of the pie so it resembles a gauge.
      defaultRenderer: const charts.ArcRendererConfig(
        arcWidth: 30,
        startAngle: 4 / 5 * pi,
        arcLength: 7 / 5 * pi,
      ),
    );
  }
}

/// Sample data type.
@immutable
class GaugeSegment {
  const GaugeSegment(this.segment, this.size);

  final String segment;
  final int size;
}
