// Copyright (C) 2023 Adriano Souza (adriano.souza113@gmail.com)

library line_chart;

import 'package:desktop/desktop.dart';

import 'package:desktop_charts/desktop_charts.dart' as charts;

import '../defaults.dart';
import 'animation_zoom.dart';
import 'area_and_line.dart';
import 'dash_pattern.dart';
import 'line_annotation.dart';
import 'points.dart';
import 'range_annotation.dart';
import 'range_annotation_margin.dart';
import 'segments.dart';
import 'simple.dart';
import 'simple_nulls.dart';
import 'stacked_area.dart';
import 'stacked_area_custom_color.dart';
import 'stacked_area_nulls.dart';

List<(String, String?, WidgetBuilder)> createItems([bool animate = true]) {
  return _createItemsWithSeries(
    simpleLineSeries: SimpleLineChart.createSampleData(),
    stackedAreaLineSeries: StackedAreaLineChart.createSampleData(),
    stackedAreaCustomColorLineSeries:
        StackedAreaCustomColorLineChart.createSampleData(),
    areaAndLineSeries: AreaAndLineChart.createSampleData(),
    pointsLineSeries: PointsLineChart.createSampleData(),
    simpleNullsLineSeries: SimpleNullsLineChart.createSampleData(),
    stackedAreaNullsLineSeries: StackedAreaNullsLineChart.createSampleData(),
    dashPatternLineSeries: DashPatternLineChart.createSampleData(),
    segmentsLineSeries: SegmentsLineChart.createSampleData(),
    lineLineAnnotationSeries: LineLineAnnotationChart.createSampleData(),
    lineRangeAnnotationSeries: LineRangeAnnotationChart.createSampleData(),
    lineRangeAnnotationMarginSeries:
        LineRangeAnnotationMarginChart.createSampleData(),
    lineAnimationZoomSeries: LineAnimationZoomChart.createSampleData(),
    animate: animate,
  );
}

List<(String, String?, WidgetBuilder)> _createItemsWithSeries({
  required List<charts.Series<dynamic, int>> simpleLineSeries,
  required List<charts.Series<dynamic, int>> stackedAreaLineSeries,
  required List<charts.Series<dynamic, int>> stackedAreaCustomColorLineSeries,
  required List<charts.Series<dynamic, int>> areaAndLineSeries,
  required List<charts.Series<dynamic, int>> pointsLineSeries,
  required List<charts.Series<dynamic, int>> simpleNullsLineSeries,
  required List<charts.Series<dynamic, int>> stackedAreaNullsLineSeries,
  required List<charts.Series<dynamic, int>> dashPatternLineSeries,
  required List<charts.Series<dynamic, int>> segmentsLineSeries,
  required List<charts.Series<dynamic, int>> lineLineAnnotationSeries,
  required List<charts.Series<dynamic, int>> lineRangeAnnotationSeries,
  required List<charts.Series<dynamic, int>> lineRangeAnnotationMarginSeries,
  required List<charts.Series<dynamic, int>> lineAnimationZoomSeries,
  bool animate = true,
}) {
  return [
    (
      'Simple Line Chart',
      'With a single series and default line point highlighter',
      (context) => SimpleLineChart(
            simpleLineSeries,
            animate: animate,
          ),
    ),
    (
      'Stacked Area Chart',
      'Stacked area chart with three series',
      (context) => StackedAreaLineChart(
            stackedAreaLineSeries,
            animate: animate,
          ),
    ),
    (
      'Stacked Area Custom Color Chart',
      'Stacked area chart with custom area skirt color',
      (context) => StackedAreaCustomColorLineChart(
            stackedAreaCustomColorLineSeries,
            animate: animate,
          ),
    ),
    (
      'Area and Line Combo Chart',
      'Combo chart with one line series and one area series',
      (context) => AreaAndLineChart(
            areaAndLineSeries,
            animate: animate,
          ),
    ),
    (
      'Points Line Chart',
      'Line chart with points on a single series',
      (context) => PointsLineChart(
            pointsLineSeries,
            animate: animate,
          ),
    ),
    (
      'Null Data Line Chart',
      'With a single series and null measure values',
      (context) => SimpleNullsLineChart(
            simpleNullsLineSeries,
            animate: animate,
          ),
    ),
    (
      'Stacked Area with Nulls Chart',
      'Stacked area chart with three series and null measure values',
      (context) => StackedAreaNullsLineChart(
            stackedAreaNullsLineSeries,
            animate: animate,
          ),
    ),
    (
      'Dash Pattern Line Chart',
      'Line chart with dash patterns',
      (context) => DashPatternLineChart(
            dashPatternLineSeries,
            animate: animate,
          ),
    ),
    (
      'Segments Line Chart',
      'Line chart with changes of style for each line',
      (context) => SegmentsLineChart(
            segmentsLineSeries,
            animate: animate,
          ),
    ),
    (
      'Line Annotation Line Chart',
      'Line chart with line annotations',
      (context) => LineLineAnnotationChart(
            lineLineAnnotationSeries,
            animate: animate,
          ),
    ),
    (
      'Range Annotation Line Chart',
      'Line chart with range annotations',
      (context) => LineRangeAnnotationChart(
            lineRangeAnnotationSeries,
            animate: animate,
          ),
    ),
    (
      'Range Annotation Margin Labels Line Chart',
      'Line chart with range annotations with labels in margins',
      (context) => LineRangeAnnotationMarginChart(
            lineRangeAnnotationMarginSeries,
            animate: animate,
          ),
    ),
    (
      'Pan and Zoom Line Chart',
      'Simple line chart pan and zoom behaviors enabled',
      (context) => LineAnimationZoomChart(
            lineAnimationZoomSeries,
            animate: animate,
          ),
    ),
  ];
}

class LinePage extends StatefulWidget {
  const LinePage({super.key});

  @override
  _LinePageState createState() => _LinePageState();
}

class _LinePageState extends State<LinePage> {
  bool _hasAnimation = true;

  late List<charts.Series<dynamic, int>> _simpleLineSeries;
  late List<charts.Series<dynamic, int>> _stackedAreaLineSeries;
  late List<charts.Series<dynamic, int>> _stackedAreaCustomColorLineSeries;
  late List<charts.Series<dynamic, int>> _areaAndLineSeries;
  late List<charts.Series<dynamic, int>> _pointsLineSeries;
  late List<charts.Series<dynamic, int>> _simpleNullsLineSeries;
  late List<charts.Series<dynamic, int>> _stackedAreaNullsLineSeries;
  late List<charts.Series<dynamic, int>> _dashPatternLineSeries;
  late List<charts.Series<dynamic, int>> _segmentsLineSeries;
  late List<charts.Series<dynamic, int>> _lineLineAnnotationSeries;
  late List<charts.Series<dynamic, int>> _lineRangeAnnotationSeries;
  late List<charts.Series<dynamic, int>> _lineRangeAnnotationMarginSeries;
  late List<charts.Series<dynamic, int>> _lineAnimationZoomSeries;

  void _updateRandomData() {
    _simpleLineSeries = SimpleLineChart.createRandomData();
    _stackedAreaLineSeries = StackedAreaLineChart.createRandomData();
    _stackedAreaCustomColorLineSeries =
        StackedAreaCustomColorLineChart.createRandomData();
    _areaAndLineSeries = AreaAndLineChart.createRandomData();
    _pointsLineSeries = PointsLineChart.createRandomData();
    _simpleNullsLineSeries = SimpleNullsLineChart.createRandomData();
    _stackedAreaNullsLineSeries = StackedAreaNullsLineChart.createRandomData();
    _dashPatternLineSeries = DashPatternLineChart.createRandomData();
    _segmentsLineSeries = SegmentsLineChart.createRandomData();
    _lineLineAnnotationSeries = LineLineAnnotationChart.createRandomData();
    _lineRangeAnnotationSeries = LineRangeAnnotationChart.createRandomData();
    _lineRangeAnnotationMarginSeries =
        LineRangeAnnotationMarginChart.createRandomData();
    _lineAnimationZoomSeries = LineAnimationZoomChart.createRandomData();
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
        simpleLineSeries: _simpleLineSeries,
        stackedAreaLineSeries: _stackedAreaLineSeries,
        stackedAreaCustomColorLineSeries: _stackedAreaCustomColorLineSeries,
        areaAndLineSeries: _areaAndLineSeries,
        pointsLineSeries: _pointsLineSeries,
        simpleNullsLineSeries: _simpleNullsLineSeries,
        stackedAreaNullsLineSeries: _stackedAreaNullsLineSeries,
        dashPatternLineSeries: _dashPatternLineSeries,
        segmentsLineSeries: _segmentsLineSeries,
        lineLineAnnotationSeries: _lineLineAnnotationSeries,
        lineRangeAnnotationSeries: _lineRangeAnnotationSeries,
        lineRangeAnnotationMarginSeries: _lineRangeAnnotationMarginSeries,
        lineAnimationZoomSeries: _lineAnimationZoomSeries,
        animate: animate,
      );

  @override
  Widget build(BuildContext context) {
    return Defaults(
      header: 'Line',
      items: _createItems(_hasAnimation)
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
