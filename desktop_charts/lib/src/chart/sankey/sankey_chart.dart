// Copyright (C) 2023 Adriano Souza (adriano.souza113@gmail.com)

// Copyright 2021 the Charts project authors. Please see the AUTHORS file
// for details.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import '../base_chart.dart';
import '../datum_details.dart';
import '../layout/layout_config.dart';
import '../sankey/sankey_renderer.dart';
import '../selection_model.dart';
import '../series_renderer.dart';

// class SankeyChart<D> extends BaseChart<D> {
//   SankeyChart({
//     LayoutConfig? layoutConfig,
//   }) : super(layoutConfig: layoutConfig ?? LayoutConfig());

//   /// Uses SankeyRenderer as the default renderer.
//   @override
//   SeriesRenderer<D> makeDefaultRenderer() {
//     return SankeyRenderer<D>()
//       ..rendererId = SeriesRenderer.defaultRendererId;
//   }

//   /// Returns a list of datum details from the selection model of [type].
//   @override
//   List<DatumDetails<D>> getDatumDetails(SelectionModelType type) {
//     return <DatumDetails<D>>[];
//   }
// }