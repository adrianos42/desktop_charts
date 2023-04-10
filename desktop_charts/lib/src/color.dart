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

extension ColorEx on Color {
  static const black = Color.fromARGB(255, 0, 0, 0);
  static const white = Color.fromARGB(255, 255, 255, 255);
  static const transparent = Color.fromARGB(0, 0, 0, 0);

  static const _darkerPercentOfOrig = 0.7;
  static const _lighterPercentOfOrig = 0.1;

  Color get darker => Color.fromARGB(
        alpha,
        (red * _darkerPercentOfOrig).round(),
        (green * _darkerPercentOfOrig).round(),
        (blue * _darkerPercentOfOrig).round(),
      );

  Color get lighter => Color.fromARGB(
        alpha,
        red + ((255 - red) * _lighterPercentOfOrig).round(),
        green + ((255 - green) * _lighterPercentOfOrig).round(),
        blue + ((255 - blue) * _lighterPercentOfOrig).round(),
      );
}
