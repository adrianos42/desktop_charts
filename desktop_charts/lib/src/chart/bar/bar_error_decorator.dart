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

import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import '../../theme.dart';
import '../chart_canvas.dart' show ChartCanvas;
import 'bar_renderer.dart' show ImmutableBarRendererElement;
import 'bar_renderer_decorator.dart' show BarRendererDecorator;

/// Decorates bars with error whiskers.
///
/// Used to represent confidence intervals for bar charts.
@immutable
class BarErrorDecorator<D> extends BarRendererDecorator<D> {
  const BarErrorDecorator({
    this.strokeWidth = _defaultStrokeWidth,
    this.endpointLength = _defaultEndpointLength,
    this.outlineWidth = _defaultOutlineWidth,
  });

  static const double _defaultStrokeWidth = 1.0;
  static const double _defaultEndpointLength = 16;

  static const double _defaultOutlineWidth = 0.0;

  final double strokeWidth;
  final double endpointLength;
  final double outlineWidth;

  @override
  void decorate(
    Iterable<ImmutableBarRendererElement<D>> barElements,
    Canvas canvas, {
    required Rect drawBounds,
    required double animationPercent,
    required bool renderingVertically,
    bool rtl = false,
  }) {
    // Only decorate the bars when animation is at 100%.
    if (animationPercent != 1.0) {
      return;
    }

    final Color strokeColor = const ChartsThemeData.fallbackw().foreground;
    final Color outlineColor = const ChartsThemeData.fallbackw().background;

    for (final element in barElements) {
      final bounds = element.bounds!;
      final datumIndex = element.index;

      final series = element.series!;

      final measureLowerBoundFn = series.measureLowerBoundFn;
      final measureUpperBoundFn = series.measureUpperBoundFn;

      if (measureLowerBoundFn != null && measureUpperBoundFn != null) {
        final measureOffsetFn = series.measureOffsetFn!;
        final measureAxis = null; // TODO
        // (chartState as CartesianChartState<D, CartesianChart<D>>)
        //     .getMeasureAxis();

        if (renderingVertically) {
          final startY = measureAxis!.getLocation(
            ((measureLowerBoundFn(datumIndex) ?? 0) +
                    measureOffsetFn(datumIndex)!)
                .toDouble(),
          )!;
          final endY = measureAxis.getLocation(
            ((measureUpperBoundFn(datumIndex) ?? 0) +
                    measureOffsetFn(datumIndex)!)
                .toDouble(),
          )!;

          if (startY != endY) {
            final barWidth = bounds.right - bounds.left;
            final x = (bounds.left + bounds.right) / 2.0;
            final rectWidth =
                min(strokeWidth + 2.0 * outlineWidth, barWidth.toDouble());
            final strokeWid = rectWidth - 2.0 * outlineWidth;
            final rectEndpointLength =
                min(endpointLength + 2.0 * outlineWidth, barWidth.toDouble());
            final endpointLen = rectEndpointLength - 2.0 * outlineWidth;

            if (outlineWidth > 0) {
              // Draw rectangle rendering the outline for the vertical line.
              canvas.drawChartRect(
                Rect.fromPoints(Offset(x - rectWidth / 2.0, startY),
                    Offset(x + rectWidth / 2.0, endY)),
                fill: outlineColor,
                strokeWidth: outlineWidth,
                background: const Color(0xff000000), // TODO
              );

              // Draw rectangle rendering the outline for the horizontal
              // endpoint representing the lower bound.
              canvas.drawChartRect(
                Rect.fromLTWH(
                  x - rectEndpointLength / 2.0,
                  startY - rectWidth / 2.0,
                  rectEndpointLength,
                  rectWidth,
                ),
                fill: outlineColor,
                strokeWidth: outlineWidth,
                background: const Color(0xff000000), // TODO
              );

              // Draw rectangle rendering the outline for the horizontal
              // endpoint representing the upper bound.
              canvas.drawChartRect(
                Rect.fromLTWH(
                  x - rectEndpointLength / 2.0,
                  endY - rectWidth / 2.0,
                  rectEndpointLength,
                  rectWidth,
                ),
                fill: outlineColor,
                strokeWidth: outlineWidth,
                background: const Color(0xff000000), // TODO
              );
            }

            // Draw vertical whisker line.
            canvas.drawChartLine(
              points: [Offset(x, startY), Offset(x, endY)],
              stroke: strokeColor,
              strokeWidth: strokeWid,
            );

            // Draw horizontal whisker line for the lower bound.
            canvas.drawChartLine(
              points: [
                Offset(x - endpointLen / 2.0, startY),
                Offset(x + endpointLen / 2.0, startY)
              ],
              stroke: strokeColor,
              strokeWidth: strokeWid,
            );

            // Draw horizontal whisker line for the upper bound.
            canvas.drawChartLine(
              points: [
                Offset(x - endpointLen / 2.0, endY),
                Offset(x + endpointLen / 2.0, endY)
              ],
              stroke: strokeColor,
              strokeWidth: strokeWid,
            );
          }
        } else {
          final startX = measureAxis!.getLocation(
            ((measureLowerBoundFn(datumIndex) ?? 0) +
                    measureOffsetFn(datumIndex)!)
                .toDouble(),
          )!;
          final endX = measureAxis.getLocation(
            ((measureUpperBoundFn(datumIndex) ?? 0) +
                    measureOffsetFn(datumIndex)!)
                .toDouble(),
          )!;

          if (startX != endX) {
            final barWidth = bounds.bottom - bounds.top;
            final y = (bounds.top + bounds.bottom) / 2.0;
            final rectWidth =
                min(strokeWidth + 2.0 * outlineWidth, barWidth.toDouble());
            final strokeWid = rectWidth - 2.0 * outlineWidth;
            final rectEndpointLength =
                min(endpointLength + 2.0 * outlineWidth, barWidth.toDouble());
            final endpointLen = rectEndpointLength - 2.0 * outlineWidth;

            if (outlineWidth > 0.0) {
              // Draw rectangle rendering the outline for the horizontal line.
              canvas.drawChartRect(
                Rect.fromPoints(Offset(startX, y - rectWidth / 2.0),
                    Offset(endX, y + rectWidth / 2.0)),
                fill: outlineColor,
                strokeWidth: outlineWidth,
                background: const Color(0xff000000), // TODO
              );

              // Draw rectangle rendering the outline for the vertical
              // endpoint representing the lower bound.
              canvas.drawChartRect(
                Rect.fromLTWH(
                  startX - rectWidth / 2.0,
                  y - rectEndpointLength / 2.0,
                  rectWidth,
                  rectEndpointLength,
                ),
                fill: outlineColor,
                strokeWidth: outlineWidth,
                background: const Color(0xff000000), // TODO
              );

              // Draw rectangle rendering the outline for the vertical
              // endpoint representing the upper bound.
              canvas.drawChartRect(
                Rect.fromLTWH(
                  endX - rectWidth / 2.0,
                  y - rectEndpointLength / 2.0,
                  rectWidth,
                  rectEndpointLength,
                ),
                fill: outlineColor,
                strokeWidth: outlineWidth,
                background: const Color(0xff000000), // TODO
              );
            }

            // Draw horizontal whisker line.
            canvas.drawChartLine(
              points: [Offset(startX, y), Offset(endX, y)],
              stroke: strokeColor,
              strokeWidth: strokeWid,
            );

            // Draw vertical whisker line for the lower bound.
            canvas.drawChartLine(
              points: [
                Offset(startX, y - endpointLen / 2.0),
                Offset(startX, y + endpointLen / 2.0)
              ],
              stroke: strokeColor,
              strokeWidth: strokeWid,
            );

            // Draw vertical whisker line for the upper bound.
            canvas.drawChartLine(
              points: [
                Offset(endX, y - endpointLen / 2.0),
                Offset(endX, y + endpointLen / 2.0)
              ],
              stroke: strokeColor,
              strokeWidth: strokeWid,
            );
          }
        }
      }
    }
  }
}
