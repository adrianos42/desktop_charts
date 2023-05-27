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

class SelectionLineHighlightCustomShapeBuilder extends ExampleBuilder {
  const SelectionLineHighlightCustomShapeBuilder();

  @override
  String? get subtitle => SelectionLineHighlightCustomShape.subtitle;

  @override
  String get title => SelectionLineHighlightCustomShape.title;

  @override
  Widget withSampleData([bool animate = true]) =>
      SelectionLineHighlightCustomShape.withSampleData(animate);

  @override
  Widget withData(dynamic data, [bool animate = true]) =>
      SelectionLineHighlightCustomShape(
        data as List<charts.Series<dynamic, num>>,
        animate: animate,
      );

  @override
  dynamic generateRandomData() =>
      SelectionLineHighlightCustomShape.createRandomData();

  @override
  bool get hasParent => true;

  @override
  String get parentTitle => 'Selection';
}

class SelectionLineHighlightCustomShape extends StatelessWidget {
  const SelectionLineHighlightCustomShape(
    this.seriesList, {
    this.animate = true,
    super.key,
  });

  /// Creates a [LineChart] with sample data and no transition.
  factory SelectionLineHighlightCustomShape.withSampleData([
    bool animate = true,
  ]) {
    return SelectionLineHighlightCustomShape(
      createSampleData(),
      animate: animate,
    );
  }

  static String get title => 'Line Highlight Custom Shape';
  static String? get subtitle =>
      'Line chart with tap and drag activation and a custom shape';

  final List<charts.Series<dynamic, num>> seriesList;
  final bool animate;

  /// Create random data.
  static List<charts.Series<LinearSales, num>> createRandomData() {
    final random = Random();

    final data = [
      LinearSales(0, random.nextInt(100)),
      LinearSales(1, random.nextInt(100)),
      LinearSales(2, random.nextInt(100)),
      LinearSales(3, random.nextInt(100)),
    ];

    return [
      charts.Series<LinearSales, int>(
        id: 'Sales',
        domain: (LinearSales sales, _) => sales.year,
        measure: (LinearSales sales, _) => sales.sales,
        data: data,
      )
    ];
  }

  /// Create one series with sample hard coded data.
  static List<charts.Series<LinearSales, int>> createSampleData() {
    const data = [
      LinearSales(0, 5),
      LinearSales(1, 25),
      LinearSales(2, 100),
      LinearSales(3, 75),
    ];

    return [
      charts.Series<LinearSales, int>(
        id: 'Sales',
        domain: (LinearSales sales, _) => sales.year,
        measure: (LinearSales sales, _) => sales.sales,
        data: data,
      )
    ];
  }

  @override
  Widget build(BuildContext context) {
    // This is a simple line chart with a behavior that highlights hovered
    // lines. A hollow rectangular shape will be drawn at the hovered datum's
    // x,y coordinate, and a vertical follow line will be drawn through it.
    //
    // A [Charts.LinePointHighlighter] behavior is added manually to enable the
    // highlighting effect.
    //
    // As an alternative, [defaultInteractions] can be set to true to include
    // the default chart interactions, including a LinePointHighlighter.
    return charts.LineChart(seriesList, animate: animate, behaviors: const [
      // Optional - Configures a [LinePointHighlighter] behavior with a
      // vertical follow line. A vertical follow line is included by
      // default, but is shown here as an example configuration.
      //
      // By default, the line has default dash pattern of [1,3]. This can be
      // set by providing a [dashPattern] or it can be turned off by passing in
      // an empty list. An empty list is necessary because passing in a null
      // value will be treated the same as not passing in a value at all.
      //
      // The symbol renderer is configured to render a hollow shape, for
      // demonstration.
      charts.LinePointHighlighter(
        showHorizontalFollowLine:
            charts.LinePointHighlighterFollowLineType.none,
        showVerticalFollowLine:
            charts.LinePointHighlighterFollowLineType.nearest,
        symbolRenderer: charts.RectSymbolRenderer(isSolid: false),
      ),
      // Optional - By default, select nearest is configured to trigger
      // with tap so that a user can have pan/zoom behavior and line point
      // highlighter. Changing the trigger to tap and drag allows the
      // highlighter to follow the dragging gesture but it is not
      // recommended to be used when pan/zoom behavior is enabled.
      charts.SelectNearest(eventTrigger: charts.SelectionTrigger.tapAndDrag)
    ]);
  }
}

/// Sample linear data type.
@immutable
class LinearSales {
  const LinearSales(this.year, this.sales);

  final int year;
  final int sales;
}