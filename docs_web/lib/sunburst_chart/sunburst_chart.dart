// Copyright (C) 2023 Adriano Souza (adriano.souza113@gmail.com)

library sunburst_chart;

import 'package:desktop/desktop.dart';

import 'simple.dart';

const _items = [
  SimpleSunburstChartBuilder(),
];

List<(String, String?, WidgetBuilder)> createItems([bool animate = true]) {
  return _items
      .map((e) => (e.title, e.subtitle, (context) => e.withSampleData(animate)))
      .toList();
}

List<(String, WidgetBuilder)> _createNodeItems() {
  return _items.map((e) => (e.title, (context) => e.page(0))).toList();
}

TreeNode createChartNode() {
  return TreeNode.children(
    titleBuilder: (context) => const Text('Sunburst'),
    children: _createNodeItems()
        .map((e) => TreeNode.child(
            titleBuilder: (context) => Text(e.$1), builder: e.$2))
        .toList(),
  );
}
