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

import 'dart:math' show min, max;

import '../../../theme.dart';

import '../../../math.dart';
import 'ordinal_scale.dart' show OrdinalScale;
import 'ordinal_scale_domain_info.dart' show OrdinalScaleDomainInfo;
import 'scale.dart'
    show
        RangeBandConfig,
        RangeBandType,
        StepSizeConfig,
        StepSizeType,
        ScaleOutputExtent;

/// Scale that converts ordinal values of type [D] to a given range output.
///
/// A `SimpleOrdinalScale` is used to map values from its domain to the
/// available range of the chart. Typically used for bar charts where the
/// width of the bar is [rangeBand] and the position of the bar is retrieved
/// by [[]].
class SimpleOrdinalScale implements OrdinalScale {
  SimpleOrdinalScale(ChartsThemeData themeData)
      : _domain = OrdinalScaleDomainInfo(),
        _rangeBandConfig = RangeBandConfig.styleAssignedPercent(themeData);

  SimpleOrdinalScale._copy(SimpleOrdinalScale other)
      : _domain = other._domain.copy(),
        _range = ScaleOutputExtent(other._range.start, other._range.end),
        _viewportScale = other._viewportScale,
        _viewportTranslate = other._viewportTranslate,
        _rangeBandConfig = other._rangeBandConfig;

  final _stepSizeConfig = const StepSizeConfig.auto();
  final OrdinalScaleDomainInfo _domain;

  ScaleOutputExtent _range = const ScaleOutputExtent(0.0, 1.0);
  double _viewportScale = 1.0;
  double _viewportTranslate = 0.0;

  RangeBandConfig _rangeBandConfig;

  bool _scaleChanged = true;
  late double _cachedStepSize;
  late double _cachedRangeBandShift;
  late double _cachedRangeBandSize;

  int? _viewportDataSize;
  String? _viewportStartingDomain;

  // TODO: When there are horizontal bars increasing from where
  // the domain and measure axis intersects but the desired behavior is
  // flipped. The plan is to fix this by fixing code to flip the range in the
  // code.
  //
  // If range start is less than range end, then the domain is calculated by
  // adding the band width. If range start is greater than range end, then the
  // domain is calculated by subtracting from the band width (ex. horizontal
  // bar charts where first series is at the bottom of the chart).
  bool get _isVertical => range.start > range.end;

  @override
  double get rangeBand {
    if (_scaleChanged) {
      _updateScale();
    }

    return _cachedRangeBandSize;
  }

  @override
  double get stepSize {
    if (_scaleChanged) {
      _updateScale();
    }

    return _cachedStepSize;
  }

  @override
  double get domainStepSize => 1.0;

  @override
  set rangeBandConfig(RangeBandConfig barGroupWidthConfig) {
    if (barGroupWidthConfig.type == RangeBandType.fixedDomain ||
        barGroupWidthConfig.type == RangeBandType.none) {
      throw ArgumentError(
          'barGroupWidthConfig must not be NONE or FIXED_DOMAIN');
    }

    _rangeBandConfig = barGroupWidthConfig;
    _scaleChanged = true;
  }

  @override
  RangeBandConfig get rangeBandConfig => _rangeBandConfig;

  @override
  set stepSizeConfig(StepSizeConfig? config) {
    if (config != null && config.type != StepSizeType.autoDetect) {
      throw ArgumentError(
          'Ordinal scales only support StepSizeConfig of type Auto');
    }
    // Nothing is set because only auto is supported.
  }

  @override
  StepSizeConfig get stepSizeConfig => _stepSizeConfig;

  /// Converts [domainValue] to the position to place the band/bar.
  ///
  /// Returns 0 if not found.
  @override
  double operator [](String domainValue) {
    if (_scaleChanged) {
      _updateScale();
    }

    final i = _domain.indexOf(domainValue);
    if (i != null) {
      return viewportTranslate +
          _range.start +
          _cachedRangeBandShift +
          (_cachedStepSize * i);
    }
    // If it wasn't found
    return 0.0;
  }

  @override
  String reverse(double location) {
    final index =
        (location - viewportTranslate - _range.start - _cachedRangeBandShift) /
            _cachedStepSize;

    // The last belongs in the last step even if it tries to round up.
    //
    // Index may be less than 0 when [location] is less than the width of
    // the range band shift. This may happen on the far left side of the chart,
    // where we want the first datum anyways. Wrapping the result in "max(0, x)"
    // cuts off these negative values.
    return _domain.getDomainAtIndex(
      max(
        0,
        min(
          index.round(),
          domain.size - 1,
        ),
      ),
    );
  }

  @override
  bool canTranslate(String domainValue) => _domain.indexOf(domainValue) != null;

  @override
  OrdinalScaleDomainInfo get domain => _domain;

  /// Update the scale to include [domainValue].
  @override
  void addDomain(String domainValue) {
    _domain.add(domainValue);
    _scaleChanged = true;
  }

  @override
  set range(ScaleOutputExtent? extent) {
    _range = extent!;
    _scaleChanged = true;
  }

  @override
  ScaleOutputExtent get range => _range;

  @override
  void resetDomain() {
    _domain.clear();
    _scaleChanged = true;
  }

  @override
  void resetViewportSettings() {
    _viewportScale = 1.0;
    _viewportTranslate = 0.0;
    _scaleChanged = true;
  }

  @override
  double get rangeWidth => (range.start - range.end).abs();

  @override
  double get viewportScalingFactor => _viewportScale;

  @override
  double get viewportTranslate => _viewportTranslate;

  @override
  void setViewportSettings(double viewportScale, double viewportTranslate) {
    _viewportScale = viewportScale;
    if (_isVertical) {
      _viewportTranslate =
          max(min(-(rangeWidth * (1.0 - viewportScale)), viewportTranslate), 0);
    } else {
      _viewportTranslate =
          min(max(rangeWidth * (1.0 - viewportScale), viewportTranslate), 0);
    }
    _scaleChanged = true;
  }

  @override
  void setViewport(int? viewportDataSize, String? startingDomain) {
    if (startingDomain != null &&
        viewportDataSize != null &&
        viewportDataSize <= 0) {
      throw ArgumentError('viewportDataSize cannot be less than 1.');
    }

    _scaleChanged = true;
    _viewportDataSize = viewportDataSize;
    _viewportStartingDomain = startingDomain;
  }

  /// Update this scale's viewport using settings [_viewportDataSize] and
  /// [_viewportStartingDomain].
  void _updateViewport() {
    setViewportSettings(1.0, 0.0);
    _recalculateScale();

    if (_domain.isEmpty) {
      return;
    }

    // Update the scale with zoom level to help find the correct translate.
    setViewportSettings(_domain.size / min(_viewportDataSize!, _domain.size),
        _isVertical ? double.maxFinite : 0.0);
    _recalculateScale();
    final domainIndex = _domain.indexOf(_viewportStartingDomain!);
    if (domainIndex != null) {
      double viewportTranslate = 0.0;

      if (_isVertical) {
        // Account for the domain values being reversed.
        viewportTranslate =
            (_viewportDataSize! - domainIndex - 1) * _cachedStepSize;
      } else {
        viewportTranslate = -(_cachedStepSize * domainIndex);
      }
      setViewportSettings(_viewportScale, viewportTranslate);
    }
  }

  @override
  int get viewportDataSize {
    if (_scaleChanged) {
      _updateScale();
    }

    return _domain.isEmpty ? 0 : (rangeWidth ~/ _cachedStepSize.abs());
  }

  @override
  String? get viewportStartingDomain {
    if (_scaleChanged) {
      _updateScale();
    }
    if (_domain.isEmpty) {
      return null;
    }
    if (_isVertical) {
      // Get topmost visible index.
      final index = (-(rangeWidth + _viewportTranslate) / _cachedStepSize)
              .ceil()
              .toInt() -
          1;
      return _domain.getDomainAtIndex(index);
    } else {
      return _domain.getDomainAtIndex(
          (-_viewportTranslate / _cachedStepSize).ceil().toInt());
    }
  }

  @override
  bool isRangeValueWithinViewport(double rangeValue) {
    return withinBounds(rangeValue, range.min, range.max);
  }

  @override
  int compareDomainValueToViewport(String domainValue) {
    // TODO: This currently works because range defaults to 0-1
    // This needs to be looked into further.
    final i = _domain.indexOf(domainValue);

    if (i != null) {
      final domain = this[domainValue];

      if (domain < range.min) {
        return -1;
      }
      if (domain > range.max) {
        return 1;
      }
      return 0;
    }
    return -1;
  }

  @override
  SimpleOrdinalScale copy() => SimpleOrdinalScale._copy(this);

  void _updateCachedFields(
    double stepSize,
    double rangeBand,
    double rangeBandShift,
  ) {
    _cachedStepSize = stepSize;
    _cachedRangeBandSize = rangeBand;
    _cachedRangeBandShift = rangeBandShift;

    if (_isVertical) {
      _cachedStepSize *= -1;
      _cachedRangeBandShift *= -1;
    }

    _scaleChanged = false;
  }

  void _updateScale() {
    if (_viewportStartingDomain != null && _viewportDataSize != null) {
      // Update viewport recalculates the scale.
      _updateViewport();
    }
    _recalculateScale();
  }

  void _recalculateScale() {
    final stepSize = _domain.isEmpty
        ? 0.0
        : _viewportScale * (rangeWidth / _domain.size.toDouble());
    double rangeBand;

    switch (rangeBandConfig.type) {
      case RangeBandType.fixed:
        rangeBand = rangeBandConfig.size.toDouble();
        break;
      case RangeBandType.fixedSpaceFromStep:
        final space = rangeBandConfig.size.toDouble();
        rangeBand = max(0.0, stepSize - space);
        break;
      case RangeBandType.styleAssignedPercentOfStep:
      case RangeBandType.fixedPercentOfStep:
        final percent = rangeBandConfig.size.toDouble();
        rangeBand = stepSize * percent;
        break;
      case RangeBandType.fixedDomain:
      case RangeBandType.none:
        throw StateError('RangeBandType must not be NONE or FIXED_DOMAIN');
    }

    _updateCachedFields(stepSize, rangeBand, stepSize / 2.0);
  }
}
