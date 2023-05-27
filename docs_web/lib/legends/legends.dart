// Copyright (C) 2023 Adriano Souza (adriano.souza113@gmail.com)

library legends;

import 'package:desktop/desktop.dart';

import '../defaults.dart';
import 'datum/measures.dart';
import 'datum/options.dart';
import 'default_hidden_series_legend.dart';
import 'legend_custom_symbol.dart';
import 'series/datum.dart';
import 'series/measures.dart';
import 'series/options.dart';
import 'series/simple.dart';

const _items = [
  DefaultHiddenSeriesLegendBuilder(),
  LegendWithCustomSymbolBuilder(),
  GroupedItensBuilder('Datum'),
  DatumLegendWithMeasuresBuilder(),
  DatumLegendOptionsBuilder(),
  GroupedItensBuilder('Series'),
  SimpleDatumLegendBuilder(),
  LegendWithMeasuresBuilder(),
  LegendOptionsBuilder(),
  SimpleSeriesLegendBuilder(),
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

List<ExampleBuilder> _createAllNodeItems() {
  return _items.where((e) => !e.hasParent).toList();
}

TreeNode createChartNode(
    (
      String?,
      int,
    ) selectedIndex) {
  final (parentTitle, childIndex) = selectedIndex;

  return TreeNode.children(
    titleBuilder: (context) => const Text('Legends'),
    children: _createAllNodeItems().map((e) {
      return TreeNode.child(
        titleBuilder: (context) => Text(e.title),
        builder: (context) => e.page(
          parentTitle == e.title ? childIndex : null,
          e.hasChildren
              ? _items
                  .where((w) => w.hasParent && w.parentTitle == e.title)
                  .toList()
              : null,
        ),
      );
    }).toList(),
  );
}