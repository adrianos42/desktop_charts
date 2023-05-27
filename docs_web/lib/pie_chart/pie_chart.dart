// Copyright (C) 2023 Adriano Souza (adriano.souza113@gmail.com)

library pie_chart;

import 'package:desktop/desktop.dart';

import 'auto_label.dart';
import 'donut.dart';
import 'gauge.dart';
import 'outside_label.dart';
import 'partial_pie.dart';
import 'simple.dart';

const _items = [
  SimplePieChartBuilder(),
  PieOutsideLabelChartBuilder(),
  PartialPieChartBuilder(),
  DonutPieChartBuilder(),
  DonutAutoLabelChartBuilder(),
  GaugeChartBuilder(),
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
    titleBuilder: (context) => const Text('Pie'),
    children: _createNodeItems()
        .map((e) => TreeNode.child(
            titleBuilder: (context) => Text(e.$1), builder: e.$2))
        .toList(),
  );
}
