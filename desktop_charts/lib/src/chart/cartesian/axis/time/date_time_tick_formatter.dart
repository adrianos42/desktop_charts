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
import '../tick_formatter.dart' show TickFormatter;
import 'hour_tick_formatter.dart' show HourTickFormatter;
import 'time_tick_formatter.dart' show TimeTickFormatter;
import 'time_tick_formatter_impl.dart'
    show CalendarField, TimeTickFormatterImpl;

/// A [TickFormatter] that formats date/time values based on minimum difference
/// between subsequent ticks.
///
/// This formatter assumes that the Tick values passed in are sorted in
/// increasing order.
///
/// This class is setup with a list of formatters that format the input ticks at
/// a given time resolution. The time resolution which will accurately display
/// the difference between 2 subsequent ticks is picked. Each time resolution
/// can be setup with a [TimeTickFormatter], which is used to format ticks as
/// regular or transition ticks based on whether the tick has crossed the time
/// boundary defined in the [TimeTickFormatter].
class DateTimeTickFormatter implements TickFormatter<DateTime> {
  /// Creates a [DateTimeTickFormatter] that works well with time tick provider
  /// classes.
  ///
  /// The default formatter makes assumptions on border cases that time tick
  /// providers will still provide ticks that make sense. Example: Tick provider
  /// does not provide ticks with 23 hour intervals.  For custom tick providers
  /// where these assumptions are not correct, please create a custom
  /// [TickFormatter].
  factory DateTimeTickFormatter(DateTimeFactory dateTimeFactory,
      {Map<int, TimeTickFormatter>? overrides}) {
    final map = <int, TimeTickFormatter>{
      minute: TimeTickFormatterImpl(
          dateTimeFactory: dateTimeFactory,
          simpleFormat: 'mm',
          transitionFormat: 'h mm',
          transitionField: CalendarField.hourOfDay),
      hour: HourTickFormatter(
          dateTimeFactory: dateTimeFactory,
          simpleFormat: 'h',
          transitionFormat: 'MMM d ha',
          noonFormat: 'ha'),
      23 * hour: TimeTickFormatterImpl(
          dateTimeFactory: dateTimeFactory,
          simpleFormat: 'd',
          transitionFormat: 'MMM d',
          transitionField: CalendarField.month),
      28 * day: TimeTickFormatterImpl(
          dateTimeFactory: dateTimeFactory,
          simpleFormat: 'MMM',
          transitionFormat: 'MMM yyyy',
          transitionField: CalendarField.year),
      364 * day: TimeTickFormatterImpl(
          dateTimeFactory: dateTimeFactory,
          simpleFormat: 'yyyy',
          transitionFormat: 'yyyy',
          transitionField: CalendarField.year),
    };

    // Allow the user to override some of the defaults.
    if (overrides != null) {
      map.addAll(overrides);
    }

    return DateTimeTickFormatter._internal(map);
  }

  /// Creates a [DateTimeTickFormatter] without the time component.
  factory DateTimeTickFormatter.withoutTime(DateTimeFactory dateTimeFactory) {
    return DateTimeTickFormatter._internal({
      23 * hour: TimeTickFormatterImpl(
          dateTimeFactory: dateTimeFactory,
          simpleFormat: 'd',
          transitionFormat: 'MMM d',
          transitionField: CalendarField.month),
      28 * day: TimeTickFormatterImpl(
          dateTimeFactory: dateTimeFactory,
          simpleFormat: 'MMM',
          transitionFormat: 'MMM yyyy',
          transitionField: CalendarField.year),
      365 * day: TimeTickFormatterImpl(
          dateTimeFactory: dateTimeFactory,
          simpleFormat: 'yyyy',
          transitionFormat: 'yyyy',
          transitionField: CalendarField.year),
    });
  }

  /// Creates a [DateTimeTickFormatter] that formats all ticks the same.
  ///
  /// Only use this formatter for data with fixed intervals, otherwise use the
  /// default, or build from scratch.
  ///
  /// [formatter] The format for all ticks.
  factory DateTimeTickFormatter.uniform(TimeTickFormatter formatter) {
    return DateTimeTickFormatter._internal({any: formatter});
  }

  /// Creates a [DateTimeTickFormatter] that formats ticks with [formatters].
  ///
  /// The formatters are expected to be provided with keys in increasing order.
  factory DateTimeTickFormatter.withFormatters(
      Map<int, TimeTickFormatter> formatters) {
    // Formatters must be non empty.
    if (formatters.isEmpty) {
      throw ArgumentError('At least one TimeTickFormatter is required.');
    }

    return DateTimeTickFormatter._internal(formatters);
  }

  DateTimeTickFormatter._internal(this._timeFormatters) {
    // If there is only one formatter, just use this one and skip this check.
    if (_timeFormatters.length == 1) {
      return;
    }
    _checkPositiveAndSorted(_timeFormatters.keys);
  }

  static const int second = 1000;
  static const int minute = 60 * second;
  static const int hour = 60 * minute;
  static const int day = 24 * hour;

  /// Used for the case when there is only one formatter.
  static const int any = -1;

  final Map<int, TimeTickFormatter> _timeFormatters;

  @override
  List<String> format(
    List<DateTime> tickValues,
    Map<DateTime, String> cache, {
    double? stepSize,
  }) {
    final tickLabels = <String>[];
    if (tickValues.isEmpty) {
      return tickLabels;
    }

    // Find the formatter that is the largest interval that has enough
    // resolution to describe the difference between ticks. If no such formatter
    // exists pick the highest res one.
    TimeTickFormatter formatter = _timeFormatters[_timeFormatters.keys.first]!;
    bool formatterFound = false;

    if (_timeFormatters.keys.first == any) {
      formatterFound = true;
    } else {
      final minTimeBetweenTicks = stepSize?.toInt() ?? 0;

      // TODO: Skip the formatter if the formatter's step size is
      // smaller than the minimum step size of the data.

      final keys = _timeFormatters.keys.iterator;
      while (keys.moveNext() && !formatterFound) {
        if (keys.current > minTimeBetweenTicks) {
          formatterFound = true;
        } else {
          formatter = _timeFormatters[keys.current]!;
        }
      }
    }

    // Format the ticks.
    final tickValuesIt = tickValues.iterator;

    DateTime tickValue = (tickValuesIt..moveNext()).current;
    DateTime prevTickValue = tickValue;
    tickLabels.add(formatter.formatFirstTick(tickValue));

    while (tickValuesIt.moveNext()) {
      tickValue = tickValuesIt.current;
      if (formatter.isTransition(tickValue, prevTickValue)) {
        tickLabels.add(formatter.formatTransitionTick(tickValue));
      } else {
        tickLabels.add(formatter.formatSimpleTick(tickValue));
      }
      prevTickValue = tickValue;
    }

    return tickLabels;
  }

  static void _checkPositiveAndSorted(Iterable<int> values) {
    final valuesIterator = values.iterator;
    int prev = (valuesIterator..moveNext()).current;
    bool isSorted = true;

    // Only need to check the first value, because the values after are expected
    // to be greater.
    if (prev <= 0) {
      throw ArgumentError('Formatter keys must be positive');
    }

    while (valuesIterator.moveNext() && isSorted) {
      isSorted = prev < valuesIterator.current;
      prev = valuesIterator.current;
    }

    if (!isSorted) {
      throw ArgumentError(
          'Formatters must be sorted with keys in increasing order');
    }
  }
}
