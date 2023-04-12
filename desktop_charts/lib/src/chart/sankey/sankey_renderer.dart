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

import 'package:flutter/widgets.dart';

import '../../math.dart' show NullablePoint;
import '../base_chart.dart' show BaseChart;
import '../datum_details.dart';
import '../series_datum.dart';
import '../series_renderer.dart';
import 'sankey_renderer_config.dart';

/// Sankey Renderer for the Sankey Chart using Graph data structure
class SankeyRenderer<D, S extends BaseChart<D>>
    extends BaseSeriesRenderer<D, S> {
  SankeyRenderer({
    String? rendererId,
    SankeyRendererConfig<D>? config,
    required super.chartState,
    required super.seriesList,
  })  : config = config ?? SankeyRendererConfig(),
        super(
          rendererId: rendererId ?? defaultRendererID,
          symbolRenderer: (config ?? SankeyRendererConfig()).symbolRenderer,
        );

  /// Default renderer ID for the Sankey Chart
  static const defaultRendererID = 'sankey';

  /// Sankey Renderer Config
  final SankeyRendererConfig<D> config;

  @override
  void preprocessSeries() {
    // TODO Populate renderer elements.
  }

  @override
  void update() {
    super.update();
    
    // TODO Calculate node and link renderer element positions.
  }

  @override
  void paint(
    PaintingContext context,
    Offset offset,
  ) {
    super.paint(context, offset);

    // TODO Paint the renderer elements on the canvas.
  }

  @override
  DatumDetails<D> addPositionToDetailsForSeriesDatum(
      DatumDetails<D> details, SeriesDatum<D> seriesDatum) {
    const chartPosition = Offset(0, 0);
    return DatumDetails.from(details,
        chartPosition: NullablePoint.from(chartPosition));
  }

  /// Datum details of nearest links or nodes in the sankey chart.
  @override
  List<DatumDetails<D>> getNearestDatumDetailPerSeries(
    Offset globalPosition,
    bool byDomain,
    Rect? boundsOverride, {
    bool selectOverlappingPoints = false,
    bool selectExactEventLocation = false,
  }) {
    return <DatumDetails<D>>[];
  }
}
