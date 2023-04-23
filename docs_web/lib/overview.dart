// Copyright (C) 2023 Adriano Souza (adriano.souza113@gmail.com)

import 'package:desktop/desktop.dart';
import 'package:flutter/foundation.dart';

import '../defaults.dart';
import 'axes/axes.dart' as axes;
import 'bar_chart/bar_chart.dart' as bar_chart;
import 'combo_chart/combo.dart' as combo_chart;
import 'i18n/i18n.dart' as i18n;
import 'legends/legends.dart' as legends;
import 'line_chart/line_chart.dart' as line_chart;
import 'pie_chart/pie_chart.dart' as pie_chart;
import 'scatter_plot_chart/scatter_plot_chart.dart' as scatter_plot_chart;
import 'time_series_chart/time_series_chart.dart' as time_series_chart;
import 'behaviors/behaviors.dart' as behaviors;

class OverviewPage extends StatefulWidget {
  const OverviewPage({super.key});

  @override
  _OverviewPageState createState() => _OverviewPageState();
}

class HeaderDelegate extends SliverPersistentHeaderDelegate {
  const HeaderDelegate(this.title, this.topPadding);

  final String title;
  final double topPadding;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).colorScheme.background[0],
      padding: EdgeInsets.only(left: 12.0, right: 12.0, top: topPadding),
      child: Defaults.createSubheader(context, title),
    );
  }

  @override
  double get maxExtent => 60.0 + topPadding;

  @override
  double get minExtent => 60.0 + topPadding;

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}

class _OverviewPageState extends State<OverviewPage> {
  Widget _creadeHeader(String title, [double topPadding = 24.0]) {
    return SliverPersistentHeader(
      pinned: false,
      floating: false,
      delegate: HeaderDelegate(title, topPadding),
    );
  }

  Widget _createItems(
    List<(String, String?, WidgetBuilder)> Function(bool animate)
        createChartItems,
  ) {
    final themeData = Theme.of(context);
    final colorSheme = themeData.colorScheme;
    final textTheme = themeData.textTheme;

    final width = MediaQuery.sizeOf(context).width;

    return SliverGrid.count(
      crossAxisCount: (width / 400.0).truncate().clamp(1, 4),
      crossAxisSpacing: 8.0,
      mainAxisSpacing: 32.0,
      children: createChartItems(false).map((e) {
        final (title, _, child) = e;

        return Column(
          children: [
            Expanded(
              child: Button(
                bodyPadding: const EdgeInsets.all(12.0),
                body: AbsorbPointer(
                  absorbing: true,
                  child: Column(
                    children: [
                      Expanded(
                        child: Builder(builder: child),
                      ),
                      Align(
                        alignment: Alignment.center,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: Text(
                            title,
                            style: textTheme.body2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                filled: true,
                onPressed: () {},
                padding: EdgeInsets.zero,
                theme: ButtonThemeData(
                  background: colorSheme.background[0],
                  hoverBackground: colorSheme.background[8],
                  highlightBackground: colorSheme.background[20],
                  //textStyle: textTheme.title,
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      //return bar_chart.BarPage();
      //return pie_chart.PiePage();
      // return time_series_chart.TimeSeriesPage();
      //return line_chart.LinePage();
      return behaviors.BehaviorsPage();
      //return legends.LegendsPage();
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Defaults.createHeader(context, 'Overview'),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return CustomScrollView(
                slivers: [
                  _creadeHeader('Bar Charts'),
                  _createItems(bar_chart.createItems),
                  _creadeHeader('Pie Charts'),
                  _createItems(pie_chart.createItems),
                  _creadeHeader('Line Charts'),
                  _createItems(line_chart.createItems),
                  _creadeHeader('Scatter Plot Charts'),
                  _createItems(scatter_plot_chart.createItems),
                  _creadeHeader('Time Series'),
                  _createItems(time_series_chart.createItems),
                  _creadeHeader('Axes'),
                  _createItems(axes.createItems),
                  _creadeHeader('Combo'),
                  _createItems(combo_chart.createItems),
                  _creadeHeader('Legends'),
                  _createItems(legends.createItems),
                  //_creadeHeader('Behaviors'),
                  //_createItems(behaviors.createItems),
                  _creadeHeader('i18n'),
                  _createItems(i18n.createItems)
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
