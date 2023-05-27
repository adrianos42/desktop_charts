// Copyright (C) 2023 Adriano Souza (adriano.souza113@gmail.com)

import 'package:desktop/desktop.dart';
import 'package:flutter/foundation.dart';
import 'package:jovial_svg/jovial_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../defaults.dart';
import 'axes/axes.dart' as axes;
import 'bar_chart/bar_chart.dart' as bar_chart;
import 'behaviors/behaviors.dart' as behaviors;
import 'combo_chart/combo.dart' as combo_chart;
import 'home.dart' show DocTreeController, DocTreeIndex;
import 'i18n/i18n.dart' as i18n;
import 'legends/legends.dart' as legends;
import 'line_chart/line_chart.dart' as line_chart;
import 'pie_chart/pie_chart.dart' as pie_chart;
import 'scatter_plot_chart/scatter_plot_chart.dart' as scatter_plot_chart;
import 'time_series_chart/time_series_chart.dart' as time_series_chart;

class OverviewPage extends StatefulWidget {
  const OverviewPage({
    super.key,
    required this.treeController,
    required this.treeNodeController,
  });

  final TreeController treeController;
  final DocTreeController treeNodeController;

  @override
  State<OverviewPage> createState() => OverviewPageState();
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

class OverviewPageState extends State<OverviewPage> {
  @override
  void initState() {
    super.initState();
  }

  final ScrollController _controller = ScrollController();

  Widget _creadeHeader(String title, [double topPadding = 24.0]) {
    return SliverPersistentHeader(
      pinned: false,
      floating: false,
      delegate: HeaderDelegate(title, topPadding),
    );
  }

  Widget _createItems(
    int treeStartIndex,
    List<(String, String?, String?, WidgetBuilder)> Function(bool animate)
        createChartItems,
  ) {
    final themeData = Theme.of(context);
    final colorSheme = themeData.colorScheme;
    final textTheme = themeData.textTheme;

    final width = MediaQuery.sizeOf(context).width;

    final children = <Widget>[];

    final chartItems = createChartItems(false);

    int x = -1;
    int y = 0;
    String? currentTitle;

    for (int i = 0; i < chartItems.length; i += 1) {
      final (title, _, parentTitle, child) = chartItems[i];

      if (parentTitle != null) {
        if (parentTitle == currentTitle) {
          y += 1;
        } else {
          currentTitle = parentTitle;
          y = 0;
          x += 1;
        }
      } else {
        currentTitle = null;
        y = 0;
        x += 1;
      }

      final index = x;
      final itemIndex = y;

      children.add(
        Column(
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
                onPressed: () {
                  widget.treeController.index = [treeStartIndex, index];
                  if (parentTitle != null) {
                    widget.treeNodeController.index = DocTreeIndex(
                      nodeIndex: itemIndex,
                      parentTitle: parentTitle,
                    );
                  }
                },
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
        ),
      );
    }

    return SliverGrid.count(
      crossAxisCount: (width / 400.0).truncate().clamp(1, 4),
      crossAxisSpacing: 8.0,
      mainAxisSpacing: 32.0,
      children: children,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      //return bar_chart.BarPage();
      //return pie_chart.PiePage();
      // return time_series_chart.TimeSeriesPage();
      // return LineAnimationZoomChartBuilder().withSampleData();
      //return const behaviors.BehaviorsPage();
      //return legends.LegendsPage();
      // return axes.createItems()[10].$4(context);
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Defaults.createHeader(context, 'Overview'),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(top: 12.0, left: 12.0, bottom: 12.0),
            child: Button(
              padding: EdgeInsets.zero,
              body: ScalableImageWidget.fromSISource(
                si: ScalableImageSource.fromSvgHttpUrl(
                  Uri.parse(
                    'https://img.shields.io/pub/v/desktop_charts.svg?style=flat-square',
                  ),
                ),
              ),
              onPressed: () async {
                await launchUrl(
                  Uri.parse('https://pub.dev/packages/desktop_charts'),
                );
              },
            ),
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return CustomScrollView(
                controller: _controller,
                slivers: [
                  _creadeHeader('Bar', 0.0),
                  _createItems(1, bar_chart.createItems),
                  _creadeHeader('Pie'),
                  _createItems(2, pie_chart.createItems),
                  _creadeHeader('Line'),
                  _createItems(3, line_chart.createItems),
                  _creadeHeader('Scatter Plot'),
                  _createItems(4, scatter_plot_chart.createItems),
                  _creadeHeader('Time Series'),
                  _createItems(5, time_series_chart.createItems),
                  _creadeHeader('Axes'),
                  _createItems(6, axes.createItems),
                  _creadeHeader('Combo'),
                  _createItems(7, combo_chart.createItems),
                  _creadeHeader('Legedns'),
                  _createItems(8, legends.createItems),
                  _creadeHeader('Behaviors'),
                  _createItems(9, behaviors.createItems),
                  _creadeHeader('i18n'),
                  _createItems(10, i18n.createItems),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
