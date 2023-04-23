// // Copyright (C) 2023 Adriano Souza (adriano.souza113@gmail.com)

// // Copyright 2018 the Charts project authors. Please see the AUTHORS file
// // for details.
// //
// // Licensed under the Apache License, Version 2.0 (the "License");
// // you may not use this file except in compliance with the License.
// // You may obtain a copy of the License at
// //
// // http://www.apache.org/licenses/LICENSE-2.0
// //
// // Unless required by applicable law or agreed to in writing, software
// // distributed under the License is distributed on an "AS IS" BASIS,
// // WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// // See the License for the specific language governing permissions and
// // limitations under the License.

// import 'package:flutter/foundation.dart';
// import 'package:flutter/rendering.dart';

// import '../../text_element.dart' show TextElement;
// import '../pie/arc_label_decorator.dart';
// import '../pie/arc_renderer_element.dart'
//     show ArcRendererElement, ArcRendererElements;
// import 'sunburst_arc_renderer.dart' show SunburstArcRendererElement;

// /// Renders labels for sunburst arc renderers. Configures label based on arc's
// /// position via innerRingArcLabelPosition, innerRingLeafArcLabelPosition, and
// /// outerRingArcLabelPosition. Currently label for non-leaf arcs in the inner
// /// ring may only be drawn inside until there's better collision detection for
// /// inner arcs' label versus the outer arcs.
// ///
// /// TODO: Improve label handling for sunburst chart.
// class SunburstArcLabelDecorator<D> extends ArcLabelDecorator<D> {
//   SunburstArcLabelDecorator({
//     TextStyle? insideLabelStyleSpec,
//     TextStyle? outsideLabelStyleSpec,
//     ArcLabelLeaderLineStyleSpec? leaderLineStyleSpec,
//     double labelPadding = 5.0,
//     bool showLeaderLines = true,
//     // TODO Color? leaderLineColor,
//     this.extendLeaderLine = false,
//     // TODO: Change to auto when we can detect collision of inner
//     // arcs' label with outer arcs.
//     this.innerRingArcLabelPosition = ArcLabelPosition.inside,
//     // TODO: Change to auto when we can detect collision of inner
//     // arcs' label with outer arcs.
//     this.innerRingLeafArcLabelPosition = ArcLabelPosition.inside,
//     this.outerRingArcLabelPosition = ArcLabelPosition.auto,
//   }) : super(
//           insideLabelStyleSpec: insideLabelStyleSpec,
//           outsideLabelStyleSpec: outsideLabelStyleSpec,
//           leaderLineStyleSpec: leaderLineStyleSpec,
//           labelPosition: ArcLabelPosition.auto,
//           labelPadding: labelPadding,
//           showLeaderLines: showLeaderLines,
//           // TODO leaderLineColor: leaderLineColor,
//         );

//   /// Configures the [ArcLabelPosition] for the non-leaf arcs in the inner ring.
//   /// Label can only be rendered inside, If set to ArcLabelPosition.outside,
//   /// label will not be rendered.
//   final ArcLabelPosition innerRingArcLabelPosition;

//   /// Configures the [ArcLabelPosition] for the leaf arcs in the inner ring.
//   final ArcLabelPosition innerRingLeafArcLabelPosition;

//   /// Configures the [ArcLabelPosition] for the arcs in the outer most ring.
//   final ArcLabelPosition outerRingArcLabelPosition;

//   /// When set to true, extend the leader line to outside of the outer most
//   /// ring to avoid collision between inner arc's label with outer arcs.
//   final bool extendLeaderLine;

//   /// Tracks the outerMostRadius when extendLeaderLine is true.
//   double? _outerMostRadius;

//   /// fields for collision detection when extendLeaderLine is true.
//   List<_CollisionDetectionParams> _collisionDetectionParams = [];

//   @override
//   void decorate(
//     List<ArcRendererElements<D>> arcElementsList,
//     Canvas canvas,
//     Offset offset, {
//     required Rect drawBounds,
//     required double animationPercent,
//     bool rtl = false,
//   }) {
//     /// TODO: Improve label handling for sunburst chart. When a
//     /// more sophisticated collision detection is in place, we can draw the
//     /// label for inner arc outside when it doesn't collide with outer arcs.
//     if (extendLeaderLine) {
//       // Resets collision detection params.
//       _collisionDetectionParams = [];
//       // Find the largest of radius in the arcElementList for the leader line.
//       _outerMostRadius = 0.0;
//       for (final arcElements in arcElementsList) {
//         if (arcElements.radius > _outerMostRadius!) {
//           _outerMostRadius = arcElements.radius;
//         }
//       }
//     }

//     // Do not draw label for arcs on the inner ring if positioned outside.
//     if (innerRingArcLabelPosition == ArcLabelPosition.outside) {
//       for (final arcElements in arcElementsList) {
//         arcElements.arcs.retainWhere(
//             (e) => (e as SunburstArcRendererElement).isLeaf == true);
//       }
//     }
//     super.decorate(
//       arcElementsList,
//       canvas,
//       offset,
//       drawBounds: drawBounds,
//       animationPercent: animationPercent,
//       rtl: rtl,
//     );
//   }

//   @override
//   double getLabelRadius(ArcRendererElements<D> arcElements) =>
//       (extendLeaderLine
//           ? (_outerMostRadius ?? arcElements.radius)
//           : arcElements.radius) +
//       leaderLineStyleSpec.length / 2;

//   @override
//   bool detectOutsideLabelCollision(double labelY, bool labelLeftOfChart,
//       double? previousOutsideLabelY, bool? previousLabelLeftOfChart) {
//     if (!extendLeaderLine) {
//       return super.detectOutsideLabelCollision(labelY, labelLeftOfChart,
//           previousOutsideLabelY, previousLabelLeftOfChart);
//     } else {
//       return _collisionDetectionParams.any((param) => super
//           .detectOutsideLabelCollision(labelY, labelLeftOfChart,
//               param.previousOutsideLabelY, param.previousLabelLeftOfChart));
//     }
//   }

//   @override
//   void updateCollisionDetectionParams(List<Object> params) {
//     if (!extendLeaderLine) {
//       super.updateCollisionDetectionParams(params);
//     } else {
//       _collisionDetectionParams.add(_CollisionDetectionParams(
//           params.first as bool, params.last as double));
//     }
//   }

//   @override
//   ArcLabelPosition calculateLabelPosition(
//     TextElement labelElement,
//     TextStyle labelStyle,
//     double insideArcWidth,
//     double outsideArcWidth,
//     ArcRendererElement<D> arcRendererElement,
//     ArcLabelPosition labelPosition,
//   ) {
//     assert(arcRendererElement is SunburstArcRendererElement);

//     if ((arcRendererElement as SunburstArcRendererElement).isOuterMostRing ==
//         true) {
//       return super.calculateLabelPosition(
//           labelElement,
//           labelStyle,
//           insideArcWidth,
//           outsideArcWidth,
//           arcRendererElement,
//           outerRingArcLabelPosition);
//     } else if ((arcRendererElement as SunburstArcRendererElement).isLeaf ==
//         true) {
//       return super.calculateLabelPosition(
//           labelElement,
//           labelStyle,
//           insideArcWidth,
//           outsideArcWidth,
//           arcRendererElement,
//           innerRingLeafArcLabelPosition);
//     } else {
//       /// TODO: Improve label handling for sunburst chart. When a
//       /// more sophisticated collision detection is in place, we can draw the
//       /// label for inner arc outside when it doesn't collide with outer arcs.

//       // Force label for arc on the inner ring inside.
//       return ArcLabelPosition.inside;
//     }
//   }
// }

// @immutable
// class _CollisionDetectionParams {
//   const _CollisionDetectionParams(
//       this.previousLabelLeftOfChart, this.previousOutsideLabelY);

//   final bool previousLabelLeftOfChart;
//   final double previousOutsideLabelY;
// }
