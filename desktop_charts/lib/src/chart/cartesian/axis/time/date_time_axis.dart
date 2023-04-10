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

import '../../../../date_time_factory.dart' show DateTimeFactory;
import '../../../base_chart.dart';
import '../axis.dart' show CartesianAxis;
import '../spec/axis_spec.dart' show AxisSpec;
import '../spec/date_time_axis_spec.dart' show DateTimeAxisSpec;
import '../tick_formatter.dart' show TickFormatter;
import '../tick_provider.dart' show TickProvider;
import 'auto_adjusting_date_time_tick_provider.dart'
    show AutoAdjustingDateTimeTickProvider;
import 'date_time_extents.dart' show DateTimeExtents;
import 'date_time_scale.dart' show DateTimeScale;
import 'date_time_tick_formatter.dart' show DateTimeTickFormatter;

class DateTimeAxis<S extends BaseChart<DateTime>>
    extends CartesianAxis<DateTime> {
  DateTimeAxis(
    DateTimeFactory dateTimeFactory, {
    TickProvider<DateTime>? tickProvider,
    TickFormatter<DateTime>? tickFormatter,
    required DateTimeAxisSpec axisSpec,
    required super.chartContext,
    required super.tickDrawStrategy,
    required super.axisDirection,
    required super.reverseOutputRange,
  }) : super(
          tickProvider: tickProvider ??
              AutoAdjustingDateTimeTickProvider.createDefault(dateTimeFactory),
          tickFormatter:
              tickFormatter ?? DateTimeTickFormatter(dateTimeFactory),
          scale: DateTimeScale(dateTimeFactory),
          axisSpec: axisSpec,
        );

  @override
  void updateAxisSpec(AxisSpec<DateTime> value) {
    super.updateAxisSpec(value);

    if (value is DateTimeAxisSpec && value.viewport != null) {
      setScaleViewport(value.viewport!);
    }
  }

  void setScaleViewport(DateTimeExtents viewport) {
    autoViewport = false;
    (mutableScale as DateTimeScale?)!.viewportDomain = viewport;
  }
}
