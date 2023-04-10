// Copyright (C) 2023 Adriano Souza (adriano.souza113@gmail.com)

library i18n;

import 'package:desktop/desktop.dart';
import 'package:desktop_charts/desktop_charts.dart' as charts;

import 'rtl_bar_chart.dart';
import 'rtl_line_chart.dart';
import 'rtl_line_segments.dart';
import 'rtl_series_legend.dart';

import '../defaults.dart';

List<(String, String?, WidgetBuilder)> createItems([bool animate = true]) {
  return _createItemsWithSeries(
    rtlBarChartSeries: RTLBarChart.createSampleData(),
    rtlLineChartSeries: RTLLineChart.createSampleData(),
    rtlLineSegmentsSeries: RTLLineSegments.createSampleData(),
    rtlSeriesLegendSeries: RTLSeriesLegend.createSampleData(),
    animate: animate,
  );
}

List<(String, String?, WidgetBuilder)> _createItemsWithSeries({
  required List<charts.Series<dynamic, String>> rtlBarChartSeries,
  required List<charts.Series<dynamic, num>> rtlLineChartSeries,
  required List<charts.Series<dynamic, num>> rtlLineSegmentsSeries,
  required List<charts.Series<dynamic, String>> rtlSeriesLegendSeries,
  bool animate = true,
}) {
  return [
    (
      'RTL Bar Chart',
      'Simple bar chart in RTL',
      (context) => RTLBarChart(
            rtlBarChartSeries,
            animate: animate,
          ),
    ),
    (
      'RTL Line Chart',
      'Simple line chart in RTL',
      (context) => RTLLineChart(
            rtlLineChartSeries,
            animate: animate,
          ),
    ),
    (
      'RTL Line Segments',
      'Stacked area chart with style segments in RTL',
      (context) => RTLLineSegments(
            rtlLineSegmentsSeries,
            animate: animate,
          ),
    ),
    (
      'RTL Series Legend',
      'Series legend in RTL',
      (context) => RTLSeriesLegend(
            rtlSeriesLegendSeries,
            animate: animate,
          ),
    )
  ];
}

class I18nPage extends StatefulWidget {
  const I18nPage({super.key});

  @override
  _I18nPageState createState() => _I18nPageState();
}

class _I18nPageState extends State<I18nPage> {
  bool _hasAnimation = true;

  late List<charts.Series<dynamic, String>> _rtlBarChartSeries;
  late List<charts.Series<dynamic, num>> _rtlLineChartSeries;
  late List<charts.Series<dynamic, num>> _rtlLineSegmentsSeries;
  late List<charts.Series<dynamic, String>> _rtlSeriesLegendSeries;

  void _updateRandomData() {
    _rtlBarChartSeries = RTLBarChart.createRandomData();
    _rtlLineChartSeries = RTLLineChart.createRandomData();
    _rtlLineSegmentsSeries = RTLLineSegments.createRandomData();
    _rtlSeriesLegendSeries = RTLSeriesLegend.createRandomData();
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
        rtlBarChartSeries: _rtlBarChartSeries,
        rtlLineChartSeries: _rtlLineChartSeries,
        rtlLineSegmentsSeries: _rtlLineSegmentsSeries,
        rtlSeriesLegendSeries: _rtlSeriesLegendSeries,
        animate: animate,
      );

  @override
  Widget build(BuildContext context) {
    return Defaults(
      header: 'i18n',
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
