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
import '../axis.dart' show CartesianAxis;
import '../draw_strategy/tick_draw_strategy.dart' show TickDrawStrategy;
import '../scale.dart' show Scale;
import '../tick_formatter.dart' show TickFormatter;
import '../tick_provider.dart' show TickProvider;

@immutable
class AxisSpec<D> {
  const AxisSpec({
    this.renderSpec,
    this.tickProviderSpec,
    this.tickFormatterSpec,
    this.showAxisLine,
    this.scaleSpec,
  });

  factory AxisSpec.from(
    AxisSpec<D> other, {
    RenderSpec<D>? renderSpec,
    TickProviderSpec<D>? tickProviderSpec,
    TickFormatterSpec<D>? tickFormatterSpec,
    bool? showAxisLine,
    ScaleSpec<D>? scaleSpec,
  }) {
    return AxisSpec(
      renderSpec: renderSpec ?? other.renderSpec,
      tickProviderSpec: tickProviderSpec ?? other.tickProviderSpec,
      tickFormatterSpec: tickFormatterSpec ?? other.tickFormatterSpec,
      showAxisLine: showAxisLine ?? other.showAxisLine,
      scaleSpec: scaleSpec ?? other.scaleSpec,
    );
  }

  final bool? showAxisLine;
  final RenderSpec<D>? renderSpec;
  final TickProviderSpec<D>? tickProviderSpec;
  final TickFormatterSpec<D>? tickFormatterSpec;
  final ScaleSpec<D>? scaleSpec;

  //void configures(CartesianAxis<D> axis, ChartContext context) {}

  /// Creates an appropriately typed [CartesianAxis].
  CartesianAxis<D> createAxis({
    required ChartContext chartContext,
    required TickDrawStrategy<D> tickDrawStrategy,
    required AxisDirection axisDirection,
    required bool reverseOutputRange,
  }) {
    throw 'Not a cartesian axis';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AxisSpec &&
          renderSpec == other.renderSpec &&
          tickProviderSpec == other.tickProviderSpec &&
          tickFormatterSpec == other.tickFormatterSpec &&
          showAxisLine == other.showAxisLine &&
          scaleSpec == other.scaleSpec);

  @override
  int get hashCode => Object.hash(
        tickProviderSpec,
        tickFormatterSpec,
        showAxisLine,
        scaleSpec,
      );
}

@immutable
abstract class TickProviderSpec<D> {
  TickProvider<D> createTickProvider(ChartContext context);
}

@immutable
abstract class TickFormatterSpec<D> {
  TickFormatter<D> createTickFormatter(ChartContext context);
}

@immutable
abstract class ScaleSpec<D> {
  Scale<D> createScale(ChartsThemeData themeData);
}

@immutable
abstract class RenderSpec<D> {
  const RenderSpec();

  TickDrawStrategy<D> createDrawStrategy(ChartContext context);
}

enum TickLabelAnchor {
  before,
  centered,
  after,

  /// The top most tick draws all text under the location.
  /// The bottom most tick draws all text above the location.
  /// The rest of the ticks are centered.
  inside,
}

enum TickLabelJustification {
  inside,
  outside,
}