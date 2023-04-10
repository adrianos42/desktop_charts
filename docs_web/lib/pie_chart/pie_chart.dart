// Copyright (C) 2023 Adriano Souza (adriano.souza113@gmail.com)

library pie_chart;

import 'package:desktop/desktop.dart';

import 'package:desktop_charts/desktop_charts.dart' as charts;

import '../defaults.dart';
import 'auto_label.dart';
import 'donut.dart';
import 'gauge.dart';
import 'outside_label.dart';
import 'partial_pie.dart';
import 'simple.dart';

List<(String, String?, WidgetBuilder)> createItems([bool animate = true]) {
  return _createItemsWithSeries(
    simpleSeries: SimplePieChart.createSampleData(),
    outsideLabelSeries: PieOutsideLabelChart.createSampleData(),
    patialSeries: PartialPieChart.createSampleData(),
    simpleDonutSeries: DonutPieChart.createSampleData(),
    autoLabelSeries: DonutAutoLabelChart.createSampleData(),
    gaugeSeries: GaugeChart.createSampleData(),
    animate: animate,
  );
}

List<(String, String?, WidgetBuilder)> _createItemsWithSeries({
  required List<charts.Series<dynamic, int>> simpleSeries,
  required List<charts.Series<dynamic, int>> outsideLabelSeries,
  required List<charts.Series<dynamic, int>> patialSeries,
  required List<charts.Series<dynamic, int>> simpleDonutSeries,
  required List<charts.Series<dynamic, int>> autoLabelSeries,
  required List<charts.Series<dynamic, String>> gaugeSeries,
  bool animate = true,
}) {
  return [
    (
      'Simple Pie Chart',
      'With a single series',
      (context) => SimplePieChart(
            simpleSeries,
            animate: animate,
          ),
    ),
    (
      'Outside Label Pie Chart',
      'With a single series and labels outside the arcs',
      (context) => PieOutsideLabelChart(
            outsideLabelSeries,
            animate: animate,
          ),
    ),
    (
      'Partial Pie Chart',
      'That doesn\'t cover a full revolution',
      (context) => PartialPieChart(
            patialSeries,
            animate: animate,
          ),
    ),
    (
      'Simple Donut Chart',
      'With a single series and a hole in the middle',
      (context) => DonutPieChart(
            simpleDonutSeries,
            animate: animate,
          ),
    ),
    (
      'Auto Label Donut Chart',
      'With a single series, a hole in the middle, and auto-positioned labels',
      (context) => DonutAutoLabelChart(
            autoLabelSeries,
            animate: animate,
          ),
    ),
    (
      'Gauge Chart',
      'That doesn\'t cover a full revolution',
      (context) => GaugeChart(
            gaugeSeries,
            animate: animate,
          ),
    ),
  ];
}

class PiePage extends StatefulWidget {
  const PiePage({super.key});

  @override
  _PiePageState createState() => _PiePageState();
}

class _PiePageState extends State<PiePage> {
  bool _hasAnimation = true;

  late List<charts.Series<dynamic, int>> _simpleSeries;
  late List<charts.Series<dynamic, int>> _outsideLabelSeries;
  late List<charts.Series<dynamic, int>> _patialSeries;
  late List<charts.Series<dynamic, int>> _simpleDonutSeries;
  late List<charts.Series<dynamic, int>> _autoLabelSeries;
  late List<charts.Series<dynamic, String>> _gaugeSeries;

  void _updateRandomData() {
    _simpleSeries = SimplePieChart.createRandomData();
    _outsideLabelSeries = PieOutsideLabelChart.createRandomData();
    _patialSeries = PartialPieChart.createRandomData();
    _simpleDonutSeries = DonutPieChart.createRandomData();
    _autoLabelSeries = DonutAutoLabelChart.createRandomData();
    _gaugeSeries = GaugeChart.createRandomData();
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
        simpleSeries: _simpleSeries,
        outsideLabelSeries: _outsideLabelSeries,
        patialSeries: _patialSeries,
        simpleDonutSeries: _simpleDonutSeries,
        autoLabelSeries: _autoLabelSeries,
        gaugeSeries: _gaugeSeries,
        animate: animate,
      );

  @override
  Widget build(BuildContext context) {
    return Defaults(
      header: 'Pie',
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
