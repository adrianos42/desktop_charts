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

class SelectionUserManagedBuilder extends ExampleBuilder {
  const SelectionUserManagedBuilder();

  @override
  String? get subtitle => SelectionUserManaged.subtitle;

  @override
  String get title => SelectionUserManaged.title;

  @override
  Widget withSampleData([bool animate = true]) =>
      SelectionUserManaged.withSampleData(animate);
  
  @override
  Widget withData(dynamic data, [bool animate = true]) =>
      SelectionUserManaged(
        data as List<charts.Series<dynamic, String>>,
        animate: animate,
      );

  @override
  dynamic generateRandomData() => SelectionUserManaged.createRandomData();

  @override
  bool get hasParent => true;

  @override
  String get parentTitle => 'Selection';
}

/// Example of using user managed state to programmatically set selection.
///
/// In this example, clicking the "clear selection" button sets the selection
/// to an empty selection. This example also shows that initial selection
/// behavior can still be used with user managed state.
///
/// Note that the picture in this example is not interactive, please run the
/// gallery app to try out using the button to clear selection.
///
class SelectionUserManaged extends StatefulWidget {
  const SelectionUserManaged(
    this.seriesList, {
    this.animate = true,
    super.key,
  });

  /// Creates a [BarChart] with sample data and no transition.
  factory SelectionUserManaged.withSampleData([bool animate = true]) {
    return SelectionUserManaged(
      createSampleData(),
      animate: animate,
    );
  }

  static String get title => 'User Managed';
  static String? get subtitle =>
      'Example where selection can be set and cleared programmatically';

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
  SelectionUserManagedState createState() {
    return SelectionUserManagedState();
  }
}

class SelectionUserManagedState extends State<SelectionUserManaged> {
  final _myState = charts.UserManagedState<String>();

  @override
  Widget build(BuildContext context) {
    final chart = charts.BarChart(
      widget.seriesList,
      animate: false, //widget.animate,
      selectionModels: [
        charts.SelectionModelConfig(
          type: charts.SelectionModelType.info,
          updatedListener: _infoSelectionModelUpdated,
        )
      ],
      // Pass in the state you manage to the chart. This will be used to
      // override the internal chart state.
      userManagedState: _myState,
      // The initial selection can still be optionally added by adding the
      // initial selection behavior.
      behaviors: const [
        charts.InitialSelection(selectedDataConfig: [
          charts.SeriesDatumConfig<String>('Sales', '2016')
        ])
      ],
    );

    final clearSelection = Button(
      onPressed: _handleClearSelection,
      body: const Text(
        'Clear Selection',
      ),
    );

    return Column(children: [
      Expanded(child: chart),
      clearSelection,
    ]);
  }

  void _infoSelectionModelUpdated(charts.SelectionModel<String> model) {
    // If you want to allow the chart to continue to respond to select events
    // that update the selection, add an updatedListener that saves off the
    // selection model each time the selection model is updated, regardless of
    // if there are changes.
    //
    // This also allows you to listen to the selection model update events and
    // alter the selection.
    _myState.selectionModels[charts.SelectionModelType.info] =
        charts.UserManagedSelectionModel(model: model);
  }

  void _handleClearSelection() {
    // Call set state to request a rebuild, to pass in the modified selection.
    // In this case, passing in an empty [UserManagedSelectionModel] creates a
    // no selection model to clear all selection when rebuilt.
    setState(() {
      _myState.selectionModels[charts.SelectionModelType.info] =
          charts.UserManagedSelectionModel();
    });
  }
}

/// Sample ordinal data type.
@immutable
class OrdinalSales {
  const OrdinalSales(this.year, this.sales);

  final String year;
  final int sales;
}
