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

/// Example of a RTL stacked area chart with changing styles within each line.
///
/// Each series of data in this example contains different values for color,
/// dashPattern, or strokeWidthPx between each datum. The line and area skirt
/// will be rendered in segments, with the styling of the series changing when
/// these data attributes change.
///
/// Note that if a dashPattern or strokeWidth value is not found for a
/// particular datum, then the chart will fall back to use the value defined in
/// the [charts.LineRendererConfig]. This could be used, for example, to define
/// a default dash pattern for the series, with only a specific datum called out
/// with a different pattern.

import 'dart:math';

import 'package:desktop/desktop.dart';
import 'package:desktop_charts/desktop_charts.dart' as charts;

class RTLLineSegments extends StatelessWidget {
  const RTLLineSegments(
    this.seriesList, {
    this.animate = true,
    super.key,
  });

  /// Creates a [LineChart] with sample data and no transition.
  factory RTLLineSegments.withSampleData([bool animate = true]) {
    return RTLLineSegments(
      createSampleData(),
      animate: animate,
    );
  }

  // This section is excluded from being copied to the gallery.
  // It is used for creating random series data to demonstrate animation in
  // the example app only.
  factory RTLLineSegments.withRandomData([bool animate = true]) {
    return RTLLineSegments(
      createRandomData(),
      animate: animate,
    );
  }

  final List<charts.Series<dynamic, num>> seriesList;
  final bool animate;

  /// Create random data.
  static List<charts.Series<LinearSales, num>> createRandomData() {
    final random = Random();

    // Series of data with static dash pattern and stroke width. The color
    // accessor will colorize each datum (for all three series).
    final colorChangeData = [
      LinearSales(0, random.nextInt(100), null, 2.0),
      LinearSales(1, random.nextInt(100), null, 2.0),
      LinearSales(2, random.nextInt(100), null, 2.0),
      LinearSales(3, random.nextInt(100), null, 2.0),
      LinearSales(4, random.nextInt(100), null, 2.0),
      LinearSales(5, random.nextInt(100), null, 2.0),
      LinearSales(6, random.nextInt(100), null, 2.0),
    ];

    // Series of data with changing color and dash pattern.
    final dashPatternChangeData = [
      LinearSales(0, random.nextInt(100), const [2, 2], 2.0),
      LinearSales(1, random.nextInt(100), const [2, 2], 2.0),
      LinearSales(2, random.nextInt(100), const [4, 4], 2.0),
      LinearSales(3, random.nextInt(100), const [4, 4], 2.0),
      LinearSales(4, random.nextInt(100), const [4, 4], 2.0),
      LinearSales(5, random.nextInt(100), const [8, 3, 2, 3], 2.0),
      LinearSales(6, random.nextInt(100), const [8, 3, 2, 3], 2.0),
    ];

    // Series of data with changing color and stroke width.
    final strokeWidthChangeData = [
      LinearSales(0, random.nextInt(100), null, 2.0),
      LinearSales(1, random.nextInt(100), null, 2.0),
      LinearSales(2, random.nextInt(100), null, 4.0),
      LinearSales(3, random.nextInt(100), null, 4.0),
      LinearSales(4, random.nextInt(100), null, 4.0),
      LinearSales(5, random.nextInt(100), null, 6.0),
      LinearSales(6, random.nextInt(100), null, 6.0),
    ];

    // Generate 2 shades of each color so that we can style the line segments.
    final blue = charts.DesktopPalette.blue.makeShades(2);
    final red = charts.DesktopPalette.red.makeShades(2);
    final green = charts.DesktopPalette.green.makeShades(2);

    return [
      charts.Series<LinearSales, int>(
        id: 'Color Change',
        // Light shade for even years, dark shade for odd.
        color: (LinearSales sales, _) => sales.year.isEven ? blue[1] : blue[0],
        dashPattern: (LinearSales sales, _) => sales.dashPattern,
        strokeWidth: (LinearSales sales, _) => sales.strokeWidth,
        domain: (LinearSales sales, _) => sales.year,
        measure: (LinearSales sales, _) => sales.sales,
        data: colorChangeData,
      ),
      charts.Series<LinearSales, int>(
        id: 'Dash Pattern Change',
        // Light shade for even years, dark shade for odd.
        color: (LinearSales sales, _) => sales.year % 2 == 0 ? red[1] : red[0],
        dashPattern: (LinearSales sales, _) => sales.dashPattern,
        strokeWidth: (LinearSales sales, _) => sales.strokeWidth,
        domain: (LinearSales sales, _) => sales.year,
        measure: (LinearSales sales, _) => sales.sales,
        data: dashPatternChangeData,
      ),
      charts.Series<LinearSales, int>(
        id: 'Stroke Width Change',
        // Light shade for even years, dark shade for odd.
        color: (LinearSales sales, _) =>
            sales.year.isEven ? green[1] : green[0],
        dashPattern: (LinearSales sales, _) => sales.dashPattern,
        strokeWidth: (LinearSales sales, _) => sales.strokeWidth,
        domain: (LinearSales sales, _) => sales.year,
        measure: (LinearSales sales, _) => sales.sales,
        data: strokeWidthChangeData,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    // Charts will determine if RTL is enabled by checking the directionality by
    // requesting Directionality.of(context). This returns the text direction
    // from the closest instance of that encloses the context passed to build
    // the chart. A [TextDirection.rtl] will be treated as a RTL chart. This
    // means that the directionality widget does not have to directly wrap each
    // chart. It is show here as an example only.
    //
    // By default, when a chart detects RTL:
    // Measure axis positions are flipped. Primary measure axis is on the right
    // and the secondary measure axis is on the left (when used).
    // Domain axis' first domain starts on the right and grows left.
    return Directionality(
      textDirection: TextDirection.rtl,
      child: charts.LineChart(
        seriesList,
        defaultRenderer:
            charts.LineRendererConfig(includeArea: true, stacked: true),
        animate: animate,
      ),
    );
  }

  /// Create one series with sample hard coded data.
  static List<charts.Series<LinearSales, int>> createSampleData() {
    // Series of data with static dash pattern and stroke width. The color
    // accessor will colorize each datum (for all three series).
    const colorChangeData = [
      LinearSales(0, 5, null, 2.0),
      LinearSales(1, 15, null, 2.0),
      LinearSales(2, 25, null, 2.0),
      LinearSales(3, 75, null, 2.0),
      LinearSales(4, 100, null, 2.0),
      LinearSales(5, 90, null, 2.0),
      LinearSales(6, 75, null, 2.0),
    ];

    // Series of data with changing color and dash pattern.
    const dashPatternChangeData = [
      LinearSales(0, 5, [2, 2], 2.0),
      LinearSales(1, 15, [2, 2], 2.0),
      LinearSales(2, 25, [4, 4], 2.0),
      LinearSales(3, 75, [4, 4], 2.0),
      LinearSales(4, 100, [4, 4], 2.0),
      LinearSales(5, 90, [8, 3, 2, 3], 2.0),
      LinearSales(6, 75, [8, 3, 2, 3], 2.0),
    ];

    // Series of data with changing color and stroke width.
    const strokeWidthChangeData = [
      LinearSales(0, 5, null, 2.0),
      LinearSales(1, 15, null, 2.0),
      LinearSales(2, 25, null, 4.0),
      LinearSales(3, 75, null, 4.0),
      LinearSales(4, 100, null, 4.0),
      LinearSales(5, 90, null, 6.0),
      LinearSales(6, 75, null, 6.0),
    ];

    // Generate 2 shades of each color so that we can style the line segments.
    final blue = charts.DesktopPalette.blue.makeShades(2);
    final red = charts.DesktopPalette.red.makeShades(2);
    final green = charts.DesktopPalette.green.makeShades(2);

    return [
      charts.Series<LinearSales, int>(
        id: 'Color Change',
        // Light shade for even years, dark shade for odd.
        color: (LinearSales sales, _) => sales.year.isEven ? blue[1] : blue[0],
        dashPattern: (LinearSales sales, _) => sales.dashPattern,
        strokeWidth: (LinearSales sales, _) => sales.strokeWidth,
        domain: (LinearSales sales, _) => sales.year,
        measure: (LinearSales sales, _) => sales.sales,
        data: colorChangeData,
      ),
      charts.Series<LinearSales, int>(
        id: 'Dash Pattern Change',
        // Light shade for even years, dark shade for odd.
        color: (LinearSales sales, _) => sales.year.isEven ? red[1] : red[0],
        dashPattern: (LinearSales sales, _) => sales.dashPattern,
        strokeWidth: (LinearSales sales, _) => sales.strokeWidth,
        domain: (LinearSales sales, _) => sales.year,
        measure: (LinearSales sales, _) => sales.sales,
        data: dashPatternChangeData,
      ),
      charts.Series<LinearSales, int>(
        id: 'Stroke Width Change',
        // Light shade for even years, dark shade for odd.
        color: (LinearSales sales, _) =>
            sales.year.isEven ? green[1] : green[0],
        dashPattern: (LinearSales sales, _) => sales.dashPattern,
        strokeWidth: (LinearSales sales, _) => sales.strokeWidth,
        domain: (LinearSales sales, _) => sales.year,
        measure: (LinearSales sales, _) => sales.sales,
        data: strokeWidthChangeData,
      ),
    ];
  }
}

/// Sample linear data type.
@immutable
class LinearSales {
  const LinearSales(this.year, this.sales, this.dashPattern, this.strokeWidth);

  final int year;
  final int sales;
  final List<int>? dashPattern;
  final double strokeWidth;
}
