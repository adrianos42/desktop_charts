// Copyright (C) 2023 Adriano Souza (adriano.souza113@gmail.com)

library line_chart;

import 'package:desktop/desktop.dart';

import '../defaults.dart';
import 'animation_zoom.dart';
import 'area_and_line.dart';
import 'dash_pattern.dart';
import 'line_annotation.dart';
import 'points.dart';
import 'range_annotation/margin.dart';
import 'range_annotation/simple.dart';
import 'segments.dart';
import 'simple/line_chart.dart';
import 'simple/nulls.dart';
import 'stacked/stacked_area.dart';
import 'stacked/stacked_area_custom_color.dart';
import 'stacked/stacked_area_nulls.dart';

const _items = [
  AreaAndLineChartBuilder(),
  DashPatternLineChartBuilder(),
  LineLineAnnotationChartBuilder(),
  PointsLineChartBuilder(),
  SegmentsLineChartBuilder(),
  LineAnimationZoomChartBuilder(),
  GroupedItensBuilder('Range Annotation'),
  LineRangeAnnotationMarginChartBuilder(),
  SimpleLineRangeAnnotationChartBuilder(),
  GroupedItensBuilder('Simple'),
  SimpleLineChartBuilder(),
  SimpleNullsLineChartBuilder(),
  GroupedItensBuilder('Stacked'),
  StackedAreaCustomColorLineChartBuilder(),
  StackedAreaNullsLineChartBuilder(),
  StackedAreaLineChartBuilder(),
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
    titleBuilder: (context) => const Text('Line'),
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
