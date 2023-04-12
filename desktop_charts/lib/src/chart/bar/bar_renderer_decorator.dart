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

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'bar_renderer.dart' show ImmutableBarRendererElement;

/// Decorates bars after the bars have already been painted.
@immutable
abstract class BarRendererDecorator<D> {
  const BarRendererDecorator();

  void decorate(
    Iterable<ImmutableBarRendererElement<D>> barElements,
    Canvas canvas,
    Offset offset, {
    required Rect drawBounds,
    required double animationPercent,
    required bool renderingVertically,
    bool rtl = false,
  });
}
