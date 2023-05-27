// Copyright (C) 2023 Adriano Souza (adriano.souza113@gmail.com)

library behaviors;

import 'package:desktop/desktop.dart';

import '../defaults.dart';
import 'chart_title.dart';
import 'initial_hint_animation.dart';
import 'initial_selection.dart';
import 'percent/domain.dart';
import 'percent/domain_by_category.dart';
import 'percent/series.dart';
import 'selection/bar_highlight.dart';
import 'selection/callback_example.dart';
import 'selection/line_highlight.dart';
import 'selection/line_highlight_custom_shape.dart';
import 'selection/scatter_plot_highlight.dart';
import 'selection/user_managed.dart';
import 'slider.dart';
import 'sliding_viewport_on_selection.dart';

const _items = [
  ChartTitleLineBuilder(),
  // TODO InitialHintAnimationBuilder(),
  InitialSelectionBuilder(),
  SliderLineBuilder(),
  SlidingViewportOnSelectionBuilder(),
  GroupedItensBuilder('Percent'),
  PercentOfDomainByCategoryBarChartBuilder(),
  PercentOfDomainBarChartBuilder(),
  PercentOfSeriesBarChartBuilder(),
  GroupedItensBuilder('Selection'),
  SelectionBarHighlightBuilder(),
  SelectionCallbackExampleBuilder(),
  SelectionLineHighlightCustomShapeBuilder(),
  SelectionLineHighlightBuilder(),
  SelectionScatterPlotHighlightBuilder(),
  SelectionUserManagedBuilder(),
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
    titleBuilder: (context) => const Text('Behaviors'),
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