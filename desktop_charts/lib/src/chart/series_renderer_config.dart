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

import '../symbol_renderer.dart';
import '../typed_registry.dart';
import 'base_chart.dart' show BaseChart, BaseChartState;
import 'processed_series.dart' show MutableSeries;
import 'series_renderer.dart' show SeriesRenderer;

/// Interface for series renderer configuration.
abstract class SeriesRendererConfig<D> {
  const SeriesRendererConfig();

  /// Stores typed renderer attributes
  ///
  /// This is useful for storing attributes that is used on the native platform.
  /// Such as the SymbolRenderer that is associated with each renderer but is
  /// a native builder since legend is built natively.
  RendererAttributes get rendererAttributes;

  String? get customRendererId;

  SymbolRenderer? get symbolRenderer;

  Widget build<S extends BaseChart<D>>(
    BuildContext context, {
    required Key key,
    required BaseChartState<D, S> chartState,
    required List<MutableSeries<D>> seriesList,
    String? rendererId,
  });
}

class RendererAttributeKey<R> extends TypedKey<R> {
  const RendererAttributeKey(String uniqueKey) : super(uniqueKey);
}

class RendererAttributes extends TypedRegistry {
  RendererAttributes();
}

abstract class BaseSeriesRenderObjectWidget<
    D,
    S extends BaseChart<D>,
    R extends SeriesRenderer<D, S>,
    C extends SeriesRendererConfig<D>> extends LeafRenderObjectWidget {
  const BaseSeriesRenderObjectWidget({
    required this.rendererId,
    required this.config,
    required this.chartState,
    required this.seriesList,
    required super.key,
  });

  final String? rendererId;
  final C config;
  final BaseChartState<D, S> chartState;
  final List<MutableSeries<D>> seriesList;

  @override
  R createRenderObject(BuildContext context);

  @override
  void updateRenderObject(BuildContext context, R renderObject) {
    renderObject
      ..chartState = chartState
      ..seriesList = seriesList;
  }
}