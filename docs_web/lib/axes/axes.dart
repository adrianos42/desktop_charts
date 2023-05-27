// Copyright (C) 2023 Adriano Souza (adriano.souza113@gmail.com)

library axes;

import 'package:desktop/desktop.dart';

import '../defaults.dart';
import 'bar/secondary.dart';
import 'bar/secondary_only.dart';
import 'custom/axis_tick_formatters.dart';
import 'custom/font_size_and_color.dart';
import 'custom/measure_tick_count.dart';
import 'gridline_dash_pattern.dart';
import 'hidden_ticks_and_labels_axis.dart';
import 'horizontal_bar_secondary_axis.dart';
import 'integer_only_measure_axis.dart';
import 'line_disjoint_axis.dart';
import 'measure_axis_label_alignment.dart';
import 'nonzero_bound_measure_axis.dart';
import 'numeric_initial_viewport.dart';
import 'ordinal_initial_viewport.dart';
import 'short_tick_length_axis.dart';
import 'statically_provided_ticks.dart';

const _items = [
  HorizontalBarChartWithSecondaryAxisBuilder(),
  ShortTickLengthAxisBuilder(),
  MeasureAxisLabelAlignmentBuilder(),
  HiddenTicksAndLabelsAxisBuilder(),
  StaticallyProvidedTicksBuilder(),
  IntegerOnlyMeasureAxisBuilder(),
  NonzeroBoundMeasureAxisBuilder(),
  OrdinalInitialViewportBuilder(),
  NumericInitialViewportBuilder(),
  GridlineDashPatternBuilder(),
  DisjointMeasureAxisLineChartBuilder(),
  GroupedItensBuilder('Bar'),
  BarChartWithSecondaryAxisOnlyBuilder(),
  BarChartWithSecondaryAxisBuilder(),
  GroupedItensBuilder('Custom'),
  CustomAxisTickFormattersBuilder(),
  CustomFontSizeAndColorBuilder(),
  CustomMeasureTickCountBuilder(),
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
    titleBuilder: (context) => const Text('Axes'),
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