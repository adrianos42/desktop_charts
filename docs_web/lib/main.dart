// Copyright (C) 2023 Adriano Souza (adriano.souza113@gmail.com)

import 'package:desktop/desktop.dart';
import 'home.dart';

void main() {
  runApp(
    const DesktopApp(
      home: DocApp(),
      showPerformanceOverlay: false,
      debugShowCheckedModeBanner: true,
    ),
  );
}