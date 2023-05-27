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

import '../../../../theme.dart';
import '../../../chart_context.dart' show ChartContext;
import '../auto_adjusting_static_tick_provider.dart'
    show AutoAdjustingStaticTickProvider;
import '../axis.dart' show OrdinalAxis, OrdinalViewport;
import '../draw_strategy/tick_draw_strategy.dart' show TickDrawStrategy;
import '../ordinal_scale.dart' show OrdinalScale;
import '../ordinal_tick_provider.dart' show OrdinalTickProvider;
import '../range_tick_provider.dart' show RangeTickProvider;
import '../scale.dart' show RangeBandConfig;
import '../simple_ordinal_scale.dart' show SimpleOrdinalScale;
import '../static_tick_provider.dart' show StaticTickProvider;
import '../tick_formatter.dart' show OrdinalTickFormatter;
import 'axis_spec.dart'
    show AxisSpec, TickProviderSpec, TickFormatterSpec, ScaleSpec;
import 'tick_spec.dart' show TickSpec;

/// [AxisSpec] specialized for ordinal/non-continuous axes typically for bars.
@immutable
class OrdinalAxisSpec extends AxisSpec<String> {
  /// Creates a [AxisSpec] that specialized for ordinal domain charts.
  ///
  /// [renderSpec] spec used to configure how the ticks and labels
  ///     actually render. Possible values are [GridlineRendererSpec],
  ///     [SmallTickRendererSpec] & [NoneRenderSpec]. Make sure that the <D>
  ///     given to the RenderSpec is of type [String] when using this spec.
  /// [tickProviderSpec] spec used to configure what ticks are generated.
  /// [tickFormatterSpec] spec used to configure how the tick labels are
  ///     formatted.
  /// [showAxisLine] override to force the axis to draw the axis line.
  const OrdinalAxisSpec({
    this.viewport,
    super.renderSpec,
    super.tickProviderSpec,
    super.tickFormatterSpec,
    super.showAxisLine,
    super.scaleSpec,
  });

  /// Sets viewport for this Axis.
  ///
  /// If pan / zoom behaviors are set, this is the initial viewport.
  final OrdinalViewport? viewport;

  @override
  OrdinalAxis createAxis({
    required ChartContext chartContext,
    required TickDrawStrategy<String> tickDrawStrategy,
    required AxisDirection axisDirection,
    required bool reverseOutputRange,
  }) =>
      OrdinalAxis(
        chartContext: chartContext,
        tickDrawStrategy: tickDrawStrategy,
        axisSpec: this,
        axisDirection: axisDirection,
        reverseOutputRange: reverseOutputRange,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is OrdinalAxisSpec &&
            viewport == other.viewport &&
            super == other);
  }

  @override
  int get hashCode => Object.hash(super.hashCode, viewport);
}

abstract class OrdinalTickProviderSpec extends TickProviderSpec<String> {}

abstract class OrdinalTickFormatterSpec extends TickFormatterSpec<String> {}

abstract class OrdinalScaleSpec extends ScaleSpec<String> {}

@immutable
class BasicOrdinalTickProviderSpec implements OrdinalTickProviderSpec {
  const BasicOrdinalTickProviderSpec();

  @override
  OrdinalTickProvider createTickProvider(ChartContext context) =>
      const OrdinalTickProvider();

  @override
  bool operator ==(Object other) => other is BasicOrdinalTickProviderSpec;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// [TickProviderSpec] that allows you to specify the ticks to be used.
@immutable
class StaticOrdinalTickProviderSpec implements OrdinalTickProviderSpec {
  const StaticOrdinalTickProviderSpec(this.tickSpecs);

  final List<TickSpec<String>> tickSpecs;

  @override
  StaticTickProvider<String> createTickProvider(ChartContext context) =>
      StaticTickProvider<String>(tickSpecs);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StaticOrdinalTickProviderSpec && tickSpecs == other.tickSpecs);

  @override
  int get hashCode => tickSpecs.hashCode;
}

/// [TickProviderSpec] that tries different tick increments to avoid tick
/// collisions.
@immutable
class AutoAdjustingStaticOrdinalTickProviderSpec
    implements OrdinalTickProviderSpec {
  const AutoAdjustingStaticOrdinalTickProviderSpec(
    this.tickSpecs,
    this.allowedTickIncrements,
  );

  final List<TickSpec<String>> tickSpecs;
  final List<int> allowedTickIncrements;

  @override
  AutoAdjustingStaticTickProvider<String> createTickProvider(
    ChartContext context,
  ) =>
      AutoAdjustingStaticTickProvider<String>(tickSpecs, allowedTickIncrements);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AutoAdjustingStaticOrdinalTickProviderSpec &&
          tickSpecs == other.tickSpecs);

  @override
  int get hashCode => tickSpecs.hashCode;
}

/// [TickProviderSpec] that allows you to provide range ticks and normal ticks.
@immutable
class RangeOrdinalTickProviderSpec implements OrdinalTickProviderSpec {
  const RangeOrdinalTickProviderSpec(this.tickSpecs);

  final List<TickSpec<String>> tickSpecs;

  @override
  RangeTickProvider<String> createTickProvider(ChartContext context) =>
      RangeTickProvider<String>(tickSpecs);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RangeOrdinalTickProviderSpec && tickSpecs == other.tickSpecs);

  @override
  int get hashCode => tickSpecs.hashCode;
}

@immutable
class BasicOrdinalTickFormatterSpec implements OrdinalTickFormatterSpec {
  const BasicOrdinalTickFormatterSpec();

  @override
  OrdinalTickFormatter createTickFormatter(ChartContext context) =>
      const OrdinalTickFormatter();

  @override
  bool operator ==(Object other) => other is BasicOrdinalTickFormatterSpec;

  @override
  int get hashCode => runtimeType.hashCode;
}

@immutable
class SimpleOrdinalScaleSpec implements OrdinalScaleSpec {
  const SimpleOrdinalScaleSpec();

  @override
  OrdinalScale createScale(ChartsThemeData themeData) =>
      SimpleOrdinalScale(themeData);

  @override
  bool operator ==(Object other) => other is SimpleOrdinalScaleSpec;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// [OrdinalScaleSpec] which allows setting space between bars to be a fixed size.
@immutable
class FixedSpaceOrdinalScaleSpec implements OrdinalScaleSpec {
  const FixedSpaceOrdinalScaleSpec(this.spaceBetweenBars);

  final double spaceBetweenBars;

  @override
  OrdinalScale createScale(ChartsThemeData themeData) =>
      SimpleOrdinalScale(themeData)
        ..rangeBandConfig =
            RangeBandConfig.fixedSpaceBetweenStep(spaceBetweenBars);

  @override
  bool operator ==(Object other) => other is SimpleOrdinalScaleSpec;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// [OrdinalScaleSpec] which allows setting bar width to be a fixed size.
@immutable
class FixedOrdinalScaleSpec implements OrdinalScaleSpec {
  const FixedOrdinalScaleSpec(this.value);

  final double value;

  @override
  OrdinalScale createScale(ChartsThemeData themeData) =>
      SimpleOrdinalScale(themeData)
        ..rangeBandConfig = RangeBandConfig.fixed(value);

  @override
  bool operator ==(Object other) => other is SimpleOrdinalScaleSpec;

  @override
  int get hashCode => runtimeType.hashCode;
}
