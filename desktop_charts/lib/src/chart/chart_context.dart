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
import '../date_time_factory.dart';
import '../rtl_spec.dart' show RTLSpec;
import '../theme.dart';

abstract class ChartContext {
  /// Flag indicating whether or not the chart's container was configured in
  /// right to left mode.
  ///
  /// This should be set when the chart is created (or if its container ever
  /// gets configured to the other direction setting).
  ///
  /// Any chart component that needs to know whether the chart axes should be
  /// rendered right to left should read [isRTL].
  bool get chartContainerIsRtl;

  /// Configures the behavior of the chart when [chartContainerIsRtl] is true.
  RTLSpec? get rtlSpec;

  /// Gets whether or not the chart axes should be rendered in right to left
  /// mode.
  ///
  /// This will only be true if the container for the chart component was
  /// configured with the rtl direction setting ([chartContainerIsRtl] == true), and the chart's
  /// [RTLSpec] is set to reverse the axis direction in rtl mode.
  bool get isRTL;

  DateTimeFactory get dateTimeFactory;

  void requestAnimation([Duration? value]);

  void requestPaint();

  //void enableA11yExploreMode(List<A11yNode> nodes, {String? announcement});

  //void disableA11yExploreMode({
  //  String? announcement,
  //});

  CurvedAnimation get animationPosition;

  bool get isVertical;

  ChartsThemeData get themeData;
}
