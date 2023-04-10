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

/// Example of a scatter plot chart with a bucketing measure axis and a legend.
///
/// A bucketing measure axis positions all values beneath a certain threshold
/// into a reserved space on the axis range. The label for the bucket line will
/// be drawn in the middle of the bucket range, rather than aligned with the
/// gridline for that value's position on the scale.

import 'dart:math';

import 'package:desktop/desktop.dart';
import 'package:desktop_charts/desktop_charts.dart' as charts;

class BucketingAxisScatterPlotChart extends StatelessWidget {
  const BucketingAxisScatterPlotChart(
    this.seriesList, {
    this.animate = true,
    super.key,
  });

  /// Creates a [ScatterPlotChart] with sample data and no transition.
  factory BucketingAxisScatterPlotChart.withSampleData([bool animate = true]) {
    return BucketingAxisScatterPlotChart(
      createSampleData(),
      animate: animate,
    );
  }

  // This section is excluded from being copied to the gallery.
  // It is used for creating random series data to demonstrate animation in
  // the example app only.
  factory BucketingAxisScatterPlotChart.withRandomData([bool animate = true]) {
    return BucketingAxisScatterPlotChart(
      createRandomData(),
      animate: animate,
    );
  }

  final List<charts.Series<dynamic, num>> seriesList;
  final bool animate;

  /// Create random data.
  static List<charts.Series<LinearSales, int>> createRandomData() {
    final random = Random();

    double makeRadius(int value) => (random.nextInt(value) + 6).toDouble();

    // Make sure that the measure values for the first five series are well
    // above the threshold. This simulates the grouping of the small values into
    // the "Other" series.
    final myFakeDesktopData = [
      LinearSales(
          random.nextInt(100), (random.nextInt(50) + 50) / 100, makeRadius(6)),
    ];

    final myFakeTabletData = [
      LinearSales(
          random.nextInt(100), (random.nextInt(50) + 50) / 100, makeRadius(6)),
    ];

    final myFakeMobileData = [
      LinearSales(
          random.nextInt(100), (random.nextInt(50) + 50) / 100, makeRadius(6)),
    ];

    final myFakeChromebookData = [
      LinearSales(
          random.nextInt(100), (random.nextInt(50) + 50) / 100, makeRadius(6)),
    ];

    final myFakeHomeData = [
      LinearSales(
          random.nextInt(100), (random.nextInt(50) + 50) / 100, makeRadius(6)),
    ];

    // Make sure that the "Other" series values are smaller.
    final myFakeOtherData = [
      LinearSales(random.nextInt(100), random.nextInt(50) / 100, makeRadius(6)),
      LinearSales(random.nextInt(100), random.nextInt(50) / 100, makeRadius(6)),
      LinearSales(random.nextInt(100), random.nextInt(50) / 100, makeRadius(6)),
      LinearSales(random.nextInt(100), random.nextInt(50) / 100, makeRadius(6)),
      LinearSales(random.nextInt(100), random.nextInt(50) / 100, makeRadius(6)),
      LinearSales(random.nextInt(100), random.nextInt(50) / 100, makeRadius(6)),
    ];

    return [
      charts.Series<LinearSales, int>(
          id: 'Desktop',
          color: (LinearSales sales, _) =>
              charts.DesktopPalette.blue.shadeDefault,
          domain: (LinearSales sales, _) => sales.year,
          measure: (LinearSales sales, _) => sales.revenueShare,
          radius: (LinearSales sales, _) => sales.radius,
          data: myFakeDesktopData),
      charts.Series<LinearSales, int>(
          id: 'Tablet',
          color: (LinearSales sales, _) =>
              charts.DesktopPalette.red.shadeDefault,
          domain: (LinearSales sales, _) => sales.year,
          measure: (LinearSales sales, _) => sales.revenueShare,
          radius: (LinearSales sales, _) => sales.radius,
          data: myFakeTabletData),
      charts.Series<LinearSales, int>(
          id: 'Mobile',
          color: (LinearSales sales, _) =>
              charts.DesktopPalette.green.shadeDefault,
          domain: (LinearSales sales, _) => sales.year,
          measure: (LinearSales sales, _) => sales.revenueShare,
          radius: (LinearSales sales, _) => sales.radius,
          data: myFakeMobileData),
      charts.Series<LinearSales, int>(
          id: 'Chromebook',
          color: (LinearSales sales, _) =>
              charts.DesktopPalette.purple.shadeDefault,
          domain: (LinearSales sales, _) => sales.year,
          measure: (LinearSales sales, _) => sales.revenueShare,
          radius: (LinearSales sales, _) => sales.radius,
          data: myFakeChromebookData),
      charts.Series<LinearSales, int>(
          id: 'Home',
          color: (LinearSales sales, _) =>
              charts.DesktopPalette.indigo.shadeDefault,
          domain: (LinearSales sales, _) => sales.year,
          measure: (LinearSales sales, _) => sales.revenueShare,
          radius: (LinearSales sales, _) => sales.radius,
          data: myFakeHomeData),
      charts.Series<LinearSales, int>(
          id: 'Other',
          color: (LinearSales sales, _) => charts.DesktopPalette.gray,
          domain: (LinearSales sales, _) => sales.year,
          measure: (LinearSales sales, _) => sales.revenueShare,
          radius: (LinearSales sales, _) => sales.radius,
          data: myFakeOtherData),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return charts.ScatterPlotChart(seriesList,
        // Set up a bucketing axis that will place all values below 0.1 (10%)
        // into a bucket at the bottom of the chart.
        //
        // Configure a tick count of 3 so that we get 100%, 50%, and the
        // threshold.
        primaryMeasureAxis: charts.BucketingAxisSpec(
            threshold: 0.1,
            tickProviderSpec: const charts.BucketingNumericTickProviderSpec(
              desiredTickCount: 3,
            )),
        // Add a series legend to display the series names.
        behaviors: [
          // TODO charts.SeriesLegend(position: charts.BehaviorPosition.end),
        ],
        animate: animate);
  }

  /// Create one series with sample hard coded data.
  static List<charts.Series<LinearSales, int>> createSampleData() {
    const myFakeDesktopData = [
      LinearSales(52, 0.75, 14.0),
    ];

    const myFakeTabletData = [
      LinearSales(45, 0.3, 18.0),
    ];

    const myFakeMobileData = [
      LinearSales(56, 0.8, 17.0),
    ];

    const myFakeChromebookData = [
      LinearSales(25, 0.6, 13.0),
    ];

    const myFakeHomeData = [
      LinearSales(34, 0.5, 15.0),
    ];

    const myFakeOtherData = [
      LinearSales(10, 0.25, 15.0),
      LinearSales(12, 0.075, 14.0),
      LinearSales(13, 0.225, 15.0),
      LinearSales(16, 0.03, 14.0),
      LinearSales(24, 0.04, 13.0),
      LinearSales(37, 0.1, 14.5),
    ];

    return [
      charts.Series<LinearSales, int>(
        id: 'Desktop',
        color: (LinearSales sales, _) =>
            charts.DesktopPalette.blue.shadeDefault,
        domain: (LinearSales sales, _) => sales.year,
        measure: (LinearSales sales, _) => sales.revenueShare,
        radius: (LinearSales sales, _) => sales.radius,
        data: myFakeDesktopData,
      ),
      charts.Series<LinearSales, int>(
        id: 'Tablet',
        color: (LinearSales sales, _) => charts.DesktopPalette.red.shadeDefault,
        domain: (LinearSales sales, _) => sales.year,
        measure: (LinearSales sales, _) => sales.revenueShare,
        radius: (LinearSales sales, _) => sales.radius,
        data: myFakeTabletData,
      ),
      charts.Series<LinearSales, int>(
        id: 'Mobile',
        color: (LinearSales sales, _) =>
            charts.DesktopPalette.green.shadeDefault,
        domain: (LinearSales sales, _) => sales.year,
        measure: (LinearSales sales, _) => sales.revenueShare,
        radius: (LinearSales sales, _) => sales.radius,
        data: myFakeMobileData,
      ),
      charts.Series<LinearSales, int>(
        id: 'Chromebook',
        color: (LinearSales sales, _) =>
            charts.DesktopPalette.purple.shadeDefault,
        domain: (LinearSales sales, _) => sales.year,
        measure: (LinearSales sales, _) => sales.revenueShare,
        radius: (LinearSales sales, _) => sales.radius,
        data: myFakeChromebookData,
      ),
      charts.Series<LinearSales, int>(
        id: 'Home',
        color: (LinearSales sales, _) =>
            charts.DesktopPalette.indigo.shadeDefault,
        domain: (LinearSales sales, _) => sales.year,
        measure: (LinearSales sales, _) => sales.revenueShare,
        radius: (LinearSales sales, _) => sales.radius,
        data: myFakeHomeData,
      ),
      charts.Series<LinearSales, int>(
        id: 'Other',
        color: (LinearSales sales, _) => charts.DesktopPalette.gray,
        domain: (LinearSales sales, _) => sales.year,
        measure: (LinearSales sales, _) => sales.revenueShare,
        radius: (LinearSales sales, _) => sales.radius,
        data: myFakeOtherData,
      ),
    ];
  }
}

/// Sample linear data type.
@immutable
class LinearSales {
  const LinearSales(this.year, this.revenueShare, this.radius);

  final int year;
  final double revenueShare;
  final double radius;
}
