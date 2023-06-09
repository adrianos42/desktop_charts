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

class OrdinalInitialViewportPage extends StatefulWidget {
  const OrdinalInitialViewportPage({super.key});

  @override
  State<OrdinalInitialViewportPage> createState() =>
      _OrdinalInitialViewportPageState();
}

class _OrdinalInitialViewportPageState
    extends State<OrdinalInitialViewportPage> {
  bool _hasAnimation = true;

  void _updateRandomData() {
    _data = OrdinalInitialViewport.createRandomData();
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
      header: 'Axes',
      items: [
        ItemTitle(
          title: OrdinalInitialViewport.title,
          subtitle: OrdinalInitialViewport.subtitle,
          body: (context) => OrdinalInitialViewport(
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

class OrdinalInitialViewportBuilder extends ExampleBuilder {
  const OrdinalInitialViewportBuilder();

  @override
  Widget page([int? index, List<ExampleBuilder>? children]) =>
      const OrdinalInitialViewportPage();

  @override
  String? get subtitle => OrdinalInitialViewport.subtitle;

  @override
  String get title => OrdinalInitialViewport.title;

  @override
  Widget withSampleData([bool animate = true]) =>
      OrdinalInitialViewport.withSampleData(animate);
}

/// Example of setting an initial viewport for ordinal axis.
///
/// This allows for specifying the specific range of data to show that differs
/// from what was provided in the series list.
///
/// In this example, the series list has ordinal data from year 2014 to 2030,
/// but we want to show starting at 2018 and we only want to show 4 values.
/// We can do this by specifying an [OrdinalViewport] in [OrdinalAxisSpec].
class OrdinalInitialViewport extends StatelessWidget {
  const OrdinalInitialViewport(
    this.seriesList, {
    this.animate = true,
    super.key,
  });

  /// Creates a [BarChart] with sample data and no transition.
  factory OrdinalInitialViewport.withSampleData([bool animate = true]) {
    return OrdinalInitialViewport(
      createSampleData(),
      animate: animate,
    );
  }

  static String get title => 'Ordinal axis with initial viewport';
  static String? get subtitle => 'Single series with initial viewport';

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
      OrdinalSales('2018', random.nextInt(100)),
      OrdinalSales('2019', random.nextInt(100)),
      OrdinalSales('2020', random.nextInt(100)),
      OrdinalSales('2021', random.nextInt(100)),
      OrdinalSales('2022', random.nextInt(100)),
      OrdinalSales('2023', random.nextInt(100)),
      OrdinalSales('2024', random.nextInt(100)),
      OrdinalSales('2025', random.nextInt(100)),
      OrdinalSales('2026', random.nextInt(100)),
      OrdinalSales('2027', random.nextInt(100)),
      OrdinalSales('2028', random.nextInt(100)),
      OrdinalSales('2029', random.nextInt(100)),
      OrdinalSales('2030', random.nextInt(100)),
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
      OrdinalSales('2018', 33),
      OrdinalSales('2019', 80),
      OrdinalSales('2020', 21),
      OrdinalSales('2021', 77),
      OrdinalSales('2022', 8),
      OrdinalSales('2023', 12),
      OrdinalSales('2024', 42),
      OrdinalSales('2025', 70),
      OrdinalSales('2026', 77),
      OrdinalSales('2027', 55),
      OrdinalSales('2028', 19),
      OrdinalSales('2029', 66),
      OrdinalSales('2030', 27),
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
      // Set the initial viewport by providing a AxisSpec with the
      // desired viewport: a starting domain and the data size.
      domainAxis: const charts.OrdinalAxisSpec(
        viewport: charts.OrdinalViewport('2018', 4),
      ),
      // Optionally add a pan or pan and zoom behavior.
      // If pan/zoom is not added, the viewport specified remains the viewport.
      behaviors: const [charts.PanAndZoomBehavior()],
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
