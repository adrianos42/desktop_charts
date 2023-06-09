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

import '../scale.dart' show Extents;

@immutable
class DateTimeExtents extends Extents<DateTime> {
  DateTimeExtents({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  @override
  bool operator ==(covariant DateTimeExtents other) {
    return start == other.start && end == other.end;
  }

  @override
  int get hashCode => Object.hash(start, end);
}
