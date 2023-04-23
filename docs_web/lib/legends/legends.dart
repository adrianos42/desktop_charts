// Copyright (C) 2023 Adriano Souza (adriano.souza113@gmail.com)

library legends;

import 'package:desktop/desktop.dart';

import 'datum_legend_options.dart';
import 'datum_legend_with_measures.dart';
import 'default_hidden_series_legend.dart';
import 'legend_custom_symbol.dart';
import 'series_legend_options.dart';
import 'series_legend_with_measures.dart';
import 'simple_datum_legend.dart';
import 'simple_series_legend.dart';

import '../defaults.dart';

List<(String, String?, WidgetBuilder)> createItems([bool animate = true]) {
  return _createItemsWithSeries(
    animate: animate,
  );
}

List<(String, String?, WidgetBuilder)> _createItemsWithSeries({
  bool animate = true,
}) {
  return [
    (
      'Series Legend',
      'A series legend for a bar chart with default settings',
      (context) => SimpleSeriesLegend.withSampleData(animate),
    ),
    (
      'Series Legend Options',
      'A series legend with custom positioning and spacing for a bar chart',
      (context) => LegendOptions.withSampleData(animate),
    ),
    (
      'Series Legend Custom Symbol',
      'A series legend using a custom symbol renderer',
      (context) => LegendWithCustomSymbol.withSampleData(animate),
    ),
    (
      'Default Hidden Series Legend',
      'A series legend showing a series hidden by default',
      (context) => DefaultHiddenSeriesLegend.withSampleData(animate),
    ),
    (
      'Series legend with measures',
      'Series legend with measures and measure formatting',
      (context) => LegendWithMeasures.withSampleData(animate),
    ),
    (
      'Datum Legend',
      'A datum legend for a pie chart with default settings',
      (context) => SimpleDatumLegend.withSampleData(animate),
    ),
    (
      'Datum Legend Options',
      'A datum legend with custom positioning and spacing for a pie chart',
      (context) => DatumLegendOptions.withSampleData(animate),
    ),
    (
      'Datum legend with measures',
      'Datum legend with measures and measure formatting',
      (context) => DatumLegendWithMeasures.withSampleData(animate),
    ),
  ];
}

class LegendsPage extends StatefulWidget {
  const LegendsPage({super.key});

  @override
  _LegendsPageState createState() => _LegendsPageState();
}

class _LegendsPageState extends State<LegendsPage> {
  bool _hasAnimation = true;

  void _updateRandomData() {}

  void _refresh() {
    setState(() => _updateRandomData());
  }

  @override
  void initState() {
    super.initState();

    _updateRandomData();
  }

  List<(String, String?, WidgetBuilder)> _createItems([bool animate = true]) =>
      _createItemsWithSeries(
        animate: animate,
      );

  @override
  Widget build(BuildContext context) {
    return Defaults(
      header: 'Legends',
      items: _createItems(_hasAnimation)
          .map(
            (e) => ItemTitle(
              title: e.$1,
              subtitle: e.$2,
              options: [
                Button.icon(
                  Icons.animation,
                  onPressed: () =>
                      setState(() => _hasAnimation = !_hasAnimation),
                  active: _hasAnimation,
                ),
                //Button.icon(Icons.refresh, onPressed: _refresh),
              ],
              body: e.$3,
            ),
          )
          .toList(),
    );
  }
}
