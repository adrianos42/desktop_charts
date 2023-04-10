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

/// A color palette.
abstract class Palette {
  const Palette();

  /// The default shade.
  Color get shadeDefault;

  /// Returns a list of colors for this color palette.
  List<Color> makeShades(int colorCnt) {
    final colors = <Color>[shadeDefault];

    // If we need more than 2 colors, then [unselected] collides with one of the
    // generated colors. Otherwise divide the space between the top color
    // and white in half.
    // final lighterColor = colorCnt < 3
    //     ? shadeDefault.lighter
    //     : _getSteppedColor(shadeDefault, (colorCnt * 2) - 1, colorCnt * 2);

    // Divide the space between 255 and c500 evenly according to the colorCnt.
    for (int i = 1; i < colorCnt; i += 1) {
      colors.add(_getSteppedColor(
        shadeDefault,
        i,
        colorCnt,
        //darker: shadeDefault.darker,
        //lighter: lighterColor,
      ));
    }

    // colors.add(Color.fromOther(color: shadeDefault, lighter: lighterColor));
    colors.add(shadeDefault);

    return colors;
  }

  Color _getSteppedColor(Color color, int index, int steps) {
    final fraction = index / steps;
    return Color.fromARGB(
      color.alpha + ((255 - color.alpha) * fraction).round(),
      color.red + ((255 - color.red) * fraction).round(),
      color.green + ((255 - color.green) * fraction).round(),
      color.blue + ((255 - color.blue) * fraction).round(),
    );
  }
}
