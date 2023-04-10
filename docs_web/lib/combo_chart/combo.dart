// Copyright (C) 2023 Adriano Souza (adriano.souza113@gmail.com)

library combo;

import 'package:desktop/desktop.dart';

import 'package:desktop_charts/desktop_charts.dart' as charts;

import '../defaults.dart';

import 'date_time_line_point.dart';
import 'numeric_line_bar.dart';
import 'numeric_line_point.dart';
import 'ordinal_bar_line.dart';
import 'scatter_plot_line.dart';

List<(String, String?, WidgetBuilder)> createItems([bool animate = true]) {
  return _createItemsWithSeries(
    ordinalComboBarLineSeries: OrdinalComboBarLineChart.createSampleData(),
    numericComboLineBarSeries: NumericComboLineBarChart.createSampleData(),
    numericComboLinePointSeries: NumericComboLinePointChart.createSampleData(),
    dateTimeComboLinePointSeries: DateTimeComboLinePointChart.createSampleData(),
    scatterPlotComboLineSeries: ScatterPlotComboLineChart.createSampleData(),
    animate: animate,
  );
}

List<(String, String?, WidgetBuilder)> _createItemsWithSeries({
  required List<charts.Series<dynamic, String>> ordinalComboBarLineSeries,
  required List<charts.Series<dynamic, num>> numericComboLineBarSeries,
  required List<charts.Series<dynamic, num>> numericComboLinePointSeries,
  required List<charts.Series<dynamic, DateTime>> dateTimeComboLinePointSeries,
  required List<charts.Series<dynamic, num>> scatterPlotComboLineSeries,
  bool animate = true,
}) {
  return [
    (
      'Ordinal Combo Chart',
      'Ordinal combo chart with bars and lines',
      (context) => OrdinalComboBarLineChart(
            ordinalComboBarLineSeries,
            animate: animate,
          ),
    ),
    (
      'Numeric Line Bar Combo Chart',
      'Numeric combo chart with lines and bars',
      (context) => NumericComboLineBarChart(
            numericComboLineBarSeries,
            animate: animate,
          ),
    ),
    (
      'Numeric Line Points Combo Chart',
      'Numeric combo chart with lines and points',
      (context) => NumericComboLinePointChart(
            numericComboLinePointSeries,
            animate: animate,
          ),
    ),
    (
      'Time Series Combo Chart',
      'Time series combo chart with lines and points',
      (context) => DateTimeComboLinePointChart(
            dateTimeComboLinePointSeries,
            animate: animate,
          ),
    ),
    (
      'Scatter Plot Combo Chart',
      'Scatter plot combo chart with a line',
      (context) => ScatterPlotComboLineChart(
            scatterPlotComboLineSeries,
            animate: animate,
          ),
    ),
  ];
}

class ComboPage extends StatefulWidget {
  const ComboPage({super.key});

  @override
  _ComboPageState createState() => _ComboPageState();
}

class _ComboPageState extends State<ComboPage> {
  bool _hasAnimation = true;

  late List<charts.Series<dynamic, String>> _ordinalComboBarLineSeries;
  late List<charts.Series<dynamic, num>> _numericComboLineBarSeries;
  late List<charts.Series<dynamic, num>> _numericComboLinePointSeries;
  late List<charts.Series<dynamic, DateTime>> _dateTimeComboLinePointSeries;
  late List<charts.Series<dynamic, num>> _scatterPlotComboLineSeries;

  void _updateRandomData() {
    _ordinalComboBarLineSeries = OrdinalComboBarLineChart.createRandomData();
    _numericComboLineBarSeries = NumericComboLineBarChart.createRandomData();
    _numericComboLinePointSeries = NumericComboLinePointChart.createRandomData();
    _dateTimeComboLinePointSeries =
        DateTimeComboLinePointChart.createRandomData();
    _scatterPlotComboLineSeries = ScatterPlotComboLineChart.createRandomData();
  }

  void _refresh() {
    setState(() => _updateRandomData());
  }

  @override
  void initState() {
    super.initState();

    _updateRandomData();
  }

  List<(String, String?, WidgetBuilder)> _createItems([bool animate = true]) =>
      _createItemsWithSeries(
        ordinalComboBarLineSeries: _ordinalComboBarLineSeries,
        numericComboLineBarSeries: _numericComboLineBarSeries,
        numericComboLinePointSeries: _numericComboLinePointSeries,
        dateTimeComboLinePointSeries: _dateTimeComboLinePointSeries,
        scatterPlotComboLineSeries: _scatterPlotComboLineSeries,
        animate: animate,
      );

  @override
  Widget build(BuildContext context) {
    return Defaults(
      header: 'Combo',
      items: _createItems(_hasAnimation)
          .map(
            (e) => ItemTitle(
              title: e.$1,
              subtitle: e.$2,
              options: [
                Button.icon(
                  Icons.animation,
                  onPressed: () =>
                      setState(() => _hasAnimation = !_hasAnimation),
                  active: _hasAnimation,
                ),
                Button.icon(Icons.refresh, onPressed: _refresh),
              ],
              body: e.$3,
            ),
          )
          .toList(),
    );
  }
}
