// Copyright (C) 2023 Adriano Souza (adriano.souza113@gmail.com)

import 'package:desktop/desktop.dart';

import 'axes/axes.dart' as axes;
import 'bar_chart/bar_chart.dart' as bar;
import 'behaviors/behaviors.dart' as behaviors;
import 'combo_chart/combo.dart' as combo;
import 'i18n/i18n.dart' as i18n;
import 'legends/legends.dart' as legends;
import 'line_chart/line_chart.dart' as line;
import 'overview.dart';
import 'pie_chart/pie_chart.dart' as pie;
import 'scatter_plot_chart/scatter_plot_chart.dart' as scatter_plot;
import 'time_series_chart/time_series_chart.dart' as time_series;

const String _version = '0.0.1-dev.4';

///
class DocHome extends StatefulWidget {
  ///
  DocHome({
    super.key,
    required this.packageVersion,
    required this.packageName,
    this.allowThemeColorChange = false,
    this.allowThemeChange = true,
    this.allowDragging = false,
    required this.treeNodes,
  }) : assert(treeNodes.isNotEmpty, 'Empty documentation.');

  ///
  final String packageVersion;

  ///
  final String packageName;

  ///
  final bool allowThemeColorChange;

  ///
  final bool allowThemeChange;

  ///
  final List<TreeNode> treeNodes;

  ///
  final bool allowDragging;

  @override
  _DocHomeState createState() => _DocHomeState();
}

class _DocHomeState extends State<DocHome> {
  static ContextMenuItem<PrimaryColors> _menuItemPrimaryColor(
    PrimaryColors color,
  ) {
    return ContextMenuItem(
      value: color,
      child: Text(
        color.toString(),
      ),
    );
  }

  PrimaryColors? _primaryColor;

  PrimaryColors get primaryColor =>
      _primaryColor ??
      PrimaryColors.fromPrimaryColor(Theme.of(context).colorScheme.primary)!;

  bool? _isShowingTree;

  Widget _createColorButton() {
    List<ContextMenuItem<PrimaryColors>> itemBuilder(context) => [
          _menuItemPrimaryColor(PrimaryColors.coral),
          _menuItemPrimaryColor(PrimaryColors.sandyBrown),
          _menuItemPrimaryColor(PrimaryColors.orange),
          _menuItemPrimaryColor(PrimaryColors.goldenrod),
          _menuItemPrimaryColor(PrimaryColors.springGreen),
          _menuItemPrimaryColor(PrimaryColors.turquoise),
          _menuItemPrimaryColor(PrimaryColors.deepSkyBlue),
          _menuItemPrimaryColor(PrimaryColors.dodgerBlue),
          _menuItemPrimaryColor(PrimaryColors.cornflowerBlue),
          _menuItemPrimaryColor(PrimaryColors.royalBlue),
          _menuItemPrimaryColor(PrimaryColors.slateBlue),
          _menuItemPrimaryColor(PrimaryColors.purple),
          _menuItemPrimaryColor(PrimaryColors.violet),
          _menuItemPrimaryColor(PrimaryColors.hotPink),
          _menuItemPrimaryColor(PrimaryColors.red),
        ];

    return Builder(
      builder: (context) => ButtonTheme.merge(
        data: ButtonThemeData(
          color: Theme.of(context).textTheme.textPrimaryHigh,
          highlightColor: ButtonTheme.of(context).color,
        ),
        child: ContextMenuButton(
          const Icon(Icons.palette),
          itemBuilder: itemBuilder,
          value: primaryColor,
          onSelected: (PrimaryColors value) {
            final themeData = Theme.of(context);
            final colorScheme = themeData.colorScheme;
            _primaryColor = value;

            Theme.updateThemeData(
              context,
              themeData.copyWith(
                colorScheme: ColorScheme(
                  colorScheme.brightness,
                  primary: value.primaryColor,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _createHome() {
    return Builder(builder: (context) {
      final orientation = MediaQuery.maybeOf(context)?.orientation;
      final textTheme = Theme.of(context).textTheme;

      final isShowingTree =
          _isShowingTree ?? orientation == Orientation.landscape;

      return Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.only(top: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.max,
          children: [
            Wrap(
              direction: Axis.horizontal,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: Button.icon(
                        Icons.menu_open,
                        theme: ButtonThemeData(
                          color: textTheme.textLow,
                          highlightColor: textTheme.textPrimaryHigh,
                        ),
                        active: isShowingTree,
                        size: 22.0,
                        onPressed: () =>
                            setState(() => _isShowingTree = !isShowingTree),
                      ),
                    ),
                    Container(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(
                        vertical: 8.0,
                        horizontal: 16.0,
                      ),
                      child: Builder(
                        builder: (context) {
                          return Tooltip(
                            message: widget.packageVersion,
                            child: Text(
                              widget.packageName,
                              style: Theme.of(context).textTheme.title.copyWith(
                                    overflow: TextOverflow.ellipsis,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary[70],
                                  ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                if (widget.allowThemeChange || widget.allowThemeColorChange)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.allowThemeColorChange) _createColorButton(),
                        if (widget.allowThemeChange)
                          _ThemeToggle(
                            onPressed: () => setState(() {
                              final invertedTheme =
                                  Theme.of(context).invertedTheme;
                              Theme.updateThemeData(context, invertedTheme);
                            }),
                          ),
                      ],
                    ),
                  )
              ],
            ),
            Expanded(
              child: Tree(
                collapsed: !isShowingTree,
                allowDragging: widget.allowDragging,
                title: Builder(
                  builder: (context) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'Documentation',
                      style: Theme.of(context).textTheme.body2,
                    ),
                  ),
                ),
                nodes: widget.treeNodes,
              ),
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // return BottomNavPage();
    return _createHome();
  }
}

class _ThemeToggle extends StatefulWidget {
  const _ThemeToggle({
    required this.onPressed,
    super.key,
  });

  final VoidCallback onPressed;

  @override
  _ThemeToggleState createState() => _ThemeToggleState();
}

class _ThemeToggleState extends State<_ThemeToggle> {
  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final iconForeground = themeData.textTheme.textHigh;
    switch (themeData.brightness) {
      case Brightness.dark:
        return Button.icon(
          Icons.dark_mode,
          onPressed: widget.onPressed,
          theme: ButtonThemeData(
            color: iconForeground,
          ),
        );
      case Brightness.light:
        return Button.icon(
          Icons.light_mode,
          onPressed: widget.onPressed,
          theme: ButtonThemeData(color: iconForeground),
        );
    }
  }
}

class DocApp extends StatelessWidget {
  const DocApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DocHome(
      packageName: 'Desktop Charts',
      packageVersion: _version,
      allowThemeChange: true,
      allowThemeColorChange: true,
      allowDragging: false,
      treeNodes: [
        TreeNode.child(
          titleBuilder: (context) => const Text('Overview'),
          builder: (context) => const OverviewPage(),
        ),
        TreeNode.child(
          titleBuilder: (context) => const Text('Bar'),
          builder: (context) => const bar.BarPage(),
        ),
        TreeNode.child(
          titleBuilder: (context) => const Text('Pie'),
          builder: (context) => const pie.PiePage(),
        ),
        TreeNode.child(
          titleBuilder: (context) => const Text('Line'),
          builder: (context) => const line.LinePage(),
        ),
        TreeNode.child(
          titleBuilder: (context) => const Text('Scatter Plot'),
          builder: (context) => const scatter_plot.ScatterPlotPage(),
        ),
        TreeNode.child(
          titleBuilder: (context) => const Text('Time Series'),
          builder: (context) => const time_series.TimeSeriesPage(),
        ),
        TreeNode.child(
          titleBuilder: (context) => const Text('Axes'),
          builder: (context) => const axes.AxesPage(),
        ),
        TreeNode.child(
          titleBuilder: (context) => const Text('Combo'),
          builder: (context) => const combo.ComboPage(),
        ),
        TreeNode.child(
          titleBuilder: (context) => const Text('Legends'),
          builder: (context) => const legends.LegendsPage(),
        ),
        TreeNode.child(
          titleBuilder: (context) => const Text('Behaviors'),
          builder: (context) => const behaviors.BehaviorsPage(),
        ),
        // TODO See support for this TreeNode.child(
        //   titleBuilder: (context) => const Text('A11y'),
        //   builder: (context) => const a11y.A11yPage(),
        // ),
        TreeNode.child(
          titleBuilder: (context) => const Text('i18n'),
          builder: (context) => const i18n.I18nPage(),
        ),
      ],
    );
  }
}
