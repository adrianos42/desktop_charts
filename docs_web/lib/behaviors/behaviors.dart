// Copyright (C) 2023 Adriano Souza (adriano.souza113@gmail.com)

library behaviors;

import 'package:desktop/desktop.dart';

import '../defaults.dart';

import 'chart_title.dart';
import 'initial_hint_animation.dart';
import 'initial_selection.dart';
import 'percent_of_domain.dart';
import 'percent_of_domain_by_category.dart';
import 'percent_of_series.dart';
import 'selection_bar_highlight.dart';
import 'selection_line_highlight.dart';
import 'selection_line_highlight_custom_shape.dart';
import 'selection_callback_example.dart';
import 'selection_scatter_plot_highlight.dart';
import 'selection_user_managed.dart';
import 'slider.dart';
import 'sliding_viewport_on_selection.dart';

class BehaviorsPage extends StatefulWidget {
  const BehaviorsPage({super.key});

  @override
  _BehaviorsPageState createState() => _BehaviorsPageState();
}

class _BehaviorsPageState extends State<BehaviorsPage> {
  void _refresh() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // return Defaults(header: 'Behaviors', items: [
    //   ItemTitle(
    //     title: 'Initial hint animation ',
    //     subtitle: 'Animate into final viewport',
    //     body: (context) => InitialHintAnimation.withRandomData(),
    //   ),
    // ]);

    return Defaults(
      header: 'Behaviors',
      items: [
        ItemTitle(
          title: 'Selection Bar Highlight',
          subtitle: 'Simple bar chart with tap activation',
          body: (context) => SelectionBarHighlight.withRandomData(),
        ),
        ItemTitle(
          title: 'Selection Line Highlight',
          subtitle: 'Line chart with tap and drag activation',
          body: (context) => SelectionLineHighlight.withRandomData(),
        ),
        ItemTitle(
          title: 'Selection Line Highlight Custom Shape',
          subtitle:
              'Line chart with tap and drag activation and a custom shape',
          body: (context) => SelectionLineHighlightCustomShape.withRandomData(),
        ),
        ItemTitle(
          title: 'Selection Scatter Plot Highlight',
          subtitle: 'Scatter plot chart with tap and drag activation',
          body: (context) => SelectionScatterPlotHighlight.withRandomData(),
        ),
        ItemTitle(
          title: 'Selection Callback Example',
          subtitle: 'Timeseries that updates external components on selection',
          body: (context) => SelectionCallbackExample.withRandomData(),
        ),
        ItemTitle(
          title: 'User managed selection',
          subtitle:
              'Example where selection can be set and cleared programmatically',
          body: (context) => SelectionUserManaged.withRandomData(),
        ),
        ItemTitle(
          title: 'Bar Chart with initial selection',
          subtitle: 'Single series with initial selection',
          body: (context) => InitialSelection.withRandomData(),
        ),
        ItemTitle(
          title: 'Line Chart with Chart Titles',
          subtitle: 'Line chart with four chart titles',
          body: (context) => ChartTitleLine.withRandomData(),
        ),
        ItemTitle(
          title: 'Line Chart with Slider',
          subtitle: 'Line chart with a slider behavior',
          body: (context) => SliderLine.withRandomData(),
        ),
        ItemTitle(
          title: 'Percent of Domain',
          subtitle:
              'Stacked bar chart with measures calculated as percent of ' +
                  'domain',
          body: (context) => PercentOfDomainBarChart.withRandomData(),
        ),
        ItemTitle(
          title: 'Percent of Domain by Category',
          subtitle: 'Grouped stacked bar chart with measures calculated as '
              'percent of domain and series category',
          body: (context) => PercentOfDomainByCategoryBarChart.withRandomData(),
        ),
        ItemTitle(
          title: 'Percent of Series',
          subtitle:
              'Grouped bar chart with measures calculated as percent of ' +
                  'series',
          body: (context) => PercentOfSeriesBarChart.withRandomData(),
        ),
        ItemTitle(
          title: 'Sliding viewport on domain selection',
          subtitle: 'Center viewport on selected domain',
          body: (context) => SlidingViewportOnSelection.withRandomData(),
        ),
        ItemTitle(
          title: 'Initial hint animation ',
          subtitle: 'Animate into final viewport',
          body: (context) => InitialHintAnimation.withRandomData(),
        ),
      ],
    );
  }
}
