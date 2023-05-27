// Copyright (C) 2023 Adriano Souza (adriano.souza113@gmail.com)

library i18n;

import 'package:desktop/desktop.dart';

import 'rtl_bar_chart.dart';
import 'rtl_line_chart.dart';
import 'rtl_line_segments.dart';
import 'rtl_series_legend.dart';

const _items = [
  RTLBarChartBuilder(),
  RTLLineChartBuilder(),
  RTLLineSegmentsBuilder(),
  RTLSeriesLegendBuilder(),
];

List<(String, String?, String? parentTitle, WidgetBuilder)> createItems(
    [bool animate = true]) {
  return _items
      .where((e) => !e.hasChildren)
      .map((e) => (
            e.title,
            e.subtitle,
            e.parentTitle,
            (context) => e.withSampleData(animate)
          ))
      .toList();
}

List<(String, WidgetBuilder)> _createNodeItems() {
  return _items.map((e) => (e.title, (context) => e.page(0))).toList();
}

TreeNode createChartNode() {
  return TreeNode.children(
    titleBuilder: (context) => const Text('i18n'),
    children: _createNodeItems()
        .map((e) => TreeNode.child(
            titleBuilder: (context) => Text(e.$1), builder: e.$2))
        .toList(),
  );
}
