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
import 'package:intl/intl.dart';

import '../numeric_extents.dart' show NumericExtents;
import 'axis_spec.dart' show AxisSpec;
import 'numeric_axis_spec.dart'
    show
        BasicNumericTickFormatterSpec,
        BasicNumericTickProviderSpec,
        NumericAxisSpec,
        NumericTickFormatterSpec;

/// Convenience [AxisSpec] specialized for numeric percentage axes.
@immutable
class PercentAxisSpec extends NumericAxisSpec {
  /// Creates a [NumericAxisSpec] that is specialized for percentage data.
  PercentAxisSpec({
    NumericTickFormatterSpec? tickFormatterSpec,
    super.showAxisLine,
    super.renderSpec,
    super.tickProviderSpec =
        const BasicNumericTickProviderSpec(dataIsInWholeNumbers: false),
    super.viewport = const NumericExtents(0.0, 1.0),
  }) : super(
          tickFormatterSpec: tickFormatterSpec ??
              BasicNumericTickFormatterSpec.fromNumberFormat(
                  NumberFormat.percentPattern()),
        );

  @override
  bool operator ==(Object other) => other is PercentAxisSpec && super == other;

  @override
  int get hashCode => runtimeType.hashCode;
}
