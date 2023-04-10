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

class LegendsPage extends StatefulWidget {
  const LegendsPage({super.key});

  @override
  _LegendsPageState createState() => _LegendsPageState();
}

class _LegendsPageState extends State<LegendsPage> {
  void _refresh() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Defaults(
      header: 'Legends',
      items: [
        ItemTitle(
          title: 'Series Legend',
          subtitle: 'A series legend for a bar chart with default settings',
          body: (context) => SimpleSeriesLegend.withRandomData(),
        ),
        ItemTitle(
          title: 'Series Legend Options',
          subtitle:
              'A series legend with custom positioning and spacing for a bar chart',
          body: (context) => LegendOptions.withRandomData(),
        ),
        ItemTitle(
          title: 'Series Legend Custom Symbol',
          subtitle: 'A series legend using a custom symbol renderer',
          body: (context) => LegendWithCustomSymbol.withRandomData(),
        ),
        ItemTitle(
          title: 'Default Hidden Series Legend',
          subtitle: 'A series legend showing a series hidden by default',
          body: (context) => DefaultHiddenSeriesLegend.withRandomData(),
        ),
        ItemTitle(
          title: 'Series legend with measures',
          subtitle: 'Series legend with measures and measure formatting',
          body: (context) => LegendWithMeasures.withRandomData(),
        ),
        ItemTitle(
          title: 'Datum Legend',
          subtitle: 'A datum legend for a pie chart with default settings',
          body: (context) => SimpleDatumLegend.withRandomData(),
        ),
        ItemTitle(
          title: 'Datum Legend Options',
          subtitle:
              'A datum legend with custom positioning and spacing for a pie chart',
          body: (context) => DatumLegendOptions.withRandomData(),
        ),
        ItemTitle(
          title: 'Datum legend with measures',
          subtitle: 'Datum legend with measures and measure formatting',
          body: (context) => DatumLegendWithMeasures.withRandomData(),
        ),
      ],
    );
  }
}
