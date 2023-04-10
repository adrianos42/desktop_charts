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

import '../cartesian/axis/time/date_time_axis.dart' show DateTimeAxis;
import '../../date_time_factory.dart'
    show DateTimeFactory, LocalDateTimeFactory;
import '../line/line_renderer_config.dart' show LineRendererConfig;
import '../cartesian/axis/draw_strategy/small_tick_draw_strategy.dart'
    show SmallTickRendererSpec;
import '../cartesian/axis/spec/axis_spec.dart' show AxisSpec;
import '../cartesian/axis/spec/date_time_axis_spec.dart' show DateTimeAxisSpec;
import '../cartesian/cartesian_chart.dart'
    show CartesianChart, CartesianChartState;
import '../series_renderer_config.dart' show SeriesRendererConfig;

class TimeSeriesChart extends CartesianChart<DateTime> {
  TimeSeriesChart(
    super.seriesList, {
    DateTimeAxisSpec? domainAxis,
    SeriesRendererConfig<DateTime>? defaultRenderer,
    this.dateTimeFactory = const LocalDateTimeFactory(),
    super.isVertical,
    super.layoutConfig,
    super.primaryMeasureAxis,
    super.secondaryMeasureAxis,
    super.disjointMeasureAxes,
    super.key,
    super.animate,
    super.animationDuration,
    super.behaviors,
    super.customSeriesRenderers,
    super.defaultInteractions,
    super.flipVerticalAxis,
    super.rtlSpec,
    super.selectionModels,
    super.userManagedState,
  }) : super(
          domainAxis: domainAxis,
          defaultRenderer: defaultRenderer ?? LineRendererConfig(),
        );

  final DateTimeFactory dateTimeFactory;

  @override
  TimeSeriesChartState createState() => TimeSeriesChartState();
}

class TimeSeriesChartState
    extends CartesianChartState<DateTime, TimeSeriesChart> {
  @override
  DateTimeAxis buildDomainAxis({
    required AxisDirection axisDirection,
    required bool reverseOutputRange,
  }) {
    return createDomainAxisFromSpec(
      widget.domainAxis ?? const DateTimeAxisSpec(),
      axisDirection: axisDirection,
      reverseOutputRange: reverseOutputRange,
    );
  }

  @override
  DateTimeAxis createDomainAxisFromSpec(
    AxisSpec<DateTime> axisSpec, {
    required AxisDirection axisDirection,
    required bool reverseOutputRange,
  }) {
    return (axisSpec as DateTimeAxisSpec).createDateTimeAxis(
      widget.dateTimeFactory,
      chartContext: this,
      tickDrawStrategy:
          const SmallTickRendererSpec<DateTime>().createDrawStrategy(this),
      axisDirection: axisDirection,
      reverseOutputRange: reverseOutputRange,
    );
  }
}
