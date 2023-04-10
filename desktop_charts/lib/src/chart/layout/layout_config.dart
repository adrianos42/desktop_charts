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

/// Collection of configurations that apply to the [LayoutManager].
class LayoutConfig {
  /// Create a [LayoutConfig] used by [DynamicLayoutManager].
  LayoutConfig({
    MarginSpec? leftSpec,
    MarginSpec? rightSpec,
    MarginSpec? topSpec,
    MarginSpec? bottomSpec,
  })  : leftSpec = leftSpec ?? MarginSpec.defaultSpec,
        rightSpec = rightSpec ?? MarginSpec.defaultSpec,
        topSpec = topSpec ?? MarginSpec.defaultSpec,
        bottomSpec = bottomSpec ?? MarginSpec.defaultSpec;

  final MarginSpec leftSpec;
  final MarginSpec rightSpec;
  final MarginSpec topSpec;
  final MarginSpec bottomSpec;
}

/// Specs that applies to one margin.
class MarginSpec {
  const MarginSpec._internal(
    double? minPixel,
    double? maxPixel,
    double? minPercent,
    double? maxPercent,
  )   : _minPixel = minPixel,
        _maxPixel = maxPixel,
        _minPercent = minPercent,
        _maxPercent = maxPercent;

  /// Create [MarginSpec] that specifies min/max pixels.
  ///
  /// [minPixel] if set must be greater than or equal to 0 and less than max if
  /// it is also set.
  /// [maxPixel] if set must be greater than or equal to 0.
  factory MarginSpec.fromPixel({
    double? minPixel,
    double? maxPixel,
  }) {
    // Require zero or higher settings if set
    assert(minPixel == null || minPixel >= 0.0);
    assert(maxPixel == null || maxPixel >= 0.0);
    // Min must be less than or equal to max.
    // Can be equal to enforce strict pixel size.
    if (minPixel != null && maxPixel != null) {
      assert(minPixel <= maxPixel);
    }

    return MarginSpec._internal(minPixel, maxPixel, null, null);
  }

  /// Create [MarginSpec] with a fixed pixel size [pixels].
  ///
  /// [pixels] if set must be greater than or equal to 0.
  factory MarginSpec.fixedPixel(double? pixels) {
    // Require require or higher setting if set
    assert(pixels == null || pixels >= 0.0);

    return MarginSpec._internal(pixels, pixels, null, null);
  }

  /// [MarginSpec] that has max of 50 percent.
  static const defaultSpec = MarginSpec._internal(null, null, null, 50.0);

  final double? _minPixel;
  final double? _maxPixel;
  final double? _minPercent;
  final double? _maxPercent;

  /// Get the min pixels, given the [totalPixels].
  double getMinPixels(double totalPixels) {
    if (_minPixel != null) {
      assert(_minPixel! < totalPixels);
      return _minPixel!;
    } else if (_minPercent != null) {
      return (totalPixels * (_minPercent! / 100.0)).roundToDouble();
    } else {
      return 0.0;
    }
  }

  /// Get the max pixels, given the [totalPixels].
  double getMaxPixels(double totalPixels) {
    if (_maxPixel != null) {
      assert(_maxPixel! < totalPixels);
      return _maxPixel!;
    } else if (_maxPercent != null) {
      return (totalPixels * (_maxPercent! / 100.0)).roundToDouble();
    } else {
      return totalPixels;
    }
  }
}
