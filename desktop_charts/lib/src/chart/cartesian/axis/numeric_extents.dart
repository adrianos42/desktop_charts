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

import 'package:flutter/foundation.dart';

import 'scale.dart' show Extents;

/// Represents the starting and ending extent of a dataset.
@immutable
class NumericExtents implements Extents<double> {
  /// Precondition: [min] <= [max].
  // TODO: When initializer list asserts are supported everywhere,
  // add the precondition as an initializer list assert. This is supported in
  // Flutter only.
  const NumericExtents(this.min, this.max);

  /// Returns [Extents] based on the min and max of the given values.
  /// Returns [NumericExtents.empty] if [values] are empty
  factory NumericExtents.fromValues(Iterable<double> values) {
    if (values.isEmpty) {
      return NumericExtents.empty;
    }
    double min = values.first;
    double max = values.first;

    for (final value in values) {
      if (value < min) {
        min = value;
      } else if (max < value) {
        max = value;
      }
    }

    return NumericExtents(min, max);
  }

  final double min;
  final double max;

  /// Returns the union of this and other.
  NumericExtents plus(NumericExtents other) {
    if (min <= other.min) {
      if (max >= other.max) {
        return this;
      } else {
        return NumericExtents(min, other.max);
      }
    } else {
      if (other.max >= max) {
        return other;
      } else {
        return NumericExtents(other.min, max);
      }
    }
  }

  /// Compares the given [value] against the extents.
  ///
  /// Returns -1 if the value is less than the extents.
  /// Returns 0 if the value is within the extents inclusive.
  /// Returns 1 if the value is greater than the extents.
  int compareValue(num value) {
    if (value < min) {
      return -1;
    }
    if (value > max) {
      return 1;
    }
    return 0;
  }

  bool _containsValue(num value) => compareValue(value) == 0;

  // Returns true if these [NumericExtents] collides with [other].
  bool overlaps(NumericExtents other) {
    return _containsValue(other.min.toDouble()) ||
        _containsValue(other.max.toDouble()) ||
        other._containsValue(min.toDouble()) ||
        other._containsValue(max.toDouble());
  }

  @override
  bool operator ==(covariant NumericExtents other) {
    return min == other.min && max == other.max;
  }

  @override
  int get hashCode => Object.hash(min, max);

  double get width => (max - min).toDouble();

  @override
  String toString() => 'Extent($min, $max)';

  static const NumericExtents unbounded =
      NumericExtents(double.negativeInfinity, double.infinity);
  static const NumericExtents empty = NumericExtents(0.0, 0.0);
}
