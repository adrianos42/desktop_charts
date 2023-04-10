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

/// Gauge chart example, where the data does not cover a full revolution in the
/// chart.

import 'dart:math';

import 'package:desktop/desktop.dart';
import 'package:desktop_charts/desktop_charts.dart' as charts;

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

  // This section is excluded from being copied to the gallery.
  // It is used for creating random series data to demonstrate animation in
  // the example app only.
  factory GaugeChart.withRandomData([bool animate = true]) {
    return GaugeChart(
      createRandomData(),
      animate: animate,
    );
  }

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

  @override
  Widget build(BuildContext context) {
    return charts.PieChart(
      seriesList,
      animate: animate,
      // Configure the width of the pie slices to 30px. The remaining space in
      // the chart will be left as a hole in the center. Adjust the start
      // angle and the arc length of the pie so it resembles a gauge.
      defaultRenderer: charts.ArcRendererConfig(
        arcWidth: 30,
        startAngle: 4 / 5 * pi,
        arcLength: 7 / 5 * pi,
      ),
    );
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
}

/// Sample data type.
@immutable
class GaugeSegment {
  const GaugeSegment(this.segment, this.size);

  final String segment;
  final int size;
}
