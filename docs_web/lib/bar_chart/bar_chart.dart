// Copyright (C) 2023 Adriano Souza (adriano.souza113@gmail.com)

library bar_chart;

import 'package:desktop/desktop.dart';

import '../defaults.dart';
import 'grouped/fill_color.dart';
import 'grouped/simple.dart';
import 'grouped/single_target_line.dart';
import 'grouped/stacked.dart';
import 'grouped/stacked_weight_pattern.dart';
import 'grouped/target_line.dart';
import 'horizontal/bar_label.dart';
import 'horizontal/bar_label_custom.dart';
import 'horizontal/pattern_forward_hatch.dart';
import 'horizontal/simple.dart';
import 'pattern_forward_hatch.dart';
import 'simple.dart';
import 'spark_bar.dart';
import 'stacked/fill_color.dart';
import 'stacked/horizontal.dart';
import 'stacked/simple.dart';
import 'stacked/target_line.dart';
import 'vertical_bar_label.dart';

const _items = [
  SimpleBarChartBuilder(),
  PatternForwardHatchBarChartBuilder(),
  VerticalBarLabelChartBuilder(),
  // TODO(as): SparkBarBuilder(),
  GroupedItensBuilder('Grouped'),
  GroupedStackedBarChartBuilder(),
  GroupedBarTargetLineChartBuilder(),
  GroupedBarSingleTargetLineChartBuilder(),
  GroupedStackedWeightPatternBarChartBuilder(),
  SimpleGroupedBarChartBuilder(),
  GroupedFillColorBarChartBuilder(),
  GroupedItensBuilder('Horizontal'),
  HorizontalBarLabelChartBuilder(),
  HorizontalBarLabelCustomChartBuilder(),
  HorizontalPatternForwardHatchBarChartBuilder(),
  SimpleHorizontalBarChartBuilder(),
  GroupedItensBuilder('Stacked'),
  StackedHorizontalBarChartBuilder(),
  StackedFillColorBarChartBuilder(),
  SimpleStackedBarChartBuilder(),
  StackedBarTargetLineChartBuilder(),
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
    titleBuilder: (context) => const Text('Bar'),
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
