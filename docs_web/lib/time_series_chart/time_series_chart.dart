// Copyright (C) 2023 Adriano Souza (adriano.souza113@gmail.com)

library time_series_chart;

import 'package:desktop/desktop.dart';

import '../defaults.dart';
import 'confidence_interval.dart';
import 'end_points_axis.dart';
import 'line_annotation.dart';
import 'range_annotation/margin_labels.dart';
import 'range_annotation/simple.dart';
import 'simple.dart';
import 'symbol_annotation.dart';
import 'with_bar_renderer.dart';

const _items = [
  SimpleTimeSeriesChartBuilder(),
  EndPointsAxisTimeSeriesChartBuilder(),
  TimeSeriesLineAnnotationChartBuilder(),
  TimeSeriesSymbolAnnotationChartBuilder(),
  TimeSeriesBarBuilder(),
  TimeSeriesConfidenceIntervalBuilder(),
  GroupedItensBuilder('Range Annotation'),
  TimeSeriesRangeAnnotationMarginChartBuilder(),
  SimpleTimeSeriesRangeAnnotationChartBuilder(),
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
    titleBuilder: (context) => const Text('Time Series'),
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