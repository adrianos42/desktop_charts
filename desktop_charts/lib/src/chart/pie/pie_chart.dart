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
import '../behavior/behavior.dart' show ChartBehavior, DomainHighlighter;
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
    ArcRendererConfig<D>? defaultRenderer,
    List<SelectionModelConfig<D>>? selectionModels,
    super.animationDuration,
    super.defaultInteractions = true,
    super.animate,
    super.rtlSpec,
    super.behaviors,
    super.key,
  }) : super(defaultRenderer: defaultRenderer ?? ArcRendererConfig<D>());

  @override
  PieChartState<D> createState() => PieChartState<D>();
}

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

  @override
  void addDefaultInteractions(List<ChartBehavior> behaviors) {
    super.addDefaultInteractions(behaviors);

    behaviors.add(DomainHighlighter<D>());
  }
}
