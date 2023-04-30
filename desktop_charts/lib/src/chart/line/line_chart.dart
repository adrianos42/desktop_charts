// Copyright (C) 2023 Adriano Souza (adriano.souza113@gmail.com)

import '../behavior/behavior.dart' show ChartBehavior, LinePointHighlighter;
import '../cartesian/cartesian_chart.dart'
    show NumericCartesianChart, NumericCartesianChartState;
import 'line_renderer_config.dart' show LineRendererConfig;

class LineChart extends NumericCartesianChart {
  const LineChart(
    super.seriesList, {
    LineRendererConfig<num>? defaultRenderer,
    super.key,
    super.userManagedState,
    super.selectionModels,
    super.behaviors,
    super.customSeriesRenderers,
    super.domainAxis,
    super.primaryMeasureAxis,
    super.secondaryMeasureAxis,
    super.disjointMeasureAxes,
    super.animate,
    super.animationDuration,
    super.isVertical,
    super.defaultInteractions,
    super.rtlSpec,
    super.flipVerticalAxis,
  }) : super(defaultRenderer: defaultRenderer ?? const LineRendererConfig());

  @override
  LineChartState createState() => LineChartState();
}

class LineChartState extends NumericCartesianChartState {
  @override
  void addDefaultInteractions(List<ChartBehavior> behaviors) {
    super.addDefaultInteractions(behaviors);

    behaviors.add(const LinePointHighlighter<num>());
  }
}
