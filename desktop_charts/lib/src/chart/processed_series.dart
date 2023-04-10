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

import 'dart:ui' show Color;
import 'package:flutter/painting.dart' show TextStyle;

import '../data/series.dart'
    show Accessor, Series, SeriesAttributes, AttributeKey;
import 'cartesian/axis/axis.dart' show CartesianAxis;
import 'chart_canvas.dart' show FillPatternType;
import 'datum_details.dart' show DomainFormatter, MeasureFormatter;

class MutableSeries<D> extends ImmutableSeries<D> {
  MutableSeries(Series<dynamic, D> series)
      : id = series.id,
        displayName = series.displayName ?? series.id,
        overlaySeries = series.overlaySeries,
        seriesCategory = series.seriesCategory,
        seriesColor = series.seriesColor,
        data = series.data,
        keyFn = series.key,
        domainFn = series.domain,
        domainFormatterFn = series.domainFormatter,
        domainLowerBoundFn = series.domainLowerBound,
        domainUpperBoundFn = series.domainUpperBound,
        measureFn = series.measure,
        measureFormatterFn = series.measureFormatter,
        measureLowerBoundFn = series.measureLowerBound,
        measureUpperBoundFn = series.measureUpperBound,
        measureOffsetFn = series.measureOffset,

        // Save the original measure functions in case they get replaced later.
        rawMeasureFn = series.measure,
        rawMeasureLowerBoundFn = series.measureLowerBound,
        rawMeasureUpperBoundFn = series.measureUpperBound,
        areaColorFn = series.areaColor,
        colorFn = series.color,
        dashPatternFn = series.dashPattern,
        fillColorFn = series.fillColor,
        fillPatternFn = series.fillPattern,
        patternColorFn = series.patternColor,
        insideLabelStyleAccessor = series.insideLabelStyleAccessor,
        outsideLabelStyleAccessor = series.outsideLabelStyleAccessor,
        radiusFn = series.radius,
        strokeWidthFn = series.strokeWidth {
    // Pre-compute the sum of the measure values to make it available on demand.
    seriesMeasureTotal = 0.0;

    for (int i = 0; i < data.length; i += 1) {
      final measure = measureFn(i);
      if (measure != null) {
        seriesMeasureTotal += measure;
      }
    }

    labelAccessor = series.labelAccessor ?? (i) => domainFn(i).toString();

    _attrs.mergeFrom(series.attributes);
  }

  MutableSeries.clone(MutableSeries<D> other)
      : id = other.id,
        displayName = other.displayName,
        overlaySeries = other.overlaySeries,
        seriesCategory = other.seriesCategory,
        seriesColor = other.seriesColor,
        seriesIndex = other.seriesIndex,
        data = other.data,
        keyFn = other.keyFn,
        domainFn = other.domainFn,
        domainFormatterFn = other.domainFormatterFn,
        domainLowerBoundFn = other.domainLowerBoundFn,
        domainUpperBoundFn = other.domainUpperBoundFn,
        measureFn = other.measureFn,
        measureFormatterFn = other.measureFormatterFn,
        measureLowerBoundFn = other.measureLowerBoundFn,
        measureUpperBoundFn = other.measureUpperBoundFn,
        measureOffsetFn = other.measureOffsetFn,
        rawMeasureFn = other.rawMeasureFn,
        rawMeasureLowerBoundFn = other.rawMeasureLowerBoundFn,
        rawMeasureUpperBoundFn = other.rawMeasureUpperBoundFn,
        seriesMeasureTotal = other.seriesMeasureTotal,
        areaColorFn = other.areaColorFn,
        colorFn = other.colorFn,
        dashPatternFn = other.dashPatternFn,
        fillColorFn = other.fillColorFn,
        fillPatternFn = other.fillPatternFn,
        patternColorFn = other.patternColorFn,
        labelAccessor = other.labelAccessor,
        insideLabelStyleAccessor = other.insideLabelStyleAccessor,
        outsideLabelStyleAccessor = other.outsideLabelStyleAccessor,
        radiusFn = other.radiusFn,
        strokeWidthFn = other.strokeWidthFn,
        measureAxis = other.measureAxis,
        domainAxis = other.domainAxis {
    _attrs.mergeFrom(other._attrs);
  }

  @override
  final String id;

  @override
  String? displayName;

  @override
  bool overlaySeries;

  @override
  String? seriesCategory;

  @override
  Color? seriesColor;

  @override
  late int seriesIndex;

  /// Sum of the measure values for the series.
  @override
  late double seriesMeasureTotal;

  @override
  List<dynamic> data;

  @override
  Accessor<String>? keyFn;

  @override
  Accessor<D> domainFn;

  @override
  Accessor<DomainFormatter<D>>? domainFormatterFn;

  @override
  Accessor<D?>? domainLowerBoundFn;

  @override
  Accessor<D?>? domainUpperBoundFn;

  @override
  Accessor<num?> measureFn;

  @override
  Accessor<MeasureFormatter>? measureFormatterFn;

  @override
  Accessor<num?>? measureLowerBoundFn;

  @override
  Accessor<num?>? measureUpperBoundFn;

  @override
  Accessor<num?>? measureOffsetFn;

  @override
  Accessor<num?> rawMeasureFn;

  @override
  Accessor<num?>? rawMeasureLowerBoundFn;

  @override
  Accessor<num?>? rawMeasureUpperBoundFn;

  @override
  Accessor<Color?>? areaColorFn;

  @override
  Accessor<Color>? colorFn;

  @override
  Accessor<List<int>?>? dashPatternFn;

  @override
  Accessor<Color?>? fillColorFn;

  @override
  Accessor<FillPatternType?>? fillPatternFn;

  @override
  Accessor<Color?>? patternColorFn;

  @override
  Accessor<double?>? radiusFn;
  @override
  Accessor<double?>? strokeWidthFn;
  @override
  Accessor<String>? labelAccessor;

  @override
  Accessor<TextStyle>? insideLabelStyleAccessor;

  @override
  Accessor<TextStyle>? outsideLabelStyleAccessor;

  final _attrs = SeriesAttributes();

  // TODO
  CartesianAxis<num>? measureAxis;
  // TODO
  CartesianAxis<D>? domainAxis;

  @override
  void setAttr<R>(AttributeKey<R> key, R value) => _attrs.setAttr(key, value);

  @override
  R? getAttr<R>(AttributeKey<R> key) => _attrs.getAttr(key);

  @override
  bool operator ==(Object other) =>
      other is MutableSeries && data == other.data && id == other.id;

  @override
  int get hashCode => Object.hash(data, id);
}

abstract class ImmutableSeries<D> {
  String get id;

  String? get displayName;

  /// Overlay series provided supplemental information on a chart, but are not
  /// considered to be primary data. They should not be selectable by user
  /// interaction.
  bool get overlaySeries;

  String? get seriesCategory;

  /// Color which represents the entire series in legends.
  ///
  /// If this is not provided in the original series object, it will be inferred
  /// from the color of the first datum in the series.
  ///
  /// If this is provided, but no [colorFn] is provided, then it will be treated
  /// as the color for each datum in the series.
  ///
  /// If neither are provided, then the chart will insert colors for each series
  /// on the chart using a mapping function.
  Color? get seriesColor;

  int get seriesIndex;

  /// Sum of the measure values for the series.
  double get seriesMeasureTotal;

  // Uses `dynamic` for convenience to callers.
  List<dynamic> get data;

  /// [keyFn] defines a globally unique identifier for each datum.
  ///
  /// The key for each datum is used during chart animation to smoothly
  /// transition data still in the series to its state.
  ///
  /// Note: This is currently an optional function that is not fully used by all
  /// series renderers yet.
  Accessor<String>? keyFn;

  Accessor<D> get domainFn;

  Accessor<DomainFormatter<D>>? get domainFormatterFn;

  Accessor<D?>? get domainLowerBoundFn;

  Accessor<D?>? get domainUpperBoundFn;

  Accessor<num?> get measureFn;

  Accessor<MeasureFormatter>? get measureFormatterFn;

  Accessor<num?>? get measureLowerBoundFn;

  Accessor<num?>? get measureUpperBoundFn;

  Accessor<num?>? get measureOffsetFn;

  Accessor<num?> get rawMeasureFn;

  Accessor<num?>? get rawMeasureLowerBoundFn;

  Accessor<num?>? get rawMeasureUpperBoundFn;

  Accessor<Color?>? get areaColorFn;

  Accessor<Color?>? get colorFn;

  Accessor<List<int>?>? get dashPatternFn;

  Accessor<Color?>? get fillColorFn;

  Accessor<Color?>? get patternColorFn;

  Accessor<FillPatternType?>? get fillPatternFn;

  Accessor<String>? get labelAccessor;

  Accessor<TextStyle>? insideLabelStyleAccessor;
  Accessor<TextStyle>? outsideLabelStyleAccessor;

  Accessor<double?>? get radiusFn;

  Accessor<double?>? get strokeWidthFn;

  void setAttr<R>(AttributeKey<R> key, R value);

  R? getAttr<R>(AttributeKey<R> key);
}
