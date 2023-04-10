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

import '../chart/chart_canvas.dart' show FillPatternType;
import '../chart/datum_details.dart' show DomainFormatter, MeasureFormatter;

import '../typed_registry.dart' show TypedRegistry, TypedKey;

class Series<T, D> {
  factory Series({
    required String id,
    required List<T> data,
    required TypedAccessor<T, D> domain,
    required TypedAccessor<T, num?> measure,
    String? displayName,
    Color? seriesColor,
    TypedAccessor<T, Color>? areaColor,
    TypedAccessor<T, Color>? color,
    TypedAccessor<T, List<int>?>? dashPattern,
    TypedAccessor<T, DomainFormatter<D>>? domainFormatter,
    TypedAccessor<T, D?>? domainLowerBound,
    TypedAccessor<T, D?>? domainUpperBound,
    TypedAccessor<T, Color?>? fillColor,
    TypedAccessor<T, Color>? patternColor,
    TypedAccessor<T, FillPatternType>? fillPattern,
    TypedAccessor<T, String>? key,
    TypedAccessor<T, String>? labelAccessor,
    TypedAccessor<T, TextStyle>? insideLabelStyleAccessor,
    TypedAccessor<T, TextStyle>? outsideLabelStyleAccessor,
    TypedAccessor<T, MeasureFormatter>? measureFormatter,
    TypedAccessor<T, num?>? measureLowerBound,
    TypedAccessor<T, num?>? measureUpperBound,
    TypedAccessor<T, num>? measureOffset,
    bool overlaySeries = false,
    TypedAccessor<T, double>? radius,
    String? seriesCategory,
    TypedAccessor<T, double?>? strokeWidth,
  }) {
    return Series._internal(
      id: id,
      data: data,
      domain: (int? index) => domain(data[index!], index),
      measure: (int? index) => measure(data[index!], index),
      displayName: displayName,
      areaColor: areaColor == null
          ? null
          : (int? index) => areaColor(data[index!], index),
      color: color == null ? null : (int? index) => color(data[index!], index),
      dashPattern: dashPattern == null
          ? null
          : (int? index) => dashPattern(data[index!], index),
      domainFormatter: domainFormatter == null
          ? null
          : (int? index) => domainFormatter(data[index!], index),
      domainLowerBound: domainLowerBound == null
          ? null
          : (int? index) => domainLowerBound(data[index!], index),
      domainUpperBound: domainUpperBound == null
          ? null
          : (int? index) => domainUpperBound(data[index!], index),
      fillColor: fillColor == null
          ? null
          : (int? index) => fillColor(data[index!], index),
      fillPattern: fillPattern == null
          ? null
          : (int? index) => fillPattern(data[index!], index),
      key: key == null ? null : (int? index) => key(data[index!], index),
      patternColor: patternColor == null
          ? null
          : (int? index) => patternColor(data[index!], index),
      labelAccessor: labelAccessor == null
          ? null
          : (int? index) => labelAccessor(data[index!], index),
      insideLabelStyleAccessor: insideLabelStyleAccessor == null
          ? null
          : (int? index) => insideLabelStyleAccessor(data[index!], index),
      outsideLabelStyleAccessor: outsideLabelStyleAccessor == null
          ? null
          : (int? index) => outsideLabelStyleAccessor(data[index!], index),
      measureFormatter: measureFormatter == null
          ? null
          : (int? index) => measureFormatter(data[index!], index),
      measureLowerBound: measureLowerBound == null
          ? null
          : (int? index) => measureLowerBound(data[index!], index),
      measureUpperBound: measureUpperBound == null
          ? null
          : (int? index) => measureUpperBound(data[index!], index),
      measureOffset: measureOffset == null
          ? null
          : (int? index) => measureOffset(data[index!], index),
      overlaySeries: overlaySeries,
      radius:
          radius == null ? null : (int? index) => radius(data[index!], index),
      seriesCategory: seriesCategory,
      seriesColor: seriesColor,
      strokeWidth: strokeWidth == null
          ? null
          : (int? index) => strokeWidth(data[index!], index),
    );
  }

  Series._internal({
    required this.id,
    required this.data,
    required this.domain,
    required this.measure,
    required this.displayName,
    required this.areaColor,
    required this.color,
    required this.dashPattern,
    required this.domainFormatter,
    required this.domainLowerBound,
    required this.domainUpperBound,
    required this.fillColor,
    required this.fillPattern,
    required this.patternColor,
    required this.key,
    required this.labelAccessor,
    required this.insideLabelStyleAccessor,
    required this.outsideLabelStyleAccessor,
    required this.measureFormatter,
    required this.measureLowerBound,
    required this.measureUpperBound,
    required this.measureOffset,
    required this.overlaySeries,
    required this.radius,
    required this.seriesCategory,
    required this.seriesColor,
    required this.strokeWidth,
  });

  final String id;
  final String? displayName;

  /// Overlay series provided supplemental information on a chart, but are not
  /// considered to be primary data. They should not be selectable by user
  /// interaction.
  final bool overlaySeries;

  final String? seriesCategory;

  /// Color which represents the entire series in legends.
  ///
  /// If this is not provided in the original series object, it will be inferred
  /// from the color of the first datum in the series.
  ///
  /// If this is provided, but no [color] is provided, then it will be treated
  /// as the color for each datum in the series.
  ///
  /// If neither are provided, then the chart will insert colors for each series
  /// on the chart using a mapping function.
  final Color? seriesColor;

  final List<T> data;

  /// [key] defines a globally unique identifier for each datum.
  ///
  /// The key for each datum is used during chart animation to smoothly
  /// transition data still in the series to its state.
  ///
  /// Note: This is currently an optional function that is not fully used by all
  /// series renderers yet.
  final Accessor<String>? key;

  final Accessor<D> domain;
  final Accessor<DomainFormatter<D>>? domainFormatter;
  final Accessor<D?>? domainLowerBound;
  final Accessor<D?>? domainUpperBound;
  final Accessor<num?> measure;
  final Accessor<MeasureFormatter>? measureFormatter;
  final Accessor<num?>? measureLowerBound;
  final Accessor<num?>? measureUpperBound;
  final Accessor<num>? measureOffset;

  /// [areaColor] returns the area color for a given data value. If not
  /// provided, then some variation of the main [color] will be used (e.g.
  /// 10% opacity).
  ///
  /// This color is used for supplemental information on the series, such as
  /// confidence intervals or area skirts.
  final Accessor<Color>? areaColor;

  /// [color] returns the rendered stroke color for a given data value.
  ///
  /// If this is not provided, then [seriesColor] will be used for every datum.
  ///
  /// If neither are provided, then the chart will insert colors for each series
  /// on the chart using a mapping function.
  final Accessor<Color>? color;

  /// [dashPattern] returns the dash pattern for a given data value.
  final Accessor<List<int>?>? dashPattern;

  /// [fillColor] returns the rendered fill color for a given data value. If
  /// not provided, then [color] will be used as a fallback.
  final Accessor<Color?>? fillColor;

  /// [patternColor] returns the background color of tile when a
  /// [FillPatternType] beside `solid` is used. If not provided, then
  /// background color is used.
  final Accessor<Color>? patternColor;

  final Accessor<FillPatternType>? fillPattern;
  final Accessor<double>? radius;
  final Accessor<double?>? strokeWidth;
  final Accessor<String>? labelAccessor;
  final Accessor<TextStyle>? insideLabelStyleAccessor;
  final Accessor<TextStyle>? outsideLabelStyleAccessor;

  // TODO: should this be immutable as well? If not, should any of
  // the non-required ones be final?
  final SeriesAttributes attributes = SeriesAttributes();

  void setAttribute<R>(AttributeKey<R> key, R value) {
    attributes.setAttr(key, value);
  }

  R? getAttribute<R>(AttributeKey<R> key) {
    return attributes.getAttr<R>(key);
  }
}

/// Computed property on series.
///
/// If the [index] argument is `null`, the accessor is asked to provide a
/// property of [series] as a whole. Accessors are not required to support
/// such usage.
///
/// Otherwise, [index] must be a valid subscript into a list of `series.length`.
typedef Accessor<R> = R Function(int? index);

typedef TypedAccessor<T, R> = R Function(T datum, int? index);

class AttributeKey<R> extends TypedKey<R> {
  const AttributeKey(String uniqueKey) : super(uniqueKey);
}

class SeriesAttributes extends TypedRegistry {}
