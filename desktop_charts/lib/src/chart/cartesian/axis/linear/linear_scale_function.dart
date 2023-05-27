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

import '../scale.dart'
    show RangeBandConfig, RangeBandType, StepSizeConfig, StepSizeType;
import 'linear_scale_domain_info.dart' show LinearScaleDomainInfo;
import 'linear_scale_viewport.dart' show LinearScaleViewportSettings;

/// Component of the LinearScale which actually handles the apply and reverse
/// function of the scale.
class LinearScaleFunction {
  /// Cached rangeBand width given the RangeBandConfig and the current
  /// domain & range.
  double rangeBand = 0.0;

  /// Cached amount in domain units to shift the input value as a part of
  /// translation.
  double domainTranslate = 0.0;

  /// Cached translation ratio for scale translation.
  double scalingFactor = 1.0;

  /// Cached amount to shift the output value as a part of
  /// translation.
  double rangeTranslate = 0.0;

  /// The calculated step size given the step size config.
  double stepSize = 0.0;

  /// Translates the given domainValue to the range output.
  double operator [](num domainValue) {
    return (((domainValue + domainTranslate) * scalingFactor) + rangeTranslate)
        .toDouble();
  }

  /// Translates the given range output back to a domainValue.
  double reverse(double value) {
    return ((value - rangeTranslate) / scalingFactor) - domainTranslate;
  }

  /// Update the scale function's scaleFactor given the current state of the
  /// viewport.
  void updateScaleFactor(
      LinearScaleViewportSettings viewportSettings,
      LinearScaleDomainInfo domainInfo,
      RangeBandConfig rangeBandConfig,
      StepSizeConfig stepSizeConfig) {
    final rangeDiff = viewportSettings.range!.diff.toDouble();
    // Note: if you provided a nice function that extends the domain, we won't
    // muck with the extended side.
    final hasHalfStepAtStart =
        domainInfo.extent.min == domainInfo.dataDomainStart;
    final hasHalfStepAtEnd = domainInfo.extent.max == domainInfo.dataDomainEnd;

    // Determine the stepSize and reserved range values.
    // The percentage of the step reserved from the scale's range due to the
    // possible half step at the start and end.
    final reservedRangePercentOfStep =
        getStepReservationPercent(hasHalfStepAtStart, hasHalfStepAtEnd);
    _updateStepSizeAndScaleFactor(viewportSettings, domainInfo, rangeDiff,
        reservedRangePercentOfStep, rangeBandConfig, stepSizeConfig);
  }

  /// Returns the percentage of the step reserved from the output range due to
  /// maybe having to hold half stepSizes on the start and end of the output.
  double getStepReservationPercent(
      bool hasHalfStepAtStart, bool hasHalfStepAtEnd) {
    if (!hasHalfStepAtStart && !hasHalfStepAtEnd) {
      return 0.0;
    }
    if (hasHalfStepAtStart && hasHalfStepAtEnd) {
      return 1.0;
    }
    return 0.5;
  }

  /// Updates the scale function's translate and rangeBand given the current
  /// state of the viewport.
  void updateTranslateAndRangeBand(LinearScaleViewportSettings viewportSettings,
      LinearScaleDomainInfo domainInfo, RangeBandConfig rangeBandConfig) {
    // Assign the rangeTranslate using the current viewportSettings.translate
    // and diffs.
    if (domainInfo.domainDiff == 0) {
      // Translate it to the center of the range.
      rangeTranslate =
          viewportSettings.range!.start + (viewportSettings.range!.diff / 2);
    } else {
      final hasHalfStepAtStart =
          domainInfo.extent.min == domainInfo.dataDomainStart;
      // The shift of the scale function due to the half a step at the
      // beginning.
      final reservedRangeShift = hasHalfStepAtStart ? (stepSize / 2.0) : 0.0;

      rangeTranslate = viewportSettings.range!.start +
          viewportSettings.translate +
          reservedRangeShift;
    }

    // We need to subtract the start from any incoming domain to apply the
    // scale, so flip its sign.
    domainTranslate = -1 * domainInfo.extent.min;

    // Update the rangeBand size.
    rangeBand = _calculateRangeBandSize(rangeBandConfig);
  }

  /// Calculates and stores the current rangeBand given the config and current
  /// step size.
  double _calculateRangeBandSize(RangeBandConfig rangeBandConfig) {
    return switch (rangeBandConfig.type) {
      RangeBandType.fixedDomain => rangeBandConfig.size * scalingFactor,
      RangeBandType.fixed => rangeBandConfig.size,
      RangeBandType.fixedSpaceFromStep => stepSize - rangeBandConfig.size,
      RangeBandType.styleAssignedPercentOfStep ||
      RangeBandType.fixedPercentOfStep =>
        stepSize * rangeBandConfig.size,
      RangeBandType.none => 0.0
    };
  }

  /// Calculates and Stores the current step size and scale factor together,
  /// given the viewport, domain, and config.
  ///
  /// <p>Scale factor and step size are related closely and should be calculated
  /// together so that we do not lose accuracy due to double arithmetic.
  void _updateStepSizeAndScaleFactor(
      LinearScaleViewportSettings viewportSettings,
      LinearScaleDomainInfo domainInfo,
      double rangeDiff,
      double reservedRangePercentOfStep,
      RangeBandConfig rangeBandConfig,
      StepSizeConfig stepSizeConfig) {
    final domainDiff = domainInfo.domainDiff;

    // If we are going to have any rangeBands, then ensure that we account for
    // needed space on the beginning and end of the range.
    if (rangeBandConfig.type != RangeBandType.none) {
      switch (stepSizeConfig.type) {
        case StepSizeType.autoDetect:
          final minimumDetectedDomainStep =
              domainInfo.minimumDetectedDomainStep.toDouble();
          if (minimumDetectedDomainStep.isFinite) {
            scalingFactor = viewportSettings.scalingFactor *
                (rangeDiff /
                    (domainDiff +
                        (minimumDetectedDomainStep *
                            reservedRangePercentOfStep)));
            stepSize = minimumDetectedDomainStep * scalingFactor;
          } else {
            stepSize = rangeDiff.abs();
            scalingFactor = 1.0;
          }
          return;
        case StepSizeType.fixed:
          stepSize = stepSizeConfig.size;
          final reservedRangeForStep = stepSize * reservedRangePercentOfStep;
          scalingFactor = domainDiff == 0
              ? 1.0
              : viewportSettings.scalingFactor *
                  (rangeDiff - reservedRangeForStep) /
                  domainDiff;
          return;
        case StepSizeType.fixedDomain:
          final domainStepWidth = stepSizeConfig.size;
          final totalDomainDiff =
              domainDiff + (domainStepWidth * reservedRangePercentOfStep);
          scalingFactor = totalDomainDiff == 0
              ? 1.0
              : viewportSettings.scalingFactor * (rangeDiff / totalDomainDiff);
          stepSize = domainStepWidth * scalingFactor;
          return;
      }
    }

    // If no cases matched, use zero step size.
    stepSize = 0.0;
    scalingFactor = domainDiff == 0
        ? 1.0
        : viewportSettings.scalingFactor * rangeDiff / domainDiff;
  }
}
