// Copyright (C) 2023 Adriano Souza (adriano.souza113@gmail.com)

library a11y;

import 'package:desktop/desktop.dart';

import '../defaults.dart';

import 'domain_a11y_explore_bar_chart.dart';

class A11yPage extends StatefulWidget {
  const A11yPage({super.key});

  @override
  _A11yPageState createState() => _A11yPageState();
}

class _A11yPageState extends State<A11yPage> {
  void _refresh() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Defaults(
      header: 'A11y',
      items: [
        ItemTitle(
          title: 'Screen reader enabled bar chart',
          subtitle: 'Requires TalkBack or Voiceover turned on to work. '
              'Bar chart with domain selection explore mode behavior.',
          body: (context) => DomainA11yExploreBarChart.withRandomData(),
        ),
      ],
    );
  }
}
