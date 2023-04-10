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

import 'layout_view.dart';

class SizeList {
  final _sizes = <double>[];
  double _total = 0.0;

  double operator [](int i) => _sizes[i];

  double get total => _total;

  int get length => _sizes.length;

  void add(double size) {
    _sizes.add(size);
    _total += size;
  }

  void adjust(int index, double amount) {
    _sizes[index] += amount;
    _total += amount;
  }
}

class _DesiredViewSizes {
  final preferredSizes = SizeList();
  final minimumSizes = SizeList();

  void add(double preferred, double minimum) {
    preferredSizes.add(preferred);
    minimumSizes.add(minimum);
  }

  void adjustedTo(double maxSize) {
    if (maxSize < preferredSizes.total) {
      double delta = preferredSizes.total - maxSize;

      for (int i = preferredSizes.length - 1; i >= 0; i -= 1) {
        final viewAvailable = preferredSizes[i] - minimumSizes[i];

        if (viewAvailable < delta) {
          // We need even more than this one view can give up, so assign the
          // minimum to the view and adjust totals.
          preferredSizes.adjust(i, -viewAvailable);
          delta -= viewAvailable;
        } else {
          // We can adjust this view to account for the delta.
          preferredSizes.adjust(i, -delta);
          return;
        }
      }
    }
  }
}

/// A strategy for calculating size of vertical margins (RIGHT & LEFT).
abstract class VerticalMarginStrategy {
  SizeList measure(
    Iterable<LayoutViewMixin> views, {
    required double maxWidth,
    required double height,
    required double fullHeight,
  }) {
    final measuredWidths = _DesiredViewSizes();
    double remainingWidth = maxWidth;

    views.forEach((LayoutViewMixin view) {
      final params = view.layoutConfig;
      final viewMargin = params.viewMargin;

      final availableHeight = (params.isFullPosition ? fullHeight : height) -
          viewMargin.top -
          viewMargin.bottom;

      // Measure with all available space, minus the buffer.
      remainingWidth = remainingWidth - viewMargin.left - viewMargin.right;
      maxWidth -= viewMargin.left + viewMargin.right;

      ViewMeasuredSizes size = ViewMeasuredSizes.zero;
      // Don't ask component to measure if both measurements are 0.
      //
      // Measure still needs to be called even when one dimension has a size of
      // zero because if the component is an axis, the axis needs to still
      // recalculate ticks even if it is not to be shown.
      if (remainingWidth > 0 || availableHeight > 0) {
        // size = view.measure(remainingWidth, availableHeight)!;
        remainingWidth -= size.preferredWidth;
      }

      measuredWidths.add(size.preferredWidth, size.minWidth);
    });

    measuredWidths.adjustedTo(maxWidth);
    return measuredWidths.preferredSizes;
  }

  void layout(List<LayoutViewMixin> views, SizeList measuredSizes,
      Rect fullBounds, Rect drawAreaBounds);
}

/// A strategy for calculating size and bounds of left margins.
class LeftMarginLayoutStrategy extends VerticalMarginStrategy {
  @override
  void layout(Iterable<LayoutViewMixin> views, SizeList measuredSizes,
      Rect fullBounds, Rect drawAreaBounds) {
    double prevBoundsRight = drawAreaBounds.left;

    int i = 0;

    for (final view in views) {
      final params = view.layoutConfig;

      final width = measuredSizes[i];
      final left = prevBoundsRight - params.viewMargin.right - width;
      final height =
          (params.isFullPosition ? fullBounds.height : drawAreaBounds.height) -
              params.viewMargin.top -
              params.viewMargin.bottom;
      final top = params.viewMargin.top +
          (params.isFullPosition ? fullBounds.top : drawAreaBounds.top);

      // Update the remaining bounds.
      prevBoundsRight = left - params.viewMargin.left;

      // Layout this component.
      // view.layout(Rect(left, top, width, height), drawAreaBounds);

      i += 1;
    }
  }
}

/// A strategy for calculating size and bounds of right margins.
class RightMarginLayoutStrategy extends VerticalMarginStrategy {
  @override
  void layout(Iterable<LayoutViewMixin> views, SizeList measuredSizes,
      Rect fullBounds, Rect drawAreaBounds) {
    double prevBoundsLeft = drawAreaBounds.right;

    int i = 0;

    for (final view in views) {
      final params = view.layoutConfig;

      final width = measuredSizes[i];
      final left = prevBoundsLeft + params.viewMargin.left;
      final height =
          (params.isFullPosition ? fullBounds.height : drawAreaBounds.height) -
              params.viewMargin.top -
              params.viewMargin.bottom;
      final top = params.viewMargin.top +
          (params.isFullPosition ? fullBounds.top : drawAreaBounds.top);

      // Update the remaining bounds.
      prevBoundsLeft = left + width + params.viewMargin.right;

      // Layout this component.
      //view.layout(Rect(left, top, width, height), drawAreaBounds);

      i += 1;
    }
  }
}

/// A strategy for calculating size of horizontal margins (TOP & BOTTOM).
abstract class HorizontalMarginStrategy {
  SizeList measure(
    Iterable<LayoutViewMixin> views, {
    required double maxHeight,
    required double width,
    required double fullWidth,
  }) {
    final measuredHeights = _DesiredViewSizes();
    double remainingHeight = maxHeight;

    views.forEach((LayoutViewMixin view) {
      final params = view.layoutConfig;
      final viewMargin = params.viewMargin;

      final availableWidth = (params.isFullPosition ? fullWidth : width) -
          viewMargin.left -
          viewMargin.right;

      // Measure with all available space, minus the buffer.
      remainingHeight = remainingHeight - viewMargin.top - viewMargin.bottom;
      maxHeight -= viewMargin.top + viewMargin.bottom;

      ViewMeasuredSizes size = ViewMeasuredSizes.zero;
      // Don't ask component to measure if both measurements are 0.
      //
      // Measure still needs to be called even when one dimension has a size of
      // zero because if the component is an axis, the axis needs to still
      // recalculate ticks even if it is not to be shown.
      if (remainingHeight > 0 || availableWidth > 0) {
        //  size = view.measure(availableWidth, remainingHeight)!;
        remainingHeight -= size.preferredHeight;
      }

      measuredHeights.add(size.preferredHeight, size.minHeight);
    });

    measuredHeights.adjustedTo(maxHeight);
    return measuredHeights.preferredSizes;
  }

  void layout(Iterable<LayoutViewMixin> views, SizeList measuredSizes,
      Rect fullBounds, Rect drawAreaBounds);
}

/// A strategy for calculating size and bounds of top margins.
class TopMarginLayoutStrategy extends HorizontalMarginStrategy {
  @override
  void layout(Iterable<LayoutViewMixin> views, SizeList measuredSizes,
      Rect fullBounds, Rect drawAreaBounds) {
    double prevBoundsBottom = drawAreaBounds.top;

    int i = 0;

    for (final view in views) {
      final params = view.layoutConfig;

      final height = measuredSizes[i];
      final top = prevBoundsBottom - height - params.viewMargin.bottom;

      final width =
          (params.isFullPosition ? fullBounds.width : drawAreaBounds.width) -
              params.viewMargin.left -
              params.viewMargin.right;
      final left = params.viewMargin.left +
          (params.isFullPosition ? fullBounds.left : drawAreaBounds.left);

      // Update the remaining bounds.
      prevBoundsBottom = top - params.viewMargin.top;

      // Layout this component.
      //view.layout(Rect(left, top, width, height), drawAreaBounds);

      i += 1;
    }
  }
}

/// A strategy for calculating size and bounds of bottom margins.
class BottomMarginLayoutStrategy extends HorizontalMarginStrategy {
  @override
  void layout(Iterable<LayoutViewMixin> views, SizeList measuredSizes,
      Rect fullBounds, Rect drawAreaBounds) {
    double prevBoundsTop = drawAreaBounds.bottom;

    int i = 0;

    for (final view in views) {
      final params = view.layoutConfig;

      final height = measuredSizes[i];
      final top = prevBoundsTop + params.viewMargin.top;

      final width =
          (params.isFullPosition ? fullBounds.width : drawAreaBounds.width) -
              params.viewMargin.left -
              params.viewMargin.right;
      final left = params.viewMargin.left +
          (params.isFullPosition ? fullBounds.left : drawAreaBounds.left);

      // Update the remaining bounds.
      prevBoundsTop = top + height + params.viewMargin.bottom;

      // Layout this component.
      //view.layout(Rect(left, top, width, height), drawAreaBounds);

      i += 1;
    }
  }
}