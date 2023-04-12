// Copyright (C) 2023 Adriano Souza (adriano.souza113@gmail.com)

library sunburst_chart;

import 'package:desktop/desktop.dart';

import 'package:desktop_charts/desktop_charts.dart' as charts;

import '../defaults.dart';
import 'simple.dart';

List<(String, String?, WidgetBuilder)> createItems([bool animate = true]) {
  return _createItemsWithSeries(
    simpleSeries: SimpleSunburstChart.createSampleData(),
    animate: animate,
  );
}

List<(String, String?, WidgetBuilder)> _createItemsWithSeries({
  required List<charts.Series<dynamic, int>> simpleSeries,
  bool animate = true,
}) {
  return [
    (
      'Simple Sunburst Chart',
      'With a single series',
      (context) => SimpleSunburstChart(
            simpleSeries,
            animate: animate,
          ),
    ),
  ];
}

class SunburstPage extends StatefulWidget {
  const SunburstPage({super.key});

  @override
  _SunburstPageState createState() => _SunburstPageState();
}

class _SunburstPageState extends State<SunburstPage> {
  bool _hasAnimation = true;

  late List<charts.Series<dynamic, int>> _simpleSeries;

  void _updateRandomData() {
    _simpleSeries = SimpleSunburstChart.createRandomData();
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
        animate: animate,
      );

  @override
  Widget build(BuildContext context) {
    return Defaults(
      header: 'Sunburst',
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
