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

import 'dart:math' show pi;

import 'package:flutter/widgets.dart';

import '../../data/tree.dart' show TreeNode;
import '../base_chart.dart' show BaseChart, BaseChartState;
import '../pie/arc_renderer.dart' show ArcRenderer;
import '../pie/base_arc_renderer_config.dart' show BaseArcRendererConfig;
import '../processed_series.dart' show MutableSeries;
import '../series_renderer_config.dart' show BaseSeriesRenderObjectWidget;
import 'sunburst_arc_renderer.dart' show SunburstArcRenderer;

/// Given the selected node and a list of currently expanded node, returns the
/// set of node to be expanded (shown beyond the initialDisplayLevel).
typedef ExpandNodeCallback = List<TreeNode<dynamic>> Function(
    TreeNode<dynamic> node, List<TreeNode<dynamic>> expandedNode);

/// Configuration for an [ArcRenderer].
@immutable
class SunburstArcRendererConfig<D> extends BaseArcRendererConfig<D> {
  SunburstArcRendererConfig({
    this.arcRatios,
    this.arcWidths,
    this.colorAssignmentStrategy = SunburstColorStrategy.newShadePerLevel,
    this.maxDisplayLevel = _maxInt32Value,
    this.initialDisplayLevel = _maxInt32Value,
    super.customRendererId,
    super.arcLength = 2 * pi,
    super.arcRatio,
    super.arcWidth,
    super.minHoleWidthForCenterContent = 30,
    super.startAngle = -pi / 2,
    super.strokeWidth = 2.0,
    super.arcRendererDecorators = const [],
    super.symbolRenderer,
  });

  static const _maxInt32Value = 1 << 31;

  /// Ratio of the arc widths for each of the ring drawn in the sunburst. The
  /// arc ratio of each ring will be normalized based on the actual render area
  /// of the chart. If the maxDisplayLevel to be rendered is greater than the
  /// arcRatios provided, the last value of the arcRatios will be used to fill
  /// the rest of the levels. If neither arcRatios nor arcWidths is provided,
  /// space will be distributed evenly between levels.
  final List<double>? arcRatios;

  /// Fixed width of the arcs for each of the ring drawn in the sunburst. The
  /// arcs will be drawn exactly as the defined width, any part exceeding the
  /// chart area will not be drawn. If the maxDisplayLevel to be rendered is
  /// greater than the arcWidths provided, the last value of the arcWidths will
  /// be used to fill the rest of the levels. arcWidths has more precedence than
  /// arcRatios. If neither arcRatios nor arcWidths is provided, space will be
  /// distributed evenly between levels.
  final List<double>? arcWidths;

  /// Configures how missing colors are assigned for the Sunburst.
  final SunburstColorStrategy colorAssignmentStrategy;

  /// The initial display level of rings to render in the sunburst. Children
  /// of hovered/selected node may expand up to the maxDisplayLevel. If unset,
  /// defaults to maxDisplayLevel.
  final int initialDisplayLevel;

  /// The max level of rings to render in the sunburst. If unset, display all
  /// data.
  final int maxDisplayLevel;

  @override
  Widget build<S extends BaseChart<D>>(
    BuildContext context, {
    required Key key,
    required BaseChartState<D, S> chartState,
    required List<MutableSeries<D>> seriesList,
    String? rendererId,
  }) {
    return _SunburstRenderObjectWidget(
      chartState: chartState,
      config: this,
      key: key,
      seriesList: seriesList,
      rendererId: rendererId,
    );
  }
}

/// Strategies for assigning color to the arcs if colorFn is not provided for
/// Series.
enum SunburstColorStrategy {
  /// Assign a shade to each of the arcs.
  newShadePerArc,

  /// Assign a shade to each ring of the sunburst.
  newShadePerLevel,
}

class _SunburstRenderObjectWidget<D, S extends BaseChart<D>>
    extends BaseSeriesRenderObjectWidget<D, S, SunburstArcRenderer<D, S>,
        SunburstArcRendererConfig<D>> {
  const _SunburstRenderObjectWidget({
    required super.chartState,
    required super.config,
    required super.key,
    required super.rendererId,
    required super.seriesList,
  });

  @override
  SunburstArcRenderer<D, S> createRenderObject(BuildContext context) =>
      SunburstArcRenderer<D, S>(
        rendererId: rendererId,
        config: config,
        chartState: chartState,
        seriesList: seriesList,
      );
}
