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
import 'package:intl/intl.dart' show DateFormat;

import '../../../../date_time_factory.dart' show DateTimeFactory;
import '../../../chart_context.dart' show ChartContext;
import '../draw_strategy/tick_draw_strategy.dart' show TickDrawStrategy;
import '../end_points_tick_provider.dart' show EndPointsTickProvider;
import '../static_tick_provider.dart' show StaticTickProvider;
import '../time/auto_adjusting_date_time_tick_provider.dart'
    show AutoAdjustingDateTimeTickProvider;
import '../time/date_time_axis.dart' show DateTimeAxis;
import '../time/date_time_extents.dart' show DateTimeExtents;
import '../time/date_time_tick_formatter.dart' show DateTimeTickFormatter;
import '../time/day_time_stepper.dart' show DayTimeStepper;
import '../time/hour_tick_formatter.dart' show HourTickFormatter;
import '../time/simple_time_tick_formatter.dart'
    show DateTimeFormatterFunction, SimpleTimeTickFormatter;
import '../time/time_range_tick_provider_impl.dart'
    show TimeRangeTickProviderImpl;
import '../time/time_tick_formatter.dart' show TimeTickFormatter;
import '../time/time_tick_formatter_impl.dart'
    show CalendarField, TimeTickFormatterImpl;
import 'axis_spec.dart'
    show AxisSpec, TickProviderSpec, TickFormatterSpec;
import 'tick_spec.dart' show TickSpec;

/// Generic [AxisSpec] specialized for TimeSeries charts.
@immutable
class DateTimeAxisSpec extends AxisSpec<DateTime> {
  /// Creates a [AxisSpec] that specialized for [TimeSeries] charts.
  ///
  /// [renderSpec] spec used to configure how the ticks and labels
  ///     actually render. Possible values are [GridlineRendererSpec],
  ///     [SmallTickRendererSpec] & [NoneRenderSpec]. Make sure that the <D>
  ///     given to the RenderSpec is of type [DateTime] for [TimeSeries].
  /// [tickProviderSpec] spec used to configure what ticks are generated.
  /// [tickFormatterSpec] spec used to configure how the tick labels
  ///     are formatted.
  /// [showAxisLine] override to force the axis to draw the axis
  ///     line.
  const DateTimeAxisSpec({
    this.viewport,
    super.renderSpec,
    super.tickProviderSpec,
    super.tickFormatterSpec,
    super.showAxisLine,
  });

  /// Sets viewport for this Axis.
  ///
  /// If pan / zoom behaviors are set, this is the initial viewport.
  final DateTimeExtents? viewport;

  @override
  DateTimeAxis createAxis({
    required ChartContext chartContext,
    required TickDrawStrategy<DateTime> tickDrawStrategy,
    required AxisDirection axisDirection,
    required bool reverseOutputRange,
  }) {
    throw 'Call createDateTimeAxis() to create a DateTimeAxis.';
  }

  /// Creates a [DateTimeAxis]. This should be called in place of createAxis.
  DateTimeAxis createDateTimeAxis(
    DateTimeFactory dateTimeFactory, {
    required ChartContext chartContext,
    required TickDrawStrategy<DateTime> tickDrawStrategy,
    required AxisDirection axisDirection,
    required bool reverseOutputRange,
  }) =>
      DateTimeAxis(
        dateTimeFactory,
        chartContext: chartContext,
        tickDrawStrategy: tickDrawStrategy,
        axisSpec: this,
        axisDirection: axisDirection,
        reverseOutputRange: reverseOutputRange,
      );

  @override
  bool operator ==(Object other) =>
      other is DateTimeAxisSpec && viewport == other.viewport && super == other;

  @override
  int get hashCode => viewport.hashCode;
}

abstract class DateTimeTickProviderSpec extends TickProviderSpec<DateTime> {}

abstract class DateTimeTickFormatterSpec extends TickFormatterSpec<DateTime> {}

/// [TickProviderSpec] that sets up the automatically assigned time ticks based
/// on the extents of your data.
@immutable
class AutoDateTimeTickProviderSpec implements DateTimeTickProviderSpec {
  /// Creates a [TickProviderSpec] that dynamically chooses ticks based on the
  /// extents of the data.
  ///
  /// [includeTime] - flag that indicates whether the time should be
  /// included when choosing appropriate tick intervals.
  const AutoDateTimeTickProviderSpec({this.includeTime = true});

  final bool includeTime;

  @override
  AutoAdjustingDateTimeTickProvider createTickProvider(
    ChartContext context,
  ) {
    if (includeTime) {
      return AutoAdjustingDateTimeTickProvider.createDefault(
        context.dateTimeFactory,
      );
    } else {
      return AutoAdjustingDateTimeTickProvider.createWithoutTime(
        context.dateTimeFactory,
      );
    }
  }

  @override
  bool operator ==(Object other) =>
      other is AutoDateTimeTickProviderSpec && includeTime == other.includeTime;

  @override
  int get hashCode => includeTime.hashCode;
}

/// [TickProviderSpec] that sets up time ticks with days increments only.
@immutable
class DayTickProviderSpec implements DateTimeTickProviderSpec {
  const DayTickProviderSpec({this.increments});

  final List<int>? increments;

  /// Creates a [TickProviderSpec] that dynamically chooses ticks based on the
  /// extents of the data, limited to day increments.
  ///
  /// [increments] specify the number of day increments that can be chosen from
  /// when searching for the appropriate tick intervals.
  @override
  AutoAdjustingDateTimeTickProvider createTickProvider(
    ChartContext context,
  ) {
    return AutoAdjustingDateTimeTickProvider.createWith([
      TimeRangeTickProviderImpl(DayTimeStepper(
        context.dateTimeFactory,
        allowedTickIncrements: increments,
      ))
    ]);
  }

  @override
  bool operator ==(Object other) =>
      other is DayTickProviderSpec && increments == other.increments;

  @override
  int get hashCode => increments.hashCode;
}

/// [TickProviderSpec] that sets up time ticks at the two end points of the axis
/// range.
@immutable
class DateTimeEndPointsTickProviderSpec implements DateTimeTickProviderSpec {
  const DateTimeEndPointsTickProviderSpec();

  /// Creates a [TickProviderSpec] that dynamically chooses time ticks at the
  /// two end points of the axis range
  @override
  EndPointsTickProvider<DateTime> createTickProvider(
    ChartContext context,
  ) {
    return EndPointsTickProvider<DateTime>();
  }

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) => other is DateTimeEndPointsTickProviderSpec;
}

/// [TickProviderSpec] that allows you to specific the ticks to be used.
@immutable
class StaticDateTimeTickProviderSpec implements DateTimeTickProviderSpec {
  const StaticDateTimeTickProviderSpec(this.tickSpecs);

  final List<TickSpec<DateTime>> tickSpecs;

  @override
  StaticTickProvider<DateTime> createTickProvider(ChartContext context) =>
      StaticTickProvider<DateTime>(tickSpecs);

  @override
  bool operator ==(Object other) =>
      other is StaticDateTimeTickProviderSpec && tickSpecs == other.tickSpecs;

  @override
  int get hashCode => tickSpecs.hashCode;
}

/// Formatters for a single level of the [DateTimeTickFormatterSpec].
@immutable
class TimeFormatterSpec {
  /// Creates a formatter for a particular granularity of data.
  ///
  /// [format] [DateFormat] format string used to format non-transition ticks.
  ///     The string is given to the dateTimeFactory to support i18n formatting.
  /// [transitionFormat] [DateFormat] format string used to format transition
  ///     ticks. Examples of transition ticks:
  ///       Day ticks would have a transition tick at month boundaries.
  ///       Hour ticks would have a transition tick at day boundaries.
  ///       The first tick is typically a transition tick.
  /// [noonFormat] [DateFormat] format string used only for formatting hours
  ///     in the event that you want to format noon differently than other
  ///     hours (ie: [10, 11, 12p, 1, 2, 3]).
  const TimeFormatterSpec({
    this.format,
    this.transitionFormat,
    this.noonFormat,
  });

  final String? format;
  final String? transitionFormat;
  final String? noonFormat;

  @override
  bool operator ==(Object other) =>
      other is TimeFormatterSpec &&
      format == other.format &&
      transitionFormat == other.transitionFormat &&
      noonFormat == other.noonFormat;

  @override
  int get hashCode => Object.hash(transitionFormat, noonFormat);
}

/// A [DateTimeTickFormatterSpec] that accepts a [DateFormat] or a
/// [DateTimeFormatterFunction].
@immutable
class BasicDateTimeTickFormatterSpec implements DateTimeTickFormatterSpec {
  const BasicDateTimeTickFormatterSpec(this.formatter) : dateFormat = null;

  const BasicDateTimeTickFormatterSpec.fromDateFormat(this.dateFormat)
      : formatter = null;

  final DateTimeFormatterFunction? formatter;
  final DateFormat? dateFormat;

  /// A formatter will be created with the [DateFormat] if it is not null.
  /// Otherwise, it will create one with the provided
  /// [DateTimeFormatterFunction].
  @override
  DateTimeTickFormatter createTickFormatter(ChartContext context) {
    assert(dateFormat != null || formatter != null);
    return DateTimeTickFormatter.uniform(SimpleTimeTickFormatter(
        formatter: dateFormat != null ? dateFormat!.format : formatter!));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is BasicDateTimeTickFormatterSpec &&
            formatter == other.formatter &&
            dateFormat == other.dateFormat);
  }

  @override
  int get hashCode => dateFormat.hashCode;
}

/// [TickFormatterSpec] that automatically chooses the appropriate level of
/// formatting based on the tick stepSize. Each level of date granularity has
/// its own [TimeFormatterSpec] used to specify the formatting strings at that
/// level.
@immutable
class AutoDateTimeTickFormatterSpec implements DateTimeTickFormatterSpec {
  /// Creates a [TickFormatterSpec] that automatically chooses the formatting
  /// given the individual [TimeFormatterSpec] formatters that are set.
  ///
  /// There is a default formatter for each level that is configurable, but
  /// by specifying a level here it replaces the default for that particular
  /// granularity. This is useful for swapping out one or all of the formatters.
  const AutoDateTimeTickFormatterSpec({
    this.minute,
    this.hour,
    this.day,
    this.month,
    this.year,
  });

  final TimeFormatterSpec? minute;
  final TimeFormatterSpec? hour;
  final TimeFormatterSpec? day;
  final TimeFormatterSpec? month;
  final TimeFormatterSpec? year;

  @override
  DateTimeTickFormatter createTickFormatter(ChartContext context) {
    final map = <int, TimeTickFormatter>{};

    if (minute != null) {
      map[DateTimeTickFormatter.minute] =
          _makeFormatter(minute!, CalendarField.hourOfDay, context);
    }
    if (hour != null) {
      map[DateTimeTickFormatter.hour] =
          _makeFormatter(hour!, CalendarField.date, context);
    }
    if (day != null) {
      map[23 * DateTimeTickFormatter.hour] =
          _makeFormatter(day!, CalendarField.month, context);
    }
    if (month != null) {
      map[28 * DateTimeTickFormatter.day] =
          _makeFormatter(month!, CalendarField.year, context);
    }
    if (year != null) {
      map[364 * DateTimeTickFormatter.day] =
          _makeFormatter(year!, CalendarField.year, context);
    }

    return DateTimeTickFormatter(context.dateTimeFactory, overrides: map);
  }

  TimeTickFormatterImpl _makeFormatter(TimeFormatterSpec spec,
      CalendarField transitionField, ChartContext context) {
    if (spec.noonFormat != null) {
      return HourTickFormatter(
          dateTimeFactory: context.dateTimeFactory,
          simpleFormat: spec.format,
          transitionFormat: spec.transitionFormat,
          noonFormat: spec.noonFormat);
    } else {
      return TimeTickFormatterImpl(
          dateTimeFactory: context.dateTimeFactory,
          simpleFormat: spec.format,
          transitionFormat: spec.transitionFormat,
          transitionField: transitionField);
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AutoDateTimeTickFormatterSpec &&
          minute == other.minute &&
          hour == other.hour &&
          day == other.day &&
          month == other.month &&
          year == other.year);

  @override
  int get hashCode => Object.hash(hour, day, month, year);
}