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

class InitialSelectionPage extends StatefulWidget {
  const InitialSelectionPage({super.key});

  @override
  State<InitialSelectionPage> createState() => _InitialSelectionPageState();
}

class _InitialSelectionPageState extends State<InitialSelectionPage> {
  bool _hasAnimation = true;

  void _updateRandomData() {
    _data = InitialSelection.createRandomData();
  }

  void _refresh() {
    setState(() => _updateRandomData());
  }

  @override
  void initState() {
    super.initState();

    _updateRandomData();
  }

  late List<charts.Series<OrdinalSales, String>> _data;

  @override
  Widget build(BuildContext context) {
    return Defaults(
      header: 'Behaviors',
      items: [
        ItemTitle(
          title: InitialSelection.title,
          subtitle: InitialSelection.subtitle,
          body: (context) => InitialSelection(
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

class InitialSelectionBuilder extends ExampleBuilder {
  const InitialSelectionBuilder();

  @override
  Widget page([int? index, List<ExampleBuilder>? children]) =>
      const InitialSelectionPage();

  @override
  String? get subtitle => InitialSelection.subtitle;

  @override
  String get title => InitialSelection.title;

  @override
  Widget withSampleData([bool animate = true]) =>
      InitialSelection.withSampleData(animate);
}

/// Example of adding an initial selection behavior.
///
/// This example adds initial selection to a bar chart, but any chart can use
/// the initial selection behavior.
///
/// Initial selection is only set on the very first draw and will not be set
/// again in subsequent draws unless the behavior is reconfigured.
///
/// The selection will remain on the chart unless another behavior is added
/// that updates the selection.
class InitialSelection extends StatelessWidget {
  const InitialSelection(
    this.seriesList, {
    this.animate = true,
    super.key,
  });

  /// Creates a [BarChart] with initial selection behavior.
  factory InitialSelection.withSampleData([bool animate = true]) {
    return InitialSelection(
      createSampleData(),
      animate: animate,
    );
  }

  static String get title => 'Bar Chart with initial selection';
  static String? get subtitle => 'Single series with initial selection';

  final List<charts.Series<dynamic, String>> seriesList;
  final bool animate;

  /// Create random data.
  static List<charts.Series<OrdinalSales, String>> createRandomData() {
    final random = Random();

    final data = [
      OrdinalSales('2014', random.nextInt(100)),
      OrdinalSales('2015', random.nextInt(100)),
      OrdinalSales('2016', random.nextInt(100)),
      OrdinalSales('2017', random.nextInt(100)),
    ];

    return [
      charts.Series<OrdinalSales, String>(
        id: 'Sales',
        color: (_, __) => charts.DesktopPalette.blue.shadeDefault,
        domain: (OrdinalSales sales, _) => sales.year,
        measure: (OrdinalSales sales, _) => sales.sales,
        data: data,
      )
    ];
  }

  /// Create one series with sample hard coded data.
  static List<charts.Series<OrdinalSales, String>> createSampleData() {
    const data = [
      OrdinalSales('2014', 5),
      OrdinalSales('2015', 25),
      OrdinalSales('2016', 100),
      OrdinalSales('2017', 75),
    ];

    return [
      charts.Series<OrdinalSales, String>(
        id: 'Sales',
        color: (_, __) => charts.DesktopPalette.blue.shadeDefault,
        domain: (OrdinalSales sales, _) => sales.year,
        measure: (OrdinalSales sales, _) => sales.sales,
        data: data,
      )
    ];
  }

  @override
  Widget build(BuildContext context) {
    return charts.BarChart(
      seriesList,
      animate: animate,
      behaviors: const [
        // Initial selection can be configured by passing in:
        //
        // A list of datum config, specified with series ID and domain value.
        // A list of series config, which is a list of series ID(s).
        //
        // Initial selection can be applied to any chart type.
        //
        // [BarChart] by default includes behaviors [SelectNearest] and
        // [DomainHighlighter]. So this behavior shows the initial selection
        // highlighted and when another datum is tapped, the selection changes.
        charts.InitialSelection(selectedDataConfig: [
          charts.SeriesDatumConfig<String>('Sales', '2016')
        ])
      ],
    );
  }
}

/// Sample ordinal data type.
@immutable
class OrdinalSales {
  const OrdinalSales(this.year, this.sales);

  final String year;
  final int sales;
}
