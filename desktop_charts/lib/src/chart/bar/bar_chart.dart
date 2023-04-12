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

import '../behavior/behavior.dart';
import '../cartesian/cartesian_chart.dart'
    show OrdinalCartesianChart, OrdinalCartesianChartState;
import 'bar_renderer_config.dart';
import 'bar_renderer_decorator.dart';
import 'base_bar_renderer_config.dart';

@immutable
class BarChart extends OrdinalCartesianChart {
  BarChart(
    super.seriesList, {
    BarRendererConfig<String>? defaultRenderer,
    BarGroupingType? barGroupingType,
    super.primaryMeasureAxis,
    super.secondaryMeasureAxis,
    super.disjointMeasureAxes,
    this.isVertical = true,
    this.barRendererDecorator,
    super.key,
    super.animate,
    super.animationDuration,
    super.behaviors,
    super.customSeriesRenderers,
    super.defaultInteractions,
    super.rtlSpec,
    super.selectionModels,
    super.userManagedState,
    super.domainAxis,
    super.flipVerticalAxis,
  }) : super(
          defaultRenderer: defaultRenderer ??
              BarRendererConfig<String>(
                groupingType: barGroupingType,
                barRendererDecorator: barRendererDecorator,
              ),
        );

  final bool isVertical;
  final BarRendererDecorator<String>? barRendererDecorator;

  @override
  BarChartState createState() => BarChartState();
}

class BarChartState extends OrdinalCartesianChartState {
  @override
  void addDefaultInteractions(List<ChartBehavior> behaviors) {
    super.addDefaultInteractions(behaviors);

    behaviors.add(DomainHighlighter<String>());
  }
}
