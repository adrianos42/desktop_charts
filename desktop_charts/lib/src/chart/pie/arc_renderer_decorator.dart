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

import 'package:flutter/rendering.dart';

import 'arc_renderer_element.dart' show ArcRendererElements;

/// Decorates arcs after the arcs have already been painted.
abstract class ArcRendererDecorator<D> {
  const ArcRendererDecorator();

  /// Configures whether the decorator should be rendered on top of or below
  /// series data elements.
  bool get renderAbove;

  void decorate(
    List<ArcRendererElements<D>> arcElementsList,
    Canvas canvas,
    Offset offset, {
    required Rect drawBounds,
    required double animationPercent,
    bool rtl = false,
  });
}
