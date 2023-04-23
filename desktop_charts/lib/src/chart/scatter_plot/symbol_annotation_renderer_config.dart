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

import '../../symbol_renderer.dart';
import '../base_chart.dart';
import 'comparison_points_decorator.dart' show ComparisonPointsDecorator;
import 'point_renderer_config.dart' show PointRendererConfig;
import 'point_renderer_decorator.dart' show PointRendererDecorator;
import 'symbol_annotation_renderer.dart' show SymbolAnnotationRenderer;

/// Configuration for [SymbolAnnotationRenderer].
///
/// This renderer is configured with a [ComparisonPointsDecorator] by default,
/// used to draw domain ranges. This decorator will draw a rectangular shape
/// between the points (domainLowerBound, measureLowerBound) and
/// (domainUpperBound, measureUpperBound), beneath the primary point for each
/// series.
class SymbolAnnotationRendererConfig<D> extends PointRendererConfig<D> {
  SymbolAnnotationRendererConfig({
    String? customRendererId,
    List<PointRendererDecorator<D>>? pointRendererDecorators,
    double radius = 5.0,
    SymbolRenderer? symbolRenderer,
    Map<String, SymbolRenderer>? customSymbolRenderers,
    this.showBottomSeparatorLine = false,
    this.showSeparatorLines = true,
    this.verticalSymbolBottomPadding = 5.0,
    this.verticalSymbolTopPadding = 5.0,
  }) : super(
            customRendererId: customRendererId,
            pointRendererDecorators: pointRendererDecorators ??
                [
                  ComparisonPointsDecorator<D>(
                    symbolRenderer: const RectangleRangeSymbolRenderer(),
                  )
                ],
            radius: radius,
            symbolRenderer: symbolRenderer,
            customSymbolRenderers: customSymbolRenderers);

  /// Whether a separator line should be drawn between the bottom row of
  /// rendered symbols and the axis ticks/labels.
  final bool showBottomSeparatorLine;

  /// Whether or not separator lines will be rendered between rows of rendered
  /// symbols.
  final bool showSeparatorLines;

  /// Space reserved at the bottom of each row where the symbol should not
  /// render into.
  final double verticalSymbolBottomPadding;

  /// Space reserved at the top of each row where the symbol should not render
  /// into.
  final double verticalSymbolTopPadding;

  @override
  SymbolAnnotationRenderer<D, S> build<S extends BaseChart<D>>({
    required BaseChartState<D, S> chartState,
    String? rendererId,
  }) {
    return SymbolAnnotationRenderer(
      chartState: chartState,
      rendererId: rendererId,
      config: this,
    );
  }

  @override
  bool operator ==(covariant SymbolAnnotationRendererConfig<D> other) {
    if (identical(this, other)) {
      return true;
    }
    return other.showBottomSeparatorLine == showBottomSeparatorLine &&
        other.showSeparatorLines == showSeparatorLines &&
        other.verticalSymbolBottomPadding == verticalSymbolBottomPadding &&
        other.verticalSymbolTopPadding == verticalSymbolTopPadding &&
        other.customRendererId == customRendererId &&
        other.layoutPaintOrder == layoutPaintOrder &&
        other.pointRendererDecorators == pointRendererDecorators &&
        other.symbolRenderer == symbolRenderer &&
        other.customSymbolRenderers == customSymbolRenderers &&
        other.radius == radius &&
        other.strokeWidth == strokeWidth &&
        other.boundsLineRadius == boundsLineRadius;
  }

  @override
  int get hashCode => Object.hash(
        showBottomSeparatorLine,
        showSeparatorLines,
        verticalSymbolBottomPadding,
        verticalSymbolTopPadding,
        customRendererId,
        layoutPaintOrder,
        pointRendererDecorators,
        symbolRenderer,
        customSymbolRenderers,
        radius,
        strokeWidth,
        boundsLineRadius,
      );
}