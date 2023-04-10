// Copyright (C) 2023 Adriano Souza (adriano.souza113@gmail.com)

library scatter_plot_chart;

import 'package:desktop/desktop.dart';

import 'package:desktop_charts/desktop_charts.dart' as charts;

import '../defaults.dart';

import 'animation_zoom.dart';
import 'bucketing_axis.dart';
import 'comparison_points.dart';
import 'shapes.dart';
import 'simple.dart';

List<(String, String?, WidgetBuilder)> createItems([bool animate = true]) {
  return _createItemsWithSeries(
    simpleScatterPlotSeries: SimpleScatterPlotChart.createSampleData(),
    shapesScatterPlotSeries: ShapesScatterPlotChart.createSampleData(),
    comparisonPointsScatterPlotSeries:
        ComparisonPointsScatterPlotChart.createSampleData(),
    scatterPlotAnimationZoomSeries:
        ScatterPlotAnimationZoomChart.createSampleData(),
    bucketingAxisScatterPlotSeries:
        BucketingAxisScatterPlotChart.createSampleData(),
    animate: animate,
  );
}

List<(String, String?, WidgetBuilder)> _createItemsWithSeries({
  required List<charts.Series<dynamic, int>> simpleScatterPlotSeries,
  required List<charts.Series<dynamic, int>> shapesScatterPlotSeries,
  required List<charts.Series<dynamic, int>> comparisonPointsScatterPlotSeries,
  required List<charts.Series<dynamic, int>> scatterPlotAnimationZoomSeries,
  required List<charts.Series<dynamic, int>> bucketingAxisScatterPlotSeries,
  bool animate = true,
}) {
  return [
    (
      'Simple Scatter Plot Chart',
      'With a single series',
      (context) => SimpleScatterPlotChart(
            simpleScatterPlotSeries,
            animate: animate,
          ),
    ),
    (
      'Shapes Scatter Plot Chart',
      'With custom shapes',
      (context) => ShapesScatterPlotChart(
            shapesScatterPlotSeries,
            animate: animate,
          ),
    ),
    (
      'Comparison Points Scatter Plot Chart',
      'Scatter plot chart with comparison points',
      (context) => ComparisonPointsScatterPlotChart(
            comparisonPointsScatterPlotSeries,
            animate: animate,
          ),
    ),
    (
      'Pan and Zoom Scatter Plot Chart',
      'Simple scatter plot chart pan and zoom behaviors enabled',
      (context) => ScatterPlotAnimationZoomChart(
            scatterPlotAnimationZoomSeries,
            animate: animate,
          ),
    ),
    (
      'Bucketing Axis Scatter Plot Chart',
      'Scatter plot with a measure axis that buckets values less '
          'than 10% into a single region below the draw area',
      (context) => BucketingAxisScatterPlotChart(
            bucketingAxisScatterPlotSeries,
            animate: animate,
          ),
    ),
  ];
}

class ScatterPlotPage extends StatefulWidget {
  const ScatterPlotPage({super.key});

  @override
  _ScatterPlotPageState createState() => _ScatterPlotPageState();
}

class _ScatterPlotPageState extends State<ScatterPlotPage> {
  bool _hasAnimation = true;

  late List<charts.Series<dynamic, int>> _simpleScatterPlotSeries;
  late List<charts.Series<dynamic, int>> _shapesScatterPlotSeries;
  late List<charts.Series<dynamic, int>> _comparisonPointsScatterPlotSeries;
  late List<charts.Series<dynamic, int>> _scatterPlotAnimationZoomSeries;
  late List<charts.Series<dynamic, int>> _bucketingAxisScatterPlotSeries;

  void _updateRandomData() {
    _simpleScatterPlotSeries = SimpleScatterPlotChart.createRandomData();
    _shapesScatterPlotSeries = ShapesScatterPlotChart.createRandomData();
    _comparisonPointsScatterPlotSeries =
        ComparisonPointsScatterPlotChart.createRandomData();
    _scatterPlotAnimationZoomSeries =
        ScatterPlotAnimationZoomChart.createRandomData();
    _bucketingAxisScatterPlotSeries =
        BucketingAxisScatterPlotChart.createRandomData();
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
        simpleScatterPlotSeries: _simpleScatterPlotSeries,
        shapesScatterPlotSeries: _shapesScatterPlotSeries,
        comparisonPointsScatterPlotSeries: _comparisonPointsScatterPlotSeries,
        scatterPlotAnimationZoomSeries: _scatterPlotAnimationZoomSeries,
        bucketingAxisScatterPlotSeries: _bucketingAxisScatterPlotSeries,
        animate: animate,
      );

  @override
  Widget build(BuildContext context) {
    return Defaults(
      header: 'Scatter Plot',
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
