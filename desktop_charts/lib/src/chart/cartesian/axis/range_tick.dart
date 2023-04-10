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

import 'tick.dart' show Tick;

/// A labeled range on an axis.
///
/// [D] is the type of the value this tick is associated with.
class RangeTick<D> extends Tick<D> {
  RangeTick({
    required this.rangeStartValue,
    required this.rangeStartLocation,
    required this.rangeEndValue,
    required this.rangeEndLocation,
    required super.value,
    required super.textElement,
    super.location,
    super.labelOffset,
  });

  /// The value that this range tick starting point represents
  final D rangeStartValue;

  /// Position of the range tick starting point.
  double rangeStartLocation;

  /// The value that this range tick ending point represents.
  final D rangeEndValue;

  /// Position of the range tick ending point.
  double rangeEndLocation;

  @override
  String toString() => 'RangeTick(value: $value, location: $location, '
      'labelOffset: $labelOffset, rangeStartValue: $rangeStartValue, '
      'rangeStartLocation: $rangeStartLocation, '
      'rangeEndValue: $rangeEndValue,  rangeEndLocation: $rangeEndLocation)';
}
