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

import '../../data/series.dart' show AttributeKey;
import '../../math.dart' show NullablePoint;
import '../base_chart.dart' show BaseChart;
import '../chart_canvas.dart';
import '../datum_details.dart';
import '../processed_series.dart' show MutableSeries, ImmutableSeries;
import '../series_datum.dart';
import '../series_renderer.dart' show BaseSeriesRenderer;
import 'link_renderer_config.dart';

const linkElementsKey =
    AttributeKey<List<LinkRendererElement>>('LinkRenderer.elements');

class LinkRenderer<D, S extends BaseChart<D>> extends BaseSeriesRenderer<D, S> {
  LinkRenderer({
    String? rendererId,
    LinkRendererConfig<D>? config,
    required super.chartState,
  })  : config = config ?? LinkRendererConfig(),
        super(
          rendererId: rendererId ?? defaultRendererID,
          //config: config ?? LinkRendererConfig(),
          symbolRenderer: (config ?? LinkRendererConfig()).symbolRenderer,
        );

  /// Default renderer ID for the Sankey Chart
  static const defaultRendererID = 'sankey';

  /// Link Renderer Config
  final LinkRendererConfig<D> config;

  // List of renderer elements to be drawn on the canvas
  final _seriesLinkMap = <String, List<LinkRendererElement>>{};

  @override
  void preprocessSeries(List<MutableSeries<D>> seriesList) {
    for (final series in seriesList) {
      final elements = <LinkRendererElement>[];
      for (int linkIndex = 0; linkIndex < series.data.length; linkIndex += 1) {
        final element = LinkRendererElement(
            series.data[linkIndex].link,
            series.data[linkIndex].orientation,
            series.data[linkIndex].fillColor);
        elements.add(element);
      }
      series.setAttr(linkElementsKey, elements);
    }
  }

  @override
  void update(List<MutableSeries<D>> seriesList) {
    super.update(seriesList);

    for (final series in seriesList) {
      final elementsList = series.getAttr(linkElementsKey);
      _seriesLinkMap.putIfAbsent(series.id, () => elementsList!);
    }
  }

  @override
  void draw(PaintingContext context, Offset offset) {
    // super.draw(context, offset);

    /// Paint the renderer elements on the canvas using drawLink.
    _seriesLinkMap.forEach((k, v) => _drawAllLinks(v, context.canvas));
  }

  void _drawAllLinks(List<LinkRendererElement> links, Canvas canvas) {
    for (final element in links) {
      canvas.drawChartLink(
          element.link, element.orientation, element.fillColor);
    }
  }

  @override
  DatumDetails<D> addPositionToDetailsForSeriesDatum(
      DatumDetails<D> details, SeriesDatum<D> seriesDatum) {
    const chartPosition = Offset(0.0, 0.0);
    return DatumDetails.from(
      details,
      chartPosition: NullablePoint.from(chartPosition),
    );
  }

  @override
  Widget build(
    BuildContext context, {
    required Key key,
    required List<ImmutableSeries<D>> seriesList,
  }) {
    throw '';
  }

  /// Datum details of nearest link.
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

@immutable
class LinkRendererElement {
  const LinkRendererElement(this.link, this.orientation, this.fillColor);

  final Link link;
  final LinkOrientation orientation;
  final Color fillColor;
}
