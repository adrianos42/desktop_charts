// Copyright (C) 2023 Adriano Souza (adriano.souza113@gmail.com)

// Copyright 2018 the Charts project authors. Please see the AUTHORS file
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

import 'package:flutter/widgets.dart';

import '../base_chart.dart';
import '../datum_details.dart' show DatumDetails;
import '../selection_model.dart' show SelectionModelType;
import '../selection_model_config.dart' show SelectionModelConfig;
import '../series_renderer.dart' show rendererIdKey;
import 'arc_renderer.dart' show ArcRenderer;
import 'arc_renderer_config.dart';

@immutable
class PieChart<D> extends BaseChart<D> {
  PieChart(
    super.seriesList, {
    super.animate,
    super.animationDuration = const Duration(milliseconds: 400),
    ArcRendererConfig<D>? defaultRenderer,
    // List<dynamic>? behaviors,
    super.rtlSpec,
    super.defaultInteractions = true,
    List<SelectionModelConfig<D>>? selectionModels,
    super.key,
    super.behaviors,
  }) : super(defaultRenderer: defaultRenderer ?? ArcRendererConfig());

  @override
  PieChartState<D> createState() => PieChartState<D>();
}

//typedef _ArcRendererState<D>
//    = ArcRendererState<D, PieChart<D>, ArcRenderer<D, PieChart<D>>>;

class PieChartState<D> extends BaseChartState<D, PieChart<D>> {
  /// Returns a list of datum details from selection model of [type].
  @override
  List<DatumDetails<D>> getDatumDetails(SelectionModelType type) {
    final entries = <DatumDetails<D>>[];

    for (final seriesDatum in getSelectionModel(type).selectedDatum) {
      final rendererId = seriesDatum.series.getAttr(rendererIdKey);
      final renderer =
          getSeriesRenderer(rendererId) as ArcRenderer<D, PieChart<D>>?;

      final details = renderer!.getExpandedDatumDetails(seriesDatum);

      entries.add(details);
    }

    return entries;
  }
}
