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
import 'package:intl/intl.dart';

import '../../../chart_context.dart' show ChartContext;
import '../../../datum_details.dart' show MeasureFormatter;
import '../axis.dart' show NumericAxis;
import '../draw_strategy/tick_draw_strategy.dart' show TickDrawStrategy;
import '../end_points_tick_provider.dart' show EndPointsTickProvider;
import '../numeric_extents.dart' show NumericExtents;
import '../numeric_tick_provider.dart' show NumericTickProvider;
import '../static_tick_provider.dart' show StaticTickProvider;
import '../tick_formatter.dart';
import '../tick_formatter.dart' show NumericTickFormatter;
import 'axis_spec.dart'
    show
        AxisSpec,
        TickProviderSpec,
        TickFormatterSpec,
        RenderSpec,
        ScaleSpec;
import 'tick_spec.dart' show TickSpec;

/// [AxisSpec] specialized for numeric/continuous axes like the measure axis.
@immutable
class NumericAxisSpec extends AxisSpec<num> {
  /// Creates a [AxisSpec] that specialized for numeric data.
  ///
  /// [renderSpec] spec used to configure how the ticks and labels
  ///     actually render. Possible values are [GridlineRendererSpec],
  ///     [SmallTickRendererSpec] & [NoneRenderSpec]. Make sure that the <D>
  ///     given to the RenderSpec is of type [num] when using this spec.
  /// [tickProviderSpec] spec used to configure what ticks are generated.
  /// [tickFormatterSpec] spec used to configure how the tick labels are
  ///     formatted.
  /// [showAxisLine] override to force the axis to draw the axis line.
  const NumericAxisSpec({
    this.viewport,
    super.renderSpec,
    super.tickProviderSpec,
    super.tickFormatterSpec,
    super.showAxisLine,
    super.scaleSpec,
  });

  factory NumericAxisSpec.from(
    NumericAxisSpec other, {
    RenderSpec<num>? renderSpec,
    TickProviderSpec<num>? tickProviderSpec,
    TickFormatterSpec<num>? tickFormatterSpec,
    bool? showAxisLine,
    ScaleSpec<num>? scaleSpec,
    NumericExtents? viewport,
  }) {
    return NumericAxisSpec(
      renderSpec: renderSpec ?? other.renderSpec,
      tickProviderSpec: (tickProviderSpec ?? other.tickProviderSpec)
          as NumericTickProviderSpec?,
      tickFormatterSpec: (tickFormatterSpec ?? other.tickFormatterSpec)
          as NumericTickFormatterSpec?,
      showAxisLine: showAxisLine ?? other.showAxisLine,
      scaleSpec: scaleSpec ?? other.scaleSpec,
      viewport: viewport ?? other.viewport,
    );
  }

  /// Sets viewport for this Axis.
  ///
  /// If pan / zoom behaviors are set, this is the initial viewport.
  final NumericExtents? viewport;

  @override
  NumericAxis createAxis({
    required ChartContext chartContext,
    required TickDrawStrategy<num> tickDrawStrategy,
    required AxisDirection axisDirection,
    required bool reverseOutputRange,
  }) =>
      NumericAxis(
        chartContext: chartContext,
        tickDrawStrategy: tickDrawStrategy,
        axisSpec: this,
        axisDirection: axisDirection,
        reverseOutputRange: reverseOutputRange,
        // tickProvider: // TODO
      );

  @override
  bool operator ==(Object other) =>
      other is NumericAxisSpec && viewport == other.viewport && super == other;

  @override
  int get hashCode => Object.hash(super.hashCode, viewport);
}

abstract class NumericTickProviderSpec extends TickProviderSpec<num> {}

abstract class NumericTickFormatterSpec extends TickFormatterSpec<num> {}

@immutable
class BasicNumericTickProviderSpec implements NumericTickProviderSpec {
  /// Creates a [TickProviderSpec] that dynamically chooses the number of
  /// ticks based on the extents of the data.
  ///
  /// [zeroBound] automatically include zero in the data range.
  /// [dataIsInWholeNumbers] skip over ticks that would produce
  ///     fractional ticks that don't make sense for the domain (ie: headcount).
  /// [desiredTickCount] the fixed number of ticks to try to make. Convenience
  ///     that sets [desiredMinTickCount] and [desiredMaxTickCount] the same.
  ///     Both min and max win out if they are set along with
  ///     [desiredTickCount].
  /// [desiredMinTickCount] automatically choose the best tick
  ///     count to produce the 'nicest' ticks but make sure we have this many.
  /// [desiredMaxTickCount] automatically choose the best tick
  ///     count to produce the 'nicest' ticks but make sure we don't have more
  ///     than this many.
  const BasicNumericTickProviderSpec({
    this.zeroBound,
    this.dataIsInWholeNumbers,
    this.desiredTickCount,
    this.desiredMinTickCount,
    this.desiredMaxTickCount,
  });

  final bool? zeroBound;
  final bool? dataIsInWholeNumbers;
  final int? desiredTickCount;
  final int? desiredMinTickCount;
  final int? desiredMaxTickCount;

  @override
  NumericTickProvider createTickProvider(ChartContext context) {
    final provider = NumericTickProvider();
    if (zeroBound != null) {
      provider.zeroBound = zeroBound!;
    }
    if (dataIsInWholeNumbers != null) {
      provider.dataIsInWholeNumbers = dataIsInWholeNumbers!;
    }

    if (desiredMinTickCount != null ||
        desiredMaxTickCount != null ||
        desiredTickCount != null) {
      provider.setTickCount(desiredMaxTickCount ?? desiredTickCount ?? 10,
          desiredMinTickCount ?? desiredTickCount ?? 2);
    }
    return provider;
  }

  @override
  bool operator ==(Object other) =>
      other is BasicNumericTickProviderSpec &&
      zeroBound == other.zeroBound &&
      dataIsInWholeNumbers == other.dataIsInWholeNumbers &&
      desiredTickCount == other.desiredTickCount &&
      desiredMinTickCount == other.desiredMinTickCount &&
      desiredMaxTickCount == other.desiredMaxTickCount;

  @override
  int get hashCode => Object.hash(
        dataIsInWholeNumbers,
        desiredTickCount,
        desiredMinTickCount,
        desiredMaxTickCount,
      );
}

/// [TickProviderSpec] that sets up numeric ticks at the two end points of the
/// axis range.
@immutable
class NumericEndPointsTickProviderSpec implements NumericTickProviderSpec {
  /// Creates a [TickProviderSpec] that dynamically chooses numeric ticks at the
  /// two end points of the axis range
  const NumericEndPointsTickProviderSpec();

  @override
  EndPointsTickProvider<num> createTickProvider(ChartContext context) {
    return EndPointsTickProvider<num>();
  }

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) => other is NumericEndPointsTickProviderSpec;
}

/// [TickProviderSpec] that allows you to specific the ticks to be used.
@immutable
class StaticNumericTickProviderSpec implements NumericTickProviderSpec {
  const StaticNumericTickProviderSpec(this.tickSpecs);

  final List<TickSpec<num>> tickSpecs;

  @override
  StaticTickProvider<num> createTickProvider(ChartContext context) =>
      StaticTickProvider<num>(tickSpecs);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StaticNumericTickProviderSpec && tickSpecs == other.tickSpecs);

  @override
  int get hashCode => tickSpecs.hashCode;
}

@immutable
class BasicNumericTickFormatterSpec implements NumericTickFormatterSpec {
  /// Simple [TickFormatterSpec] that delegates formatting to the given
  /// [NumberFormat].
  const BasicNumericTickFormatterSpec(this.formatter) : numberFormat = null;

  const BasicNumericTickFormatterSpec.fromNumberFormat(this.numberFormat)
      : formatter = null;

  final MeasureFormatter? formatter;
  final NumberFormat? numberFormat;

  /// A formatter will be created with the number format if it is not null.
  /// Otherwise, it will create one with the [MeasureFormatter] callback.
  @override
  NumericTickFormatter createTickFormatter(ChartContext context) {
    return numberFormat != null
        ? NumericTickFormatter.fromNumberFormat(numberFormat!)
        : NumericTickFormatter(formatter: formatter);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is BasicNumericTickFormatterSpec &&
            formatter == other.formatter &&
            numberFormat == other.numberFormat);
  }

  @override
  int get hashCode => numberFormat.hashCode;
}
