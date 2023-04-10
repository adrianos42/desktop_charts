// Copyright (C) 2023 Adriano Souza (adriano.souza113@gmail.com)

library time_series_chart;

import 'package:desktop/desktop.dart';

import '../defaults.dart';

import 'confidence_interval.dart';
import 'end_points_axis.dart';
import 'line_annotation.dart';
import 'range_annotation.dart';
import 'range_annotation_margin.dart';
import 'simple.dart';
import 'symbol_annotation.dart';
import 'with_bar_renderer.dart';

List<(String, String?, WidgetBuilder)> createItems([bool animate = true]) {
  return [
    (
      'Time Series Chart',
      'Simple single time series chart',
      (context) => SimpleTimeSeriesChart.withRandomData(animate),
    ),
    (
      'End Points Axis Time Series Chart',
      'Time series chart with an end points axis',
      (context) => EndPointsAxisTimeSeriesChart.withRandomData(animate),
    ),
    (
      'Line Annotation on Time Series Chart',
      'Time series chart with future line annotation',
      (context) => TimeSeriesLineAnnotationChart.withRandomData(animate),
    ),
    (
      'Range Annotation on Time Series Chart',
      'Time series chart with future range annotation',
      (context) => TimeSeriesRangeAnnotationChart.withRandomData(animate),
    ),
    (
      'Range Annotation Margin Labels on Time Series Chart',
      'Time series chart with range annotations with labels in margins',
      (context) => TimeSeriesRangeAnnotationMarginChart.withRandomData(animate),
    ),
    (
      'Symbol Annotation Time Series Chart',
      'Time series chart with annotation data below the draw area',
      (context) => TimeSeriesSymbolAnnotationChart.withRandomData(animate),
    ),
    (
      'Time Series Chart with Bars',
      'Time series chart using the bar renderer',
      (context) => TimeSeriesBar.withRandomData(animate),
    ),
    (
      'Time Series Chart with Confidence Interval',
      'Draws area around the confidence interval',
      (context) => TimeSeriesConfidenceInterval.withRandomData(animate),
    ),
  ];
}

class TimeSeriesPage extends StatefulWidget {
  const TimeSeriesPage({super.key});

  @override
  _TimeSeriesPageState createState() => _TimeSeriesPageState();
}

class _TimeSeriesPageState extends State<TimeSeriesPage> {
  bool _hasAnimation = true;

  void _refresh() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Defaults(
      header: 'Time Series',
      items: createItems(_hasAnimation)
          .map(
            (e) => ItemTitle(
              title: e.$1,
              subtitle: e.$2,
              body: e.$3,
              options: [
                Button.icon(
                  Icons.animation,
                  onPressed: () =>
                      setState(() => _hasAnimation = !_hasAnimation),
                  active: _hasAnimation,
                ),
                Button.icon(Icons.refresh, onPressed: _refresh),
              ],
            ),
          )
          .toList(),
    );
  }
}
