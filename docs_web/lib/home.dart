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

const String _version = '0.0.1-dev.9';

@immutable
class DocTreeIndex {
  const DocTreeIndex({
    required this.nodeIndex,
    required this.parentTitle,
  });

  final int nodeIndex;
  final String parentTitle;

  @override
  int get hashCode => Object.hash(nodeIndex, parentTitle);

  @override
  bool operator ==(covariant DocTreeIndex other) {
    return other.nodeIndex == nodeIndex && other.parentTitle == parentTitle;
  }
}

class DocTreeController extends ChangeNotifier {
  DocTreeController();

  DocTreeIndex? get index => _index;
  DocTreeIndex? _index;
  set index(DocTreeIndex? value) {
    if (_index != value) {
      _index = value;
      notifyListeners();
    }
  }

  @mustCallSuper
  @override
  void dispose() {
    super.dispose();
  }
}

///
class DocHome extends StatefulWidget {
  ///
  const DocHome({
    super.key,
    required this.packageVersion,
    required this.packageName,
    this.allowThemeColorChange = false,
    this.allowThemeChange = true,
    this.allowDragging = false,
    required this.treeNodes,
    required this.treeController,
  });

  final String packageVersion;

  final String packageName;

  final bool allowThemeColorChange;

  final bool allowThemeChange;

  final List<TreeNode> treeNodes;

  final TreeController treeController;

  final bool allowDragging;

  @override
  State<DocHome> createState() => _DocHomeState();
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
                controller: widget.treeController,
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

class DocApp extends StatefulWidget {
  const DocApp({super.key});

  @override
  DocAppState createState() => DocAppState();
}

class DocAppState extends State<DocApp> {
  final TreeController _treeController = TreeController();
  final DocTreeController _internalTree = DocTreeController();

  @override
  void initState() {
    super.initState();

    _internalTree.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _treeController.dispose();
    _internalTree.dispose();
    super.dispose();
  }

  (String?, int) _indexForCurrentNode(int index) {
    return (
      _treeController.index.isNotEmpty && _treeController.index.first == index
          ? _internalTree.index?.parentTitle
          : null,
      _internalTree.index?.nodeIndex ?? 0
    );
  }

  @override
  Widget build(BuildContext context) {
    return DocHome(
      packageName: 'Desktop Charts',
      packageVersion: _version,
      allowThemeChange: true,
      allowThemeColorChange: true,
      allowDragging: true,
      treeController: _treeController,
      treeNodes: [
        TreeNode.child(
          titleBuilder: (context) => const Text('Overview'),
          builder: (context) => OverviewPage(
            treeController: _treeController,
            treeNodeController: _internalTree,
          ),
        ),
        bar.createChartNode(_indexForCurrentNode(1)),
        pie.createChartNode(),
        line.createChartNode(_indexForCurrentNode(3)),
        scatter_plot.createChartNode(),
        time_series.createChartNode(_indexForCurrentNode(5)),
        axes.createChartNode(_indexForCurrentNode(6)),
        combo.createChartNode(),
        legends.createChartNode(_indexForCurrentNode(8)),
        behaviors.createChartNode(_indexForCurrentNode(9)),
        i18n.createChartNode(),
        //sunburst.createChartNode(),
        // TODO See support for this TreeNode.child(
        //   titleBuilder: (context) => const Text('A11y'),
        //   builder: (context) => const a11y.A11yPage(),
        // ),
      ],
    );
  }
}
