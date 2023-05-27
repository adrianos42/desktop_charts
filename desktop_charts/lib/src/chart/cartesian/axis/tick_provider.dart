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

import '../../../text_element.dart';
import '../../chart_context.dart' show ChartContext;
import 'draw_strategy/tick_draw_strategy.dart' show TickDrawStrategy;
import 'scale.dart' show MutableScale;
import 'tick.dart' show Tick;
import 'tick_formatter.dart' show TickFormatter;

/// A strategy for selecting values for axis ticks based on the domain values.
///
/// [D] is the domain type.
abstract class TickProvider<D> {
  const TickProvider();

  /// Returns a list of ticks in value order that should be displayed.
  ///
  /// If no ticks are desired an empty list should be returned.
  ///
  /// [scale] The scale of the data.
  /// [formatter] The formatter to use for generating tick labels.
  /// [orientation] Orientation of this axis ticks.
  /// [tickDrawStrategy] Draw strategy for ticks.
  /// [viewportExtensionEnabled] allow extending the viewport for 'niced' ticks.
  /// [tickHint] tick values for provider to calculate a desired tick range.
  List<Tick<D>> getTicks({
    required ChartContext? context,
    required covariant MutableScale<D> scale,
    required TickFormatter<D> formatter,
    required Map<D, String> formatterValueCache,
    required TickDrawStrategy<D> tickDrawStrategy,
    required AxisDirection? orientation,
    bool viewportExtensionEnabled = false,
    TickHint<D>? tickHint,
  });
}

/// A base tick provider.
abstract class BaseTickProvider<D> implements TickProvider<D> {
  const BaseTickProvider();

  /// Create ticks from [domainValues].
  List<Tick<D>> createTicks(
    List<D> domainValues, {
    required ChartContext? context,
    required MutableScale<D> scale,
    required TickFormatter<D> formatter,
    required Map<D, String> formatterValueCache,
    required TickDrawStrategy<D> tickDrawStrategy,
    double? stepSize,
  }) {
    final ticks = <Tick<D>>[];
    final labels =
        formatter.format(domainValues, formatterValueCache, stepSize: stepSize);

    for (int i = 0; i < domainValues.length; i += 1) {
      final value = domainValues[i];
      final tick = Tick(
        value: value,
        textElement: TextElement(labels[i]),
        location: scale[value]?.toDouble(),
      );

      ticks.add(tick);
    }

    // Allow draw strategy to decorate the ticks.
    tickDrawStrategy.decorateTicks(ticks);

    return ticks;
  }
}

/// A hint for the tick provider to determine step size and tick count.
@immutable
class TickHint<D> {
  const TickHint(
    this.start,
    this.end, {
    required this.tickCount,
  });

  /// The starting hint tick value.
  final D start;

  /// The ending hint tick value.
  final D end;

  /// Number of ticks.
  final int tickCount;
}
