// // Copyright (C) 2023 Adriano Souza (adriano.souza113@gmail.com)

// // Copyright 2018 the Charts project authors. Please see the AUTHORS file
// // for details.
// //
// // Licensed under the Apache License, Version 2.0 (the "License");
// // you may not use this file except in compliance with the License.
// // You may obtain a copy of the License at
// //
// // http://www.apache.org/licenses/LICENSE-2.0
// //
// // Unless required by applicable law or agreed to in writing, software
// // distributed under the License is distributed on an "AS IS" BASIS,
// // WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// // See the License for the specific language governing permissions and
// // limitations under the License.

// import 'dart:collection' show HashSet;
// import 'dart:math' show max, min, pi;

// import 'package:collection/collection.dart' show IterableExtension;
// import 'package:flutter/widgets.dart';

// import '../../data/series.dart' show AttributeKey;
// import '../../data/tree.dart' show TreeNode;
// import '../base_chart.dart' show BaseChart;
// import '../pie/arc_renderer_decorator.dart' show ArcRendererDecorator;
// import '../pie/arc_renderer_element.dart'
//     show ArcRendererElement, AnimatedArcs, AnimatedArc;
// import '../pie/base_arc_renderer.dart';
// import '../processed_series.dart' show ImmutableSeries, MutableSeries;
// import 'sunburst_arc_renderer_config.dart'
//     show SunburstArcRendererConfig, SunburstColorStrategy;

// const arcElementsKey = AttributeKey<List<SunburstArcRendererElement<Object>>>(
//     'SunburstArcRenderer.elements');

// /// ArcRenderer for the Sunburst chart using Tree based data.
// class SunburstArcRenderer<D, S extends BaseChart<D>>
//     extends BaseArcRenderer<D, S> {
//   SunburstArcRenderer({
//     String? rendererId,
//     SunburstArcRendererConfig<D>? config,
//     required super.chartState,
//     required super.seriesList,
//   }) : super(
//           config: config ?? SunburstArcRendererConfig<D>(),
//           rendererId: rendererId ?? 'sunburst',
//         );

//   List<ArcRendererDecorator<D>> get _arcRendererDecorators =>
//       config.arcRendererDecorators;

//   Rect? get componentBounds => Rect.fromLTWH(0.0, 0.0, size.width, size.height);

//   /// Store a map of series drawn on the chart, mapped by series name.
//   ///
//   /// [Map] is used to render the series on the canvas in the same
//   /// order as the data was given to the chart.
//   // ignore: prefer_collection_literals, https://github.com/dart-lang/linter/issues/1649
//   final _seriesArcMap = Map<String, List<AnimatedArcs<D>>>();

//   final _nodeToArcRenderElementMap =
//       <TreeNode<D>, SunburstArcRendererElement>{};

//   // Store a list of arcs that exist in the series data.
//   //
//   // This list will be used to remove any [AnimatedArc] that were rendered in
//   // previous draw cycles, but no longer have a corresponding datum in the new
//   // data.
//   final _currentKeys = <String>[];

//   final _nodeToExpand = HashSet<TreeNode<dynamic>>();

//   SunburstArcRendererConfig<D> get _config =>
//       config as SunburstArcRendererConfig<D>;

//   /// Stroke color of the border of the arcs.
//   Color get strokeColor => chartState.themeData.arcStrokeColor;

//   // /// Color of the "no data" state for the chart, used when an empty series is
//   // /// drawn.
//   Color get noDataColor => chartState.themeData.noDataColor;

//   @override
//   void preprocessSeries() {
//     _nodeToArcRenderElementMap.clear();
//     for (final series in seriesList) {
//       final elements = <SunburstArcRendererElement<D>>[];

//       final domainFn = series.domainFn;
//       final measureFn = series.measureFn;

//       // The seriesMeasureTotal needs to be computed from currently displayed
//       // top level.
//       double seriesMeasureTotal = 0.0;

//       for (int i = 0; i < series.data.length; i += 1) {
//         final node = series.data[i] as TreeNode<Object>;
//         final measure = measureFn(i);
//         if (node.depth == 1 && measure != null) {
//           seriesMeasureTotal += measure;
//         }
//       }

//       // On the canvas, arc measurements are defined as angles from the positive
//       // x axis. Start our first slice at the positive y axis instead.
//       final startAngle = config.startAngle;
//       final arcLength = config.arcLength;

//       // No data processing is same as the regular arc renderer.
//       if (series.data.isEmpty) {
//         // If the series has no data, generate an empty arc element that
//         // occupies the entire chart.
//         //
//         // Use a tiny epsilon difference to ensure that the canvas renders a
//         // "full" circle, in the correct direction.
//         final angle = arcLength == 2 * pi ? arcLength * .999999 : arcLength;
//         final endAngle = startAngle + angle;

//         final details = SunburstArcRendererElement<D>(
//             startAngle: startAngle,
//             endAngle: endAngle,
//             index: 0,
//             key: 0,
//             series: series);

//         elements.add(details);
//       } else {
//         // Create SunburstArcRendererElement for each item in the tree,
//         // excluding the root node.
//         final root = series.data.first as TreeNode<D>;
//         root.visit((node) {
//           elements.addAll(_createArcRenderElementForNode(series, node));
//         });
//       }

//       series.setAttr(arcElementsKey, elements);
//     }
//   }

//   // Create SunburstArcRendererElement for children of the node.
//   List<SunburstArcRendererElement<D>> _createArcRenderElementForNode(
//       MutableSeries<D> series, TreeNode<D> node) {
//     final elements = <SunburstArcRendererElement<D>>[];
//     final children = node.children;
//     if (children.isNotEmpty) {
//       double childrenMeasureTotal = 0.0;

//       // Compute the measure total for the node's children.
//       for (int i = 0; i < children.length; i += 1) {
//         final child = children.elementAt(i);
//         final measure = series.measureFn(series.data.indexOf(child));
//         if (measure != null) {
//           childrenMeasureTotal += measure;
//         }
//       }

//       // Create ArcRenderElement for the node's children. Computing arc angles
//       // based on parent arc’s arcLength and the nodes measure versus the
//       // sibling nodes.
//       double startAngle = _getParentStartAngle(node);
//       for (int i = 0; i < children.length; i += 1) {
//         final child = children.elementAt(i);
//         final arcIndex = series.data.indexOf(child);
//         final measure = series.measureFn(arcIndex);
//         final domain = series.domainFn(arcIndex);
//         if (measure == null) {
//           continue;
//         }

//         final percentOfLevel =
//             childrenMeasureTotal > 0 ? measure / childrenMeasureTotal : 0;
//         final angle = _getParentArcLength(node) * percentOfLevel;
//         final endAngle = startAngle + angle;

//         final details = SunburstArcRendererElement<D>(
//           arcLength: angle,
//           startAngle: startAngle,
//           endAngle: endAngle,
//           index: arcIndex,
//           key: arcIndex,
//           domain: domain,
//           series: series,
//         );

//         _nodeToArcRenderElementMap[child] = details;
//         elements.add(details);

//         // Update the starting angle for the next datum in the series.
//         startAngle = endAngle;
//       }
//     }
//     return elements;
//   }

//   double _getParentArcLength(TreeNode<D> parent) =>
//       _nodeToArcRenderElementMap[parent]?.arcLength != null
//           ? _nodeToArcRenderElementMap[parent]!.arcLength!
//           : config.arcLength;

//   double _getParentStartAngle(TreeNode<D> parent) =>
//       _nodeToArcRenderElementMap[parent] != null
//           ? _nodeToArcRenderElementMap[parent]!.startAngle
//           : config.startAngle;

//   @override
//   void update() {
//     super.update();

//     _currentKeys.clear();

//     final center = Offset(
//         (size.width / 2).roundToDouble(), (size.height / 2).roundToDouble());

//     final radius = size.height < size.width
//         ? (size.height / 2).roundToDouble()
//         : (size.width / 2).roundToDouble();

//     if (config.arcRatio != null) {
//       if (config.arcRatio! < 0 || config.arcRatio! > 1) {
//         throw ArgumentError('arcRatio must be between 0 and 1');
//       }
//     }

//     for (final series in seriesList) {
//       final colorFn = series.colorFn;
//       final arcListKey = series.id;
//       final elementsList = series.getAttr(arcElementsKey)
//           as List<SunburstArcRendererElement<D>>?;

//       final arcLists =
//           _seriesArcMap.putIfAbsent(arcListKey, () => <AnimatedArcs<D>>[]);
//       if (series.data.isEmpty) {
//         final arcList = AnimatedArcs<D>();

//         _seriesArcMap.putIfAbsent(arcListKey, () => [arcList]);
//         final innerRadius = _calculateRadii(radius).first;

//         // If the series is empty, set up the "no data" arc element. This should
//         // occupy the entire chart, and use the chart style's no data color.
//         final details = elementsList![0];

//         const arcKey = '__no_data__';

//         // If we already have an AnimatingArc for that index, use it.
//         AnimatedArc<D>? animatingArc =
//             arcList.arcs.firstWhereOrNull((arc) => arc.key == arcKey);

//         arcList.center = center;
//         arcList.radius = radius;
//         arcList.innerRadius = innerRadius;
//         arcList.series = series;
//         arcList.stroke = noDataColor;
//         arcList.strokeWidth = 0.0;

//         // If we don't have any existing arc element, create a arc. Unlike
//         // real arcs, we should not animate the no data state in from 0.
//         if (animatingArc == null) {
//           animatingArc = AnimatedArc<D>(arcKey, null, null);
//           arcList.arcs.add(animatingArc);
//         } else {
//           animatingArc.datum = null;
//           animatingArc.domain = null;
//         }

//         // Update the set of arcs that still exist in the series data.
//         _currentKeys.add(arcKey);

//         // Get the arcElement we are going to setup.
//         // Optimization to prevent allocation in non-animating case.
//         final arcElement = SunburstArcRendererElement<D>(
//             startAngle: details.startAngle,
//             endAngle: details.endAngle,
//             color: noDataColor,
//             series: series);

//         animatingArc.setNewTarget(arcElement);

//         arcLists.add(arcList);
//       } else {
//         double previousEndAngle = config.startAngle;

//         // Create Arc and add to arcList for each of the node with depth
//         // within config.maxDisplayLevel
//         final root = series.data.first as TreeNode<Object>;
//         int maxDepth = 0;
//         root.visit((node) {
//           maxDepth = max(maxDepth, node.depth);
//         });

//         // Create arcLists up to min(maxDepth, config.maxDisplayLevel).
//         final maxDisplayLevel = min(maxDepth, _config.maxDisplayLevel);
//         final displayLevel = min(maxDepth, _config.initialDisplayLevel);
//         for (int i = 0; i < maxDisplayLevel; i += 1) {
//           final arcList = arcLists.length > i ? arcLists[i] : AnimatedArcs<D>();

//           // Create arc for node that’s within the initial display level or
//           // selected nodes and its children up to the maxDisplayLevel.
//           for (final node in _nodeToArcRenderElementMap.keys.where((e) =>
//               e.depth == i + 1 &&
//               (e.depth <= displayLevel || _nodeToExpand.contains(e)))) {
//             final radii = _calculateRadii(radius, maxDisplayLevel, i + 1);
//             final innerRadius = radii.first;
//             final outerRadius = radii.last;

//             final arcIndex = series.data.indexOf(node);
//             final Object datum = series.data[arcIndex];
//             final details = _nodeToArcRenderElementMap[node];
//             final domainValue = details!.domain;
//             final isLeaf = !node.hasChildren ||
//                 ((node.depth == displayLevel || _nodeToExpand.contains(node)) &&
//                     !_nodeToExpand.any((e) => node.children.contains(e)));
//             final isOuterMostRing = node.depth == maxDisplayLevel;

//             final arcKey = '${series.id}__${domainValue.toString()}';

//             // If we already have an AnimatingArc for that index, use it.
//             AnimatedArc<D>? animatingArc =
//                 arcList.arcs.firstWhereOrNull((arc) => arc.key == arcKey);

//             arcList.center = center;
//             arcList.radius = outerRadius;
//             arcList.innerRadius = innerRadius;
//             arcList.series = series;
//             arcList.stroke = strokeColor;
//             arcList.strokeWidth = config.strokeWidth;

//             // If we don't have any existing arc element, create a arc and
//             // have it animate in from the position of the previous arc's end
//             // angle. If there were no previous arcs, then animate everything in
//             // from 0.
//             if (animatingArc == null) {
//               animatingArc = AnimatedArc<D>(arcKey, datum, domainValue)
//                 ..setNewTarget(SunburstArcRendererElement<D>(
//                   color: colorFn!(arcIndex),
//                   startAngle: previousEndAngle,
//                   endAngle: previousEndAngle,
//                   index: arcIndex,
//                   series: series,
//                   isLeaf: isLeaf,
//                   isOuterMostRing: isOuterMostRing,
//                 ));

//               arcList.arcs.add(animatingArc);
//             } else {
//               animatingArc.datum = datum;

//               previousEndAngle = animatingArc.previousArcEndAngle ?? 0.0;
//             }

//             animatingArc.domain = domainValue;

//             // Update the set of arcs that still exist in the series data.
//             _currentKeys.add(arcKey);

//             // Get the arcElement we are going to setup.
//             // Optimization to prevent allocation in non-animating case.
//             final arcElement = SunburstArcRendererElement<D>(
//                 color: colorFn!(arcIndex),
//                 startAngle: details.startAngle,
//                 endAngle: details.endAngle,
//                 index: arcIndex,
//                 series: series,
//                 isLeaf: isLeaf,
//                 isOuterMostRing: isOuterMostRing);

//             animatingArc.setNewTarget(arcElement);
//           }
//           if (arcLists.length <= i && arcList.arcs.isNotEmpty) {
//             arcLists.add(arcList);
//           }
//         }
//       }
//     }

//     // Animate out arcs that don't exist anymore.
//     _seriesArcMap.forEach((String key, List<AnimatedArcs<D>> arcLists) {
//       for (final arcList in arcLists) {
//         for (int arcIndex = 0; arcIndex < arcList.arcs.length; arcIndex += 1) {
//           final arc = arcList.arcs[arcIndex];
//           final arcStartAngle = arc.previousArcStartAngle;

//           if (_currentKeys.contains(arc.key) != true) {
//             // Default to animating out to the top of the chart, clockwise, if
//             // there are no arcs that start past this arc.
//             double targetArcAngle = (2 * pi) + config.startAngle;

//             // Find the nearest start angle of the next arc that still exists in
//             // the data.
//             for (final nextArc in arcList.arcs
//                 .where((arc) => _currentKeys.contains(arc.key))) {
//               final nextArcStartAngle = nextArc.newTargetArcStartAngle;

//               if (arcStartAngle! < nextArcStartAngle! &&
//                   nextArcStartAngle < targetArcAngle) {
//                 targetArcAngle = nextArcStartAngle;
//               }
//             }

//             arc.animateOut(targetArcAngle);
//           }
//         }
//       }
//     });
//   }

//   @override
//   void draw(PaintingContext context, Offset offset) {
//     super.draw(context, offset);

//     // Clean up the arcs that no longer exist.
//     if (chartState.animationPosition.value == 1.0) {
//       final keysToRemove = <String>[];

//       _seriesArcMap.forEach((String key, List<AnimatedArcs<D>> arcLists) {
//         final arcListToRemove = <AnimatedArcs<D>>[];
//         for (final arcList in arcLists) {
//           arcList.arcs.removeWhere((AnimatedArc<D> arc) => arc.animatingOut);

//           if (arcList.arcs.isEmpty) {
//             arcListToRemove.add(arcList);
//           }
//         }

//         arcListToRemove.forEach(arcLists.remove);
//         if (arcLists.isEmpty) {
//           keysToRemove.add(key);
//         }
//       });

//       keysToRemove.forEach(_seriesArcMap.remove);
//     }
//   }

//   bool _isNodeDisplayed(TreeNode<D>? node) {
//     return node != null &&
//         (node.depth <= _config.initialDisplayLevel ||
//             _nodeToExpand.contains(node));
//   }

//   // Records the nodes to expand beyond initial display level.
//   void expandNode(TreeNode<D>? node) {
//     if (node == null) {
//       _nodeToExpand.clear();
//     } else if (node.hasChildren) {
//       // Collapse rings up to the clicked expanded node.
//       if (node.children.any((e) => _nodeToExpand.contains(e))) {
//         node.visit((e) {
//           if (node != e) {
//             _nodeToExpand.remove(e);
//           }
//         });
//       } else {
//         // Expand clicked node by one level.
//         _nodeToExpand.add(node);
//         _nodeToExpand.addAll(node.children);
//       }
//     }
//   }

//   /// Assigns one color pallet for each subtree from the children of the root
//   /// node, and one shade for each node of the subtree to series that are
//   /// missing their colorFn.
//   @override
//   void assignMissingColors(
//     Iterable<MutableSeries<D>> seriesList, {
//     required bool emptyCategoryUsesSinglePalette,
//   }) {
//     for (final series in seriesList) {
//       if (series.colorFn == null) {
//         final root = series.data.first as TreeNode<D>;
//         final firstLevelChildren = (series.data.first as TreeNode<D>).children;

//         // Create number of palettes based on the first level children of root.
//         final colorPalettes =
//             chartState.themeData.getOrderedPalettes(root.children.length);
//         final nodeToColorMap = {};

//         // Create shades base on number of Nodes in the subtree
//         if (_config.colorAssignmentStrategy ==
//             SunburstColorStrategy.newShadePerArc) {
//           for (int i = 0; i < firstLevelChildren.length; i += 1) {
//             int numOfNodeInSubTree = 0;

//             firstLevelChildren.elementAt(i).visit((node) {
//               numOfNodeInSubTree += 1;
//             });

//             final colorList = colorPalettes[i].makeShades(numOfNodeInSubTree);

//             // Fill in node to color map to be used in the colorFn
//             numOfNodeInSubTree = 0;
//             firstLevelChildren.elementAt(i).visit((node) {
//               nodeToColorMap[node] = colorList[numOfNodeInSubTree];
//               numOfNodeInSubTree += 1;
//             });
//           }
//         } else {
//           // Create number of shades based on the full depth of the tree instead
//           // of each subtree, so the shades of each branch looks more aligned
//           // at each level.
//           int depthOfTree = 0;

//           root.visit((node) {
//             depthOfTree = max(depthOfTree, node.depth);
//           });

//           for (int i = 0; i < firstLevelChildren.length; i += 1) {
//             final colorList = colorPalettes[i].makeShades(depthOfTree);

//             // Fill in node to color map to be used in the colorFn
//             firstLevelChildren.elementAt(i).visit((node) {
//               nodeToColorMap[node] = colorList[node.depth - 1];
//             });
//           }
//         }
//         series.colorFn ??= (index) =>
//             nodeToColorMap[series.data[index!]] ??
//             chartState.themeData.foreground;
//       }
//     }
//   }

//   /// Calculate the inner and outer radius of the current level based on config.
//   List<double> _calculateRadii(
//     double radius, [
//     int maxDisplayLevel = 1,
//     int currentLevel = 1,
//   ]) {
//     // arcRatio trumps arcWidth for determining the inner radius. If neither is
//     // defined, then inner radius is 0.
//     final double baseInnerRadius;

//     if (config.arcRatio != null) {
//       baseInnerRadius = max(radius - radius * config.arcRatio!, 0.0).toDouble();
//     } else if (config.arcWidth != null) {
//       baseInnerRadius = max(radius - config.arcWidth!, 0.0).toDouble();
//     } else {
//       baseInnerRadius = 0.0;
//     }

//     if (_config.arcWidths != null && _config.arcWidths!.isNotEmpty) {
//       // Check if arcWidths provided covers maxDisplayLevel, if not, copy the
//       // last value for each level not provided.
//       final arcWidths = _ensureConfigLengthCoversMaxDisplayLevel(
//         _config.arcWidths!,
//         maxDisplayLevel,
//       );
//       final sumOfPreviousLevelRadii = currentLevel > 1
//           ? arcWidths.take(currentLevel - 1).reduce((a, b) => a + b)
//           : 0;
//       final innerRadius = baseInnerRadius + sumOfPreviousLevelRadii;
//       return [
//         innerRadius,
//         innerRadius + arcWidths[currentLevel - 1] - config.strokeWidth
//       ];
//     } else {
//       final totalRadius = radius - baseInnerRadius;
//       final double radiusDenom;
//       final double sumOfPreviousLevelRadiiFactor;
//       final double currentLevelRadiusFactor;

//       // If arcRatios is defined, calculate inner and outer radius based on it.
//       if (_config.arcRatios != null && _config.arcRatios!.isNotEmpty) {
//         final arcRatios = _ensureConfigLengthCoversMaxDisplayLevel(
//           _config.arcRatios!,
//           maxDisplayLevel,
//         );
//         radiusDenom = arcRatios.reduce((a, b) => a + b);
//         sumOfPreviousLevelRadiiFactor = currentLevel > 1
//             ? arcRatios.take(currentLevel - 1).reduce((a, b) => a + b)
//             : 0;
//         currentLevelRadiusFactor = arcRatios[currentLevel - 1];
//       } else {
//         // Else distribute the chart area to rings evenly.
//         radiusDenom = maxDisplayLevel.toDouble();
//         sumOfPreviousLevelRadiiFactor = currentLevel - 1;
//         currentLevelRadiusFactor = 1;
//       }

//       // InnerRadius is baseInnerRadius + sum of radii of previous levels.
//       final innerRadius = baseInnerRadius +
//           totalRadius * sumOfPreviousLevelRadiiFactor / radiusDenom;

//       // OuterRadius is baseInnerRadius + sum of radii of previous levels +
//       // radius of currentLevel. Subtract config.strokeWidth from outerRadius to
//       // create the separation of slice between levels.
//       final outerRadius = baseInnerRadius +
//           totalRadius *
//               (sumOfPreviousLevelRadiiFactor + currentLevelRadiusFactor) /
//               radiusDenom -
//           config.strokeWidth;
//       return [innerRadius, outerRadius];
//     }
//   }

//   @override
//   List<AnimatedArcs<D>> getArcLists({String? seriesId}) {
//     if (seriesId == null) {
//       return _seriesArcMap.values.first;
//     }
//     final arcList = _seriesArcMap[seriesId];

//     if (arcList == null) {
//       return <AnimatedArcs<D>>[];
//     }
//     return arcList;
//   }

//   List<double> _ensureConfigLengthCoversMaxDisplayLevel(
//     List<double> configParam,
//     int maxDisplayLevel,
//   ) {
//     // Check if config param provided covers maxDisplayLevel, if not, copy the
//     // last value for each level not provided.
//     List<double> arcWidths;
//     if (configParam.length < maxDisplayLevel) {
//       // Repeat last value in the config param to match length of
//       // maxDisplayLevel.
//       arcWidths = List<double>.generate(maxDisplayLevel,
//           (i) => (configParam.length > i) ? configParam[i] : configParam.last);
//     } else {
//       arcWidths = List<double>.from(configParam);
//     }
//     return arcWidths;
//   }
// }

// class SunburstArcRendererElement<D> extends ArcRendererElement<D> {
//   SunburstArcRendererElement({
//     required double startAngle,
//     required double endAngle,
//     required ImmutableSeries<D> series,
//     Color? color,
//     int? index,
//     int? key,
//     D? domain,
//     this.arcLength,
//     this.isLeaf,
//     this.isOuterMostRing,
//   }) : super(
//           startAngle: startAngle,
//           endAngle: endAngle,
//           series: series,
//           color: color,
//           index: index,
//           key: key,
//           domain: domain,
//         );

//   /// Records the arcLength of a particular node, so its children can use it
//   /// to compute the start and end angles.
//   double? arcLength;

//   /// Whether the SunburstArcRendererElement is currently displayed as the outer
//   /// most arc of the branch.
//   bool? isLeaf;

//   /// Whether the SunburstArcRendererElement is on the outer most ring of the
//   /// sunburst.
//   bool? isOuterMostRing;

//   @override
//   SunburstArcRendererElement<D> clone() {
//     return SunburstArcRendererElement<D>(
//       arcLength: arcLength,
//       startAngle: startAngle,
//       endAngle: endAngle,
//       color: color,
//       index: index,
//       key: key,
//       series: series,
//       isLeaf: isLeaf,
//       isOuterMostRing: isOuterMostRing,
//     );
//   }
// }
