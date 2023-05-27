// Copyright (C) 2023 Adriano Souza (adriano.souza113@gmail.com)

import 'dart:math' show Random;

import 'package:flutter_test/flutter_test.dart';
import 'package:desktop_charts/desktop_charts.dart';
import 'package:desktop/desktop.dart';

class OrdinalSales {
  const OrdinalSales(this.year, this.sales);

  final String year;
  final int sales;
}

void main() {
  final random = Random();

  final data = [
    OrdinalSales('2014', random.nextInt(100)),
    OrdinalSales('2015', random.nextInt(100)),
    OrdinalSales('2016', random.nextInt(100)),
    OrdinalSales('2017', random.nextInt(100)),
  ];

  final seriesList = [
    Series<OrdinalSales, String>(
      id: 'Sales',
      color: (_, __) => DesktopPalette.blue.shadeDefault,
      domain: (OrdinalSales sales, _) => sales.year,
      measure: (OrdinalSales sales, _) => sales.sales,
      data: data,
    )
  ];

  testWidgets('test', (WidgetTester tester) async {
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: BarChart(seriesList),
    ));

    final barFinder = find.byType(BarChart);

    await tester.tapAt(const Offset(200, 200)); 

    expect(barFinder, findsOneWidget);
  });
}
