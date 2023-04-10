// Copyright (C) 2023 Adriano Souza (adriano.souza113@gmail.com)

library bar_chart;

import 'package:desktop/desktop.dart';

import 'package:desktop_charts/desktop_charts.dart' as charts;

import '../defaults.dart';
import 'grouped.dart';
import 'grouped_fill_color.dart';
import 'grouped_single_target_line.dart';
import 'grouped_stacked.dart';
import 'grouped_stacked_weight_pattern.dart';
import 'grouped_target_line.dart';
import 'horizontal.dart';
import 'horizontal_bar_label.dart';
import 'horizontal_bar_label_custom.dart';
import 'horizontal_pattern_forward_hatch.dart';
import 'pattern_forward_hatch.dart';
import 'simple.dart';
import 'spark_bar.dart';
import 'stacked.dart';
import 'stacked_fill_color.dart';
import 'stacked_horizontal.dart';
import 'stacked_target_line.dart';
import 'vertical_bar_label.dart';

List<(String, String?, WidgetBuilder)> createItems([bool animate = true]) {
  return _createItemsWithSeries(
    simpleBarSeries: SimpleBarChart.createSampleData(),
    stackedBarSeries: StackedBarChart.createSampleData(),
    groupedBarSeries: GroupedBarChart.createSampleData(),
    groupedStackedBarSeries: GroupedStackedBarChart.createSampleData(),
    groupedBarTargetLineSeries: GroupedBarTargetLineChart.createSampleData(),
    groupedBarSingleTargetLineSeries:
        GroupedBarSingleTargetLineChart.createSampleData(),
    stackedBarTargetLineSeries: StackedBarTargetLineChart.createSampleData(),
    horizontalBarSeries: HorizontalBarChart.createSampleData(),
    stackedHorizontalBarSeries: StackedHorizontalBarChart.createSampleData(),
    horizontalBarLabelSeries: HorizontalBarLabelChart.createSampleData(),
    horizontalBarLabelCustomSeries:
        HorizontalBarLabelCustomChart.createSampleData(),
    verticalBarLabelSeries: VerticalBarLabelChart.createSampleData(),
    sparkBarSeries: SparkBar.createSampleData(),
    groupedFillColorBarSeries: GroupedFillColorBarChart.createSampleData(),
    stackedFillColorBarSeries: StackedFillColorBarChart.createSampleData(),
    patternForwardHatchBarSeries:
        PatternForwardHatchBarChart.createSampleData(),
    horizontalPatternForwardHatchBarSeries:
        HorizontalPatternForwardHatchBarChart.createSampleData(),
    groupedStackedWeightPatternBarSeries:
        GroupedStackedWeightPatternBarChart.createSampleData(),
    animate: animate,
  );
}

List<(String, String?, WidgetBuilder)> _createItemsWithSeries({
  required List<charts.Series<dynamic, String>> simpleBarSeries,
  required List<charts.Series<dynamic, String>> stackedBarSeries,
  required List<charts.Series<dynamic, String>> groupedBarSeries,
  required List<charts.Series<dynamic, String>> groupedStackedBarSeries,
  required List<charts.Series<dynamic, String>> groupedBarTargetLineSeries,
  required List<charts.Series<dynamic, String>>
      groupedBarSingleTargetLineSeries,
  required List<charts.Series<dynamic, String>> stackedBarTargetLineSeries,
  required List<charts.Series<dynamic, String>> horizontalBarSeries,
  required List<charts.Series<dynamic, String>> stackedHorizontalBarSeries,
  required List<charts.Series<dynamic, String>> horizontalBarLabelSeries,
  required List<charts.Series<dynamic, String>> horizontalBarLabelCustomSeries,
  required List<charts.Series<dynamic, String>> verticalBarLabelSeries,
  required List<charts.Series<dynamic, String>> sparkBarSeries,
  required List<charts.Series<dynamic, String>> groupedFillColorBarSeries,
  required List<charts.Series<dynamic, String>> stackedFillColorBarSeries,
  required List<charts.Series<dynamic, String>> patternForwardHatchBarSeries,
  required List<charts.Series<dynamic, String>>
      horizontalPatternForwardHatchBarSeries,
  required List<charts.Series<dynamic, String>>
      groupedStackedWeightPatternBarSeries,
  bool animate = true,
}) {
  return [
    (
      'Simple Bar Chart',
      'Simple bar chart with a single series',
      (context) => SimpleBarChart(
            simpleBarSeries,
            animate: animate,
          ),
    ),
    (
      'Stacked Bar Chart',
      'Stacked bar chart with multiple series',
      (context) => StackedBarChart(
            stackedBarSeries,
            animate: animate,
          ),
    ),
    (
      'Grouped Bar Chart',
      'Grouped bar chart with multiple series',
      (context) => GroupedBarChart(
            groupedBarSeries,
            animate: animate,
          ),
    ),
    (
      'Grouped Stacked Bar Chart',
      'Grouped and stacked bar chart with multiple series',
      (context) => GroupedStackedBarChart(
            groupedStackedBarSeries,
            animate: animate,
          ),
    ),
    (
      'Grouped Bar Target Line Chart',
      'Grouped bar target line chart with multiple series',
      (context) => GroupedBarTargetLineChart(
            groupedBarTargetLineSeries,
            animate: animate,
          ),
    ),
    (
      'Grouped Bar Single Target Line Chart',
      'Grouped bar target line chart with multiple series and a single target',
      (context) => GroupedBarSingleTargetLineChart(
            groupedBarSingleTargetLineSeries,
            animate: animate,
          ),
    ),
    (
      'Stacked Bar Target Line Chart',
      'Stacked bar target line chart with multiple series',
      (context) => StackedBarTargetLineChart(
            stackedBarTargetLineSeries,
            animate: animate,
          ),
    ),
    (
      'Horizontal Bar Chart',
      'Horizontal bar chart with a single series',
      (context) => HorizontalBarChart(
            horizontalBarSeries,
            animate: animate,
          ),
    ),
    (
      'Stacked Horizontal Bar Chart',
      'Stacked horizontal bar chart with multiple series',
      (context) => StackedHorizontalBarChart(
            stackedHorizontalBarSeries,
            animate: animate,
          ),
    ),
    (
      'Horizontal Bar Chart with Bar Labels',
      'Horizontal bar chart with a single series and bar labels',
      (context) => HorizontalBarLabelChart(
            horizontalBarLabelSeries,
            animate: animate,
          ),
    ),
    (
      'Horizontal Bar Chart with Custom Bar Labels',
      'Bar labels with customized styling',
      (context) => HorizontalBarLabelCustomChart(
            horizontalBarLabelCustomSeries,
            animate: animate,
          ),
    ),
    (
      'Vertical Bar Chart with Bar Labels',
      'Vertical bar chart with a single series and bar labels',
      (context) => VerticalBarLabelChart(
            verticalBarLabelSeries,
            animate: animate,
          ),
    ),
    (
      'Spark Bar Chart',
      null,
      (context) => SparkBar(
            sparkBarSeries,
            animate: animate,
          ),
    ),
    (
      'Grouped Fill Color Bar Chart',
      null,
      (context) => GroupedFillColorBarChart(
            groupedFillColorBarSeries,
            animate: animate,
          ),
    ),
    (
      'Stacked Fill Color Bar Chart',
      null,
      (context) => StackedFillColorBarChart(
            stackedFillColorBarSeries,
            animate: animate,
          ),
    ),
    (
      'Pattern Forward Hatch Bar Chart',
      null,
      (context) => PatternForwardHatchBarChart(
            patternForwardHatchBarSeries,
            animate: animate,
          ),
    ),
    (
      'Horizontal Pattern Forward Hatch Bar Chart',
      null,
      (context) => HorizontalPatternForwardHatchBarChart(
            horizontalPatternForwardHatchBarSeries,
            animate: animate,
          ),
    ),
    (
      'Weight Pattern Bar Chart',
      'Grouped and stacked bar chart with a weight pattern',
      (context) => GroupedStackedWeightPatternBarChart(
            groupedStackedWeightPatternBarSeries,
            animate: animate,
          ),
    ),
  ];
}

class BarPage extends StatefulWidget {
  const BarPage({super.key});

  @override
  _BarPageState createState() => _BarPageState();
}

class _BarPageState extends State<BarPage> {
  bool _hasAnimation = true;

  void _updateRandomData() {
    _simpleBarSeries = SimpleBarChart.createRandomData();
    _stackedBarSeries = StackedBarChart.createRandomData();
    _groupedBarSeries = GroupedBarChart.createRandomData();
    _groupedStackedBarSeries = GroupedStackedBarChart.createRandomData();
    _groupedBarTargetLineSeries = GroupedBarTargetLineChart.createRandomData();
    _groupedBarSingleTargetLineSeries =
        GroupedBarSingleTargetLineChart.createRandomData();
    _stackedBarTargetLineSeries = StackedBarTargetLineChart.createRandomData();
    _horizontalBarSeries = HorizontalBarChart.createRandomData();
    _stackedHorizontalBarSeries = StackedHorizontalBarChart.createRandomData();
    _horizontalBarLabelSeries = HorizontalBarLabelChart.createRandomData();
    _horizontalBarLabelCustomSeries =
        HorizontalBarLabelCustomChart.createRandomData();
    _verticalBarLabelSeries = VerticalBarLabelChart.createRandomData();
    _sparkBarSeries = SparkBar.createRandomData();
    _groupedFillColorBarSeries = GroupedFillColorBarChart.createRandomData();
    _stackedFillColorBarSeries = StackedFillColorBarChart.createRandomData();
    _patternForwardHatchBarSeries =
        PatternForwardHatchBarChart.createRandomData();
    _horizontalPatternForwardHatchBarSeries =
        HorizontalPatternForwardHatchBarChart.createRandomData();
    _groupedStackedWeightPatternBarSeries =
        GroupedStackedWeightPatternBarChart.createRandomData();
  }

  void _refresh() {
    setState(() => _updateRandomData());
  }

  @override
  void initState() {
    super.initState();

    _updateRandomData();
  }

  late List<charts.Series<dynamic, String>> _simpleBarSeries;
  late List<charts.Series<dynamic, String>> _stackedBarSeries;
  late List<charts.Series<dynamic, String>> _groupedBarSeries;
  late List<charts.Series<dynamic, String>> _groupedStackedBarSeries;
  late List<charts.Series<dynamic, String>> _groupedBarTargetLineSeries;
  late List<charts.Series<dynamic, String>> _groupedBarSingleTargetLineSeries;
  late List<charts.Series<dynamic, String>> _stackedBarTargetLineSeries;
  late List<charts.Series<dynamic, String>> _horizontalBarSeries;
  late List<charts.Series<dynamic, String>> _stackedHorizontalBarSeries;
  late List<charts.Series<dynamic, String>> _horizontalBarLabelSeries;
  late List<charts.Series<dynamic, String>> _horizontalBarLabelCustomSeries;
  late List<charts.Series<dynamic, String>> _verticalBarLabelSeries;
  late List<charts.Series<dynamic, String>> _sparkBarSeries;
  late List<charts.Series<dynamic, String>> _groupedFillColorBarSeries;
  late List<charts.Series<dynamic, String>> _stackedFillColorBarSeries;
  late List<charts.Series<dynamic, String>> _patternForwardHatchBarSeries;
  late List<charts.Series<dynamic, String>>
      _horizontalPatternForwardHatchBarSeries;
  late List<charts.Series<dynamic, String>>
      _groupedStackedWeightPatternBarSeries;

  @override
  Widget build(BuildContext context) {
    return Defaults(
      header: 'Bar',
      items: _createItemsWithSeries(
        simpleBarSeries: _simpleBarSeries,
        stackedBarSeries: _stackedBarSeries,
        groupedBarSeries: _groupedBarSeries,
        groupedStackedBarSeries: _groupedStackedBarSeries,
        groupedBarTargetLineSeries: _groupedBarTargetLineSeries,
        groupedBarSingleTargetLineSeries: _groupedBarSingleTargetLineSeries,
        stackedBarTargetLineSeries: _stackedBarTargetLineSeries,
        horizontalBarSeries: _horizontalBarSeries,
        stackedHorizontalBarSeries: _stackedHorizontalBarSeries,
        horizontalBarLabelSeries: _horizontalBarLabelSeries,
        horizontalBarLabelCustomSeries: _horizontalBarLabelCustomSeries,
        verticalBarLabelSeries: _verticalBarLabelSeries,
        sparkBarSeries: _sparkBarSeries,
        groupedFillColorBarSeries: _groupedFillColorBarSeries,
        stackedFillColorBarSeries: _stackedFillColorBarSeries,
        patternForwardHatchBarSeries: _patternForwardHatchBarSeries,
        horizontalPatternForwardHatchBarSeries:
            _horizontalPatternForwardHatchBarSeries,
        groupedStackedWeightPatternBarSeries:
            _groupedStackedWeightPatternBarSeries,
        animate: _hasAnimation,
      )
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
