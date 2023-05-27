// Copyright (C) 2023 Adriano Souza (adriano.souza113@gmail.com)

library combo;

import 'package:desktop/desktop.dart';

import 'date_time_line_point.dart';
import 'numeric_line_bar.dart';
import 'numeric_line_point.dart';
import 'ordinal_bar_line.dart';
import 'scatter_plot_line.dart';

const _items = [
  OrdinalComboBarLineChartBuilder(),
  NumericComboLineBarChartBuilder(),
  NumericComboLinePointChartBuilder(),
  DateTimeComboLinePointChartBuilder(),
  ScatterPlotComboLineChartBuilder(),
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
    titleBuilder: (context) => const Text('Combo'),
    children: _createNodeItems()
        .map((e) => TreeNode.child(
            titleBuilder: (context) => Text(e.$1), builder: e.$2))
        .toList(),
  );
}
