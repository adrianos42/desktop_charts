// // Copyright (C) 2023 Adriano Souza (adriano.souza113@gmail.com)

// // Copyright 2019 the Charts project authors. Please see the AUTHORS file
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

// import '../../data/tree.dart';
// import '../base_chart.dart' show BaseChart;
// import 'base_treemap_renderer.dart';
// import 'treemap_renderer_config.dart';

// /// A treemap renderer that renders a treemap with dice layout.
// class DiceTreeMapRenderer<D, S extends BaseChart<D>>
//     extends BaseTreeMapRenderer<D, S> {
//   DiceTreeMapRenderer(
//       {String? rendererId,
//       TreeMapRendererConfig<D>? config,
//       required super.chartState,
//       required super.seriesList})
//       : super(
//           config: config ??
//               TreeMapRendererConfig(
//                 tileType: TreeMapTileType.dice,
//               ),
//           rendererId: rendererId ?? BaseTreeMapRenderer.defaultRendererId,
//         );

//   @override
//   void tile(TreeNode<Object> node) {
//     final children = node.children;
//     if (children.isNotEmpty) {
//       final rect = availableLayoutBoundingRect(node);
//       final measure = measureForTreeNode(node);
//       final scaleFactor =
//           measure == 0.0 ? 0.0 : areaForRectangle(rect) / measure;
//       scaleArea(children, scaleFactor);
//       position(children, rect, rect.height, areaForRectangle(rect));
//     }
//   }
// }
