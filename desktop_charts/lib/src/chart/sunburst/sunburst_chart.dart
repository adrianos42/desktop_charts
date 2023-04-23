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

// import 'package:flutter/widgets.dart';

// import '../../data/tree.dart' show TreeNode;
// import '../base_chart.dart' show BaseChartState, BaseChart;
// import '../datum_details.dart' show DatumDetails;
// import '../selection_model.dart' show SelectionModelType;
// import '../series_renderer.dart' show rendererIdKey;
// import 'sunburst_arc_renderer.dart';
// import 'sunburst_arc_renderer_config.dart';

// @immutable
// class SunburstChart<D> extends BaseChart<D> {
//   SunburstChart(
//     super.seriesList, {
//     SunburstArcRendererConfig<D>? defaultRenderer,
//     super.animate,
//     super.animationDuration,
//     super.behaviors,
//     super.customSeriesRenderers,
//     super.defaultInteractions,
//     super.key,
//     super.rtlSpec,
//     super.selectionModels,
//     super.userManagedState,
//   }): super(defaultRenderer: defaultRenderer ?? SunburstArcRendererConfig());

//   @override
//   SunburstChartState<D> createState() => SunburstChartState<D>();
// }

// class SunburstChartState<D> extends BaseChartState<D, SunburstChart<D>> {
//   /// Returns a list of datum details from selection model of [type].
//   @override
//   List<DatumDetails<D>> getDatumDetails(SelectionModelType type) {
//     final entries = <DatumDetails<D>>[];

//     for (final seriesDatum in getSelectionModel(type).selectedDatum) {
//       final rendererId = seriesDatum.series.getAttr(rendererIdKey);
//       final renderer = getSeriesRenderer(rendererId)
//           as SunburstArcRenderer<D, SunburstChart<D>>?;

//       final details = renderer!.getExpandedDatumDetails(seriesDatum);

//       entries.add(details);
//     }

//     return entries;
//   }

//   void expandNode(TreeNode<D> node) {
//     final rendererState =
//         defaultRenderer as SunburstArcRenderer<D, SunburstChart<D>>?;
//     rendererState!.expandNode(node);
//   }
// }
