// Copyright (C) 2023 Adriano Souza (adriano.souza113@gmail.com)

library axes;

import 'package:desktop/desktop.dart';

import 'package:desktop_charts/desktop_charts.dart' as charts;

import '../defaults.dart';
import 'bar_secondary_axis.dart';
import 'bar_secondary_axis_only.dart';
import 'custom_axis_tick_formatters.dart';
import 'custom_font_size_and_color.dart';
import 'custom_measure_tick_count.dart';
import 'gridline_dash_pattern.dart';
import 'hidden_ticks_and_labels_axis.dart';
import 'horizontal_bar_secondary_axis.dart';
import 'integer_only_measure_axis.dart';
import 'line_disjoint_axis.dart';
import 'measure_axis_label_alignment.dart';
import 'nonzero_bound_measure_axis.dart';
import 'numeric_initial_viewport.dart';
import 'ordinal_initial_viewport.dart';
import 'short_tick_length_axis.dart';
import 'statically_provided_ticks.dart';

List<(String, String?, WidgetBuilder)> createItems([bool animate = true]) {
  return _createItemsWithSeries(
    barChartWithSecondaryAxisSeries:
        BarChartWithSecondaryAxis.createSampleData(),
    barChartWithSecondaryAxisOnlySeries:
        BarChartWithSecondaryAxisOnly.createSampleData(),
    horizontalBarChartWithSecondaryAxisSeries:
        HorizontalBarChartWithSecondaryAxis.createSampleData(),
    shortTickLengthAxisSeries: ShortTickLengthAxis.createSampleData(),
    customFontSizeAndColorSeries: CustomFontSizeAndColor.createSampleData(),
    measureAxisLabelAlignmentSeries:
        MeasureAxisLabelAlignment.createSampleData(),
    hiddenTicksAndLabelsAxisSeries: HiddenTicksAndLabelsAxis.createSampleData(),
    staticallyProvidedTicksSeries: StaticallyProvidedTicks.createSampleData(),
    customAxisTickFormattersSeries: CustomAxisTickFormatters.createSampleData(),
    customMeasureTickCountSeries: CustomMeasureTickCount.createSampleData(),
    integerOnlyMeasureAxisSeries: IntegerOnlyMeasureAxis.createSampleData(),
    nonzeroBoundMeasureAxisSeries: NonzeroBoundMeasureAxis.createSampleData(),
    ordinalInitialViewportSeries: OrdinalInitialViewport.createSampleData(),
    numericInitialViewportSeries: NumericInitialViewport.createSampleData(),
    gridlineDashPatternSeries: GridlineDashPattern.createSampleData(),
    disjointMeasureAxisLineChartSeries:
        DisjointMeasureAxisLineChart.createSampleData(),
    animate: animate,
  );
}

List<(String, String?, WidgetBuilder)> _createItemsWithSeries({
  required List<charts.Series<dynamic, String>> barChartWithSecondaryAxisSeries,
  required List<charts.Series<dynamic, String>>
      barChartWithSecondaryAxisOnlySeries,
  required List<charts.Series<dynamic, String>>
      horizontalBarChartWithSecondaryAxisSeries,
  required List<charts.Series<dynamic, String>> shortTickLengthAxisSeries,
  required List<charts.Series<dynamic, String>> customFontSizeAndColorSeries,
  required List<charts.Series<dynamic, String>> measureAxisLabelAlignmentSeries,
  required List<charts.Series<dynamic, String>> hiddenTicksAndLabelsAxisSeries,
  required List<charts.Series<dynamic, String>> staticallyProvidedTicksSeries,
  required List<charts.Series<dynamic, DateTime>>
      customAxisTickFormattersSeries,
  required List<charts.Series<dynamic, DateTime>> customMeasureTickCountSeries,
  required List<charts.Series<dynamic, DateTime>> integerOnlyMeasureAxisSeries,
  required List<charts.Series<dynamic, DateTime>> nonzeroBoundMeasureAxisSeries,
  required List<charts.Series<dynamic, String>> ordinalInitialViewportSeries,
  required List<charts.Series<dynamic, num>> numericInitialViewportSeries,
  required List<charts.Series<dynamic, DateTime>> gridlineDashPatternSeries,
  required List<charts.Series<dynamic, num>> disjointMeasureAxisLineChartSeries,
  bool animate = true,
}) {
  return [
    (
      'Bar chart with Secondary Measure Axis',
      'Bar chart with a series using a secondary measure axis',
      (context) => BarChartWithSecondaryAxis(
            barChartWithSecondaryAxisSeries,
            animate: animate,
          ),
    ),
    (
      'Bar chart with Secondary Measure Axis only',
      'Bar chart with both series using secondary measure axis',
      (context) => BarChartWithSecondaryAxisOnly(
            barChartWithSecondaryAxisOnlySeries,
            animate: animate,
          ),
    ),
    (
      'Horizontal bar chart with Secondary Measure Axis',
      'Horizontal Bar chart with a series using secondary measure axis',
      (context) => HorizontalBarChartWithSecondaryAxis(
            horizontalBarChartWithSecondaryAxisSeries,
            animate: animate,
          ),
    ),
    (
      'Short Ticks Axis',
      'Bar chart with the primary measure axis having short ticks',
      (context) => ShortTickLengthAxis(
            shortTickLengthAxisSeries,
            animate: animate,
          ),
    ),
    (
      'Custom Axis Fonts',
      'Bar chart with custom axis font size and color',
      (context) => CustomFontSizeAndColor(
            customFontSizeAndColorSeries,
            animate: animate,
          ),
    ),
    (
      'Label Alignment Axis',
      'Bar chart with custom measure axis label alignments',
      (context) => MeasureAxisLabelAlignment(
            measureAxisLabelAlignmentSeries,
            animate: animate,
          ),
    ),
    (
      'No Axis',
      'Bar chart with only the axis line drawn',
      (context) => HiddenTicksAndLabelsAxis(
            hiddenTicksAndLabelsAxisSeries,
            animate: animate,
          ),
    ),
    (
      'Statically Provided Ticks',
      'Bar chart with statically provided ticks',
      (context) => StaticallyProvidedTicks(
            staticallyProvidedTicksSeries,
            animate: animate,
          ),
    ),
    (
      'Custom Formatter',
      'Time series with custom domain and measure tick formatters',
      (context) => CustomAxisTickFormatters(
            customAxisTickFormattersSeries,
            animate: animate,
          ),
    ),
    (
      'Custom Tick Count',
      'Time series with custom measure axis tick count',
      (context) => CustomMeasureTickCount(
            customMeasureTickCountSeries,
            animate: animate,
          ),
    ),
    (
      'Integer Measure Ticks',
      'Time series with only whole number measure axis ticks',
      (context) => IntegerOnlyMeasureAxis(
            integerOnlyMeasureAxisSeries,
            animate: animate,
          ),
    ),
    (
      'Non-zero bound Axis',
      'Time series with measure axis that does not include zero',
      (context) => NonzeroBoundMeasureAxis(
            nonzeroBoundMeasureAxisSeries,
            animate: animate,
          ),
    ),
    (
      'Ordinal axis with initial viewport',
      'Single series with initial viewport',
      (context) => OrdinalInitialViewport(
            ordinalInitialViewportSeries,
            animate: animate,
          ),
    ),
    (
      'Numeric axis with initial viewport',
      'Initial viewport is set to a subset of the data',
      (context) => NumericInitialViewport(
            numericInitialViewportSeries,
            animate: animate,
          ),
    ),
    (
      'Gridline dash pattern',
      'Time series with measure grid lines that have a dash pattern',
      (context) => GridlineDashPattern(
            gridlineDashPatternSeries,
            animate: animate,
          ),
    ),
    (
      'Disjoint Measure Axes',
      'Line chart with disjoint measure axes',
      (context) => DisjointMeasureAxisLineChart(
            disjointMeasureAxisLineChartSeries,
            animate: animate,
          ),
    ),
  ];
}

class AxesPage extends StatefulWidget {
  const AxesPage({super.key});

  @override
  _AxesPageState createState() => _AxesPageState();
}

class _AxesPageState extends State<AxesPage> {
  bool _hasAnimation = true;

  late List<charts.Series<dynamic, String>> _barChartWithSecondaryAxisSeries;
  late List<charts.Series<dynamic, String>>
      _barChartWithSecondaryAxisOnlySeries;
  late List<charts.Series<dynamic, String>>
      _horizontalBarChartWithSecondaryAxisSeries;
  late List<charts.Series<dynamic, String>> _shortTickLengthAxisSeries;
  late List<charts.Series<dynamic, String>> _customFontSizeAndColorSeries;
  late List<charts.Series<dynamic, String>> _measureAxisLabelAlignmentSeries;
  late List<charts.Series<dynamic, String>> _hiddenTicksAndLabelsAxisSeries;
  late List<charts.Series<dynamic, String>> _staticallyProvidedTicksSeries;
  late List<charts.Series<dynamic, DateTime>> _customAxisTickFormattersSeries;
  late List<charts.Series<dynamic, DateTime>> _customMeasureTickCountSeries;
  late List<charts.Series<dynamic, DateTime>> _integerOnlyMeasureAxisSeries;
  late List<charts.Series<dynamic, DateTime>> _nonzeroBoundMeasureAxisSeries;
  late List<charts.Series<dynamic, String>> _ordinalInitialViewportSeries;
  late List<charts.Series<dynamic, num>> _numericInitialViewportSeries;
  late List<charts.Series<dynamic, DateTime>> _gridlineDashPatternSeries;
  late List<charts.Series<dynamic, num>> _disjointMeasureAxisLineChartSeries;

  void _updateRandomData() {
    _barChartWithSecondaryAxisSeries =
        BarChartWithSecondaryAxis.createRandomData();
    _barChartWithSecondaryAxisOnlySeries =
        BarChartWithSecondaryAxisOnly.createRandomData();
    _horizontalBarChartWithSecondaryAxisSeries =
        HorizontalBarChartWithSecondaryAxis.createRandomData();
    _shortTickLengthAxisSeries = ShortTickLengthAxis.createRandomData();
    _customFontSizeAndColorSeries = CustomFontSizeAndColor.createRandomData();
    _measureAxisLabelAlignmentSeries =
        MeasureAxisLabelAlignment.createRandomData();
    _hiddenTicksAndLabelsAxisSeries =
        HiddenTicksAndLabelsAxis.createRandomData();
    _staticallyProvidedTicksSeries = StaticallyProvidedTicks.createRandomData();
    _customAxisTickFormattersSeries =
        CustomAxisTickFormatters.createRandomData();
    _customMeasureTickCountSeries = CustomMeasureTickCount.createRandomData();
    _integerOnlyMeasureAxisSeries = IntegerOnlyMeasureAxis.createRandomData();
    _nonzeroBoundMeasureAxisSeries = NonzeroBoundMeasureAxis.createRandomData();
    _ordinalInitialViewportSeries = OrdinalInitialViewport.createRandomData();
    _numericInitialViewportSeries = NumericInitialViewport.createRandomData();
    _gridlineDashPatternSeries = GridlineDashPattern.createRandomData();
    _disjointMeasureAxisLineChartSeries =
        DisjointMeasureAxisLineChart.createRandomData();
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
        barChartWithSecondaryAxisSeries: _barChartWithSecondaryAxisSeries,
        barChartWithSecondaryAxisOnlySeries:
            _barChartWithSecondaryAxisOnlySeries,
        horizontalBarChartWithSecondaryAxisSeries:
            _horizontalBarChartWithSecondaryAxisSeries,
        shortTickLengthAxisSeries: _shortTickLengthAxisSeries,
        customFontSizeAndColorSeries: _customFontSizeAndColorSeries,
        measureAxisLabelAlignmentSeries: _measureAxisLabelAlignmentSeries,
        hiddenTicksAndLabelsAxisSeries: _hiddenTicksAndLabelsAxisSeries,
        staticallyProvidedTicksSeries: _staticallyProvidedTicksSeries,
        customAxisTickFormattersSeries: _customAxisTickFormattersSeries,
        customMeasureTickCountSeries: _customMeasureTickCountSeries,
        integerOnlyMeasureAxisSeries: _integerOnlyMeasureAxisSeries,
        nonzeroBoundMeasureAxisSeries: _nonzeroBoundMeasureAxisSeries,
        ordinalInitialViewportSeries: _ordinalInitialViewportSeries,
        numericInitialViewportSeries: _numericInitialViewportSeries,
        gridlineDashPatternSeries: _gridlineDashPatternSeries,
        disjointMeasureAxisLineChartSeries: _disjointMeasureAxisLineChartSeries,
        animate: animate,
      );

  @override
  Widget build(BuildContext context) {
    return Defaults(
      header: 'Axes',
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
