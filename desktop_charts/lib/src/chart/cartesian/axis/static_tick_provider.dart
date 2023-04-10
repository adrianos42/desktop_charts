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
import 'numeric_scale.dart' show NumericScale;
import 'scale.dart' show MutableScale;
import 'spec/tick_spec.dart' show TickSpec;
import 'tick.dart' show Tick;
import 'tick_formatter.dart' show TickFormatter;
import 'tick_provider.dart' show TickProvider, TickHint;
import 'time/date_time_scale.dart' show DateTimeScale;

/// A strategy that uses the ticks provided and only assigns positioning.
///
/// The [TextStyle] is not overridden during [TickDrawStrategy.decorateTicks].
/// If the [TickSpec] style is null, then the default [TextStyle] is used.
///
/// Optionally the [tickIncrement] can be provided in which case every Nth tick
/// is selected.
@immutable
class StaticTickProvider<D> extends TickProvider<D> {
  const StaticTickProvider(this.tickSpec, {this.tickIncrement = 1});

  final List<TickSpec<D>> tickSpec;
  final int tickIncrement;

  @override
  List<Tick<D>> getTicks({
    required ChartContext? context,
    required MutableScale<D> scale,
    required TickFormatter<D> formatter,
    required Map<D, String> formatterValueCache,
    required TickDrawStrategy<D> tickDrawStrategy,
    required AxisDirection? orientation,
    bool viewportExtensionEnabled = false,
    TickHint<D>? tickHint,
  }) {
    final ticks = <Tick<D>>[];

    bool allTicksHaveLabels = true;

    for (final spec in tickSpec) {
      // When static ticks are being used with a numeric axis, extend the axis
      // with the values specified.
      if (scale is NumericScale || scale is DateTimeScale) {
        scale.addDomain(spec.value);
      }

      // Save off whether all ticks have labels.
      allTicksHaveLabels = allTicksHaveLabels && (spec.label != null);
    }

    // Use the formatter's label if the tick spec does not provide one.
    late List<String> formattedValues;
    if (!allTicksHaveLabels) {
      formattedValues = formatter.format(
          tickSpec.map((spec) => spec.value).toList(), formatterValueCache,
          stepSize: scale.domainStepSize);
    }

    for (int i = 0; i < tickSpec.length; i += tickIncrement) {
      final spec = tickSpec[i];
      // We still check if the spec is within the viewport because we do not
      // extend the axis for OrdinalScale.
      if (scale.compareDomainValueToViewport(spec.value) == 0) {
        final tick = Tick<D>(
          value: spec.value,
          textElement: TextElement(spec.label ?? formattedValues[i]),
          location: scale[spec.value]?.toDouble(),
        );
        final style = spec.style;
        if (style != null) {
          tick.textElement!.textStyle = style;
        }
        ticks.add(tick);
      }
    }

    // Allow draw strategy to decorate the ticks.
    tickDrawStrategy.decorateTicks(ticks);

    return ticks;
  }

  @override
  bool operator ==(Object other) =>
      other is StaticTickProvider && tickSpec == other.tickSpec;

  @override
  int get hashCode => tickSpec.hashCode;
}
