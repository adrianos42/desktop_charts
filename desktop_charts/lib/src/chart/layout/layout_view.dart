// Copyright (C) 2023 Adriano Souza (adriano.souza113@gmail.com)

import '../behavior/chart_behavior.dart'
    show BehaviorPosition, OutsideJustification;

/// Position of a [LayoutView].
enum LayoutPosition {
  bottom,
  fullBottom,

  top,
  fullTop,

  left,
  fullLeft,

  right,
  fullRight,

  drawArea,
}

/// Standard layout paint orders for all internal components.
///
/// Custom component layers should define their paintOrder by taking the nearest
/// layer from this list, and adding or subtracting 1. This will help reduce the
/// chance of custom behaviors, renderers, etc. from breaking if we need to
/// re-order these components internally.
class LayoutViewPaintOrder {
  // Draw range annotations beneath axis grid lines.
  static const rangeAnnotation = -10;
  // Axis elements form the "base layer" of all components on the chart. Domain
  // axes are drawn on top of measure axes to ensure that the domain axis line
  // appears on top of any measure axis grid lines.
  static const measureAxis = 0;
  static const domainAxis = 5;
  // Draw series data on top of axis elements.
  static const arc = 10;
  static const bar = 10;
  static const treeMap = 10;
  static const sankey = 10;
  static const barTargetLine = 15;
  static const line = 20;
  static const point = 25;
  // Draw most behaviors on top of series data.
  static const legend = 100;
  static const linePointHighlighter = 110;
  static const slider = 150;
  static const chartTitle = 160;
}

/// Standard layout position orders for all internal components.
///
/// Custom component layers should define their positionOrder by taking the
/// nearest component from this list, and adding or subtracting 1. This will
/// help reduce the chance of custom behaviors, renderers, etc. from breaking if
/// we need to re-order these components internally.
class LayoutViewPositionOrder {
  static const drawArea = 0;
  static const symbolAnnotation = 10;
  static const axis = 20;
  static const legend = 30;
  static const chartTitle = 40;
}

/// Translates a component's [BehaviorPosition] and [OutsideJustification] into
/// a [LayoutPosition] that a [LayoutManager] can use to place components on the
/// chart.
LayoutPosition layoutPosition(BehaviorPosition behaviorPosition,
    OutsideJustification outsideJustification, bool isRtl) {
  LayoutPosition position = switch (behaviorPosition) {
    BehaviorPosition.bottom => LayoutPosition.bottom,
    BehaviorPosition.end => isRtl ? LayoutPosition.left : LayoutPosition.right,
    BehaviorPosition.inside => LayoutPosition.drawArea,
    BehaviorPosition.start => isRtl ? LayoutPosition.right : LayoutPosition.left,
    BehaviorPosition.top => LayoutPosition.top,
    BehaviorPosition.insideBelowAxis => LayoutPosition.bottom
  };

  // If we have a "full" [OutsideJustification], convert the layout position
  // to the "full" form.
  if (outsideJustification == OutsideJustification.start ||
      outsideJustification == OutsideJustification.middle ||
      outsideJustification == OutsideJustification.end) {
    switch (position) {
      case LayoutPosition.bottom:
        position = LayoutPosition.fullBottom;
        break;
      case LayoutPosition.left:
        position = LayoutPosition.fullLeft;
        break;
      case LayoutPosition.top:
        position = LayoutPosition.fullTop;
        break;
      case LayoutPosition.right:
        position = LayoutPosition.fullRight;
        break;

      // Ignore other positions, like DrawArea.
      default:
        break;
    }
  }

  return position;
}
