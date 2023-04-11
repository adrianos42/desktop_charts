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

import 'package:collection/collection.dart' show ListEquality;
import 'package:flutter/widgets.dart';

import '../data/data.dart';
import '../date_time_factory.dart' show DateTimeFactory, LocalDateTimeFactory;
import '../gesture_listener.dart' show GestureListener;
import '../proxy_gesture_listener.dart' show ProxyGestureListener;
import '../rtl_spec.dart' show RTLSpec;
import '../theme.dart';
import 'behavior/behavior.dart'
    show
        ChartBehavior,
        BehaviorPosition,
        InsideJustification,
        OutsideJustification,
        SelectNearest,
        SelectionTrigger,
        A11yNode;
import 'chart_context.dart' show ChartContext;
import 'datum_details.dart' show DatumDetails;
import 'processed_series.dart' show MutableSeries;
import 'selection_model.dart'
    show SelectionModelType, SelectionModelListener, MutableSelectionModel;
import 'selection_model_config.dart' show SelectionModelConfig;
import 'series_datum.dart' show SeriesDatum;
import 'series_renderer.dart' show SeriesRenderer, rendererIdKey, rendererKey;
import 'series_renderer_config.dart' show SeriesRendererConfig;
import 'user_managed_state.dart' show UserManagedState;

typedef BehaviorCreator = ChartBehavior<D> Function<D>();

@immutable
abstract class BaseChart<D> extends StatefulWidget {
  const BaseChart(
    this.seriesList, {
    this.animate = true,
    this.animationDuration = const Duration(milliseconds: 300),
    this.defaultRenderer,
    this.customSeriesRenderers,
    this.behaviors,
    this.selectionModels,
    this.rtlSpec,
    this.defaultInteractions = true,
    this.userManagedState,
    super.key,
  });

  /// Series list to draw.
  final List<Series<dynamic, D>> seriesList;

  /// Animation transitions.
  final bool animate;
  final Duration animationDuration;

  // Default renderer used to draw series data on the chart.
  final SeriesRendererConfig<D>? defaultRenderer;

  /// Include the default interactions or not.
  final bool defaultInteractions;

  final List<ChartBehavior<D>>? behaviors;

  final List<SelectionModelConfig<D>>? selectionModels;

  // List of custom series renderers used to draw series data on the chart.
  //
  // Series assigned a rendererIdKey will be drawn with the matching renderer in
  // this list. Series without a rendererIdKey will be drawn by the default
  // renderer.
  final List<SeriesRendererConfig<D>>? customSeriesRenderers;

  /// The spec to use if RTL is enabled.
  final RTLSpec? rtlSpec;

  /// Optional state that overrides internally kept state, such as selection.
  final UserManagedState<D>? userManagedState;
}

abstract class BaseChartState<D, S extends BaseChart<D>> extends State<S>
    with TickerProviderStateMixin
    implements ChartContext {
  // Animation
  late AnimationController _animationController;
  late CurvedAnimation _animationPosition;

  @override
  AnimationController get animationController => _animationController;

  @override
  CurvedAnimation get animationPosition => _animationPosition;

  dynamic _chartGestureDetector;
  final _lifecycleListeners = <LifecycleListener<D>>[];

  LifecycleListener<D> addLifecycleListener(LifecycleListener<D> listener) {
    _lifecycleListeners.add(listener);
    return listener;
  }

  bool removeLifecycleListener(LifecycleListener<D> listener) =>
      _lifecycleListeners.remove(listener);

  /// Called when data is drawn to the chart (not a redraw).
  ///
  /// This step is good for processing the data (running averages, percentage of
  /// first, etc). It can also be used to add Series of data (trend line) or
  /// remove a line as mentioned above, removing Series.
  final ValueNotifier<List<MutableSeries<D>>> dataNotifier =
      ValueNotifier<List<MutableSeries<D>>>([]);

  /// Called for every redraw given the original SeriesList resulting from the
  /// previous onData.
  ///
  /// This step is good for injecting default attributes on the Series before
  /// the renderers process the data (ex: before stacking measures).
  final ValueNotifier<List<MutableSeries<D>>> preprocessNotifier =
      ValueNotifier<List<MutableSeries<D>>>([]);

  /// Called after the chart and renderers get a chance to process the data but
  /// before the axes process them.
  ///
  /// This step is good if you need to alter the Series measure values after the
  /// renderers have processed them (ex: after stacking measures).
  final ValueNotifier<List<MutableSeries<D>>> postprocessNotifier =
      ValueNotifier<List<MutableSeries<D>>>([]);

  /// Called after the Axes have been configured.
  /// This step is good if you need to use the axes to get any cartesian
  /// location information. At this point Axes should be immutable and stable.
  final ChangeNotifier axisConfiguredNotifier = ChangeNotifier();

  /// Called after the chart is done rendering passing along the canvas allowing
  /// a behavior or other listener to render on top of the chart.
  ///
  /// This is a convenience callback, however if there is any significant canvas
  /// interaction or stacking needs, it is preferred that a AplosView/ChartView
  /// is added to the chart instead to fully participate in the view stacking.
  // final LifecycleCanvasCallback? postrenderNotifier = ValueNotifier<List<MutableSeries<D>>>();

  /// Called after animation hits 100%. This allows a behavior or other listener
  /// to chain animations to create a multiple step animation transition.
  final ChangeNotifier animationCompleteNotifier = ChangeNotifier();

  final autoBehaviorWidgets = <ChartBehavior<D>>[];
  final addedBehaviorWidgets = <ChartBehavior<D>>[];
  final addedCommonBehaviorsByRole = <String, ChartBehavior<D>>{};

  final addedSelectionChangedListenersByType =
      <SelectionModelType, SelectionModelListener<D>>{};
  final addedSelectionUpdatedListenersByType =
      <SelectionModelType, SelectionModelListener<D>>{};

  final _behaviorAnimationControllers =
      <ChartBehavior<D>, AnimationController>{};

  static const chartLayoutID = 'chart';

  void _playAnimation(Duration duration) {
    _animationController.duration = duration;
    _animationController.forward(from: 0.0);
  }

  /// Get animation controller to be used by [behavior].
  AnimationController getAnimationController(ChartBehavior behavior) {
    // _behaviorAnimationControllers[behavior] ??=
    //     AnimationController(vsync: this);

    return _behaviorAnimationControllers[behavior]!;
  }

  /// Dispose of animation controller used by [behavior].
  void disposeAnimationController(ChartBehavior behavior) {
    // final controller = _behaviorAnimationControllers.remove(behavior);
    // controller?.dispose();
  }

  void _updateBehaviors() {
    final behaviorList = List<ChartBehavior<D>>.from(widget.behaviors ?? []);

    // Insert automatic behaviors to the front of the behavior list.
    if (widget.defaultInteractions) {
      if (autoBehaviorWidgets.isEmpty) {
        addDefaultInteractions(autoBehaviorWidgets);
      }

      // Add default interaction behaviors to the front of the list if they
      // don't conflict with user behaviors by role.
      autoBehaviorWidgets.reversed
          .where(_notACustomBehavior)
          .forEach((ChartBehavior<D> behavior) {
        behaviorList.insert(0, behavior);
      });
    }

    // Remove any behaviors from the chart that are not in the incoming list.
    // Walk in reverse order they were added.
    // Also, remove any persisting behaviors from incoming list.
    for (int i = addedBehaviorWidgets.length - 1; i >= 0; i--) {
      final addedBehavior = addedBehaviorWidgets[i];
      if (!behaviorList.remove(addedBehavior)) {
        setState(() {
          final role = addedBehavior.role;
          addedBehaviorWidgets.remove(addedBehavior);
          addedCommonBehaviorsByRole.remove(role);
          removeBehavior(addedCommonBehaviorsByRole[role]);
        });
      }
    }

    // Add any remaining/behaviors.
    for (final behavior in behaviorList) {
      addBehavior(behavior);
      addedBehaviorWidgets.add(behavior);
      addedCommonBehaviorsByRole[behavior.role] = behavior;
    }
  }

  /// Create the list of default interaction behaviors.
  @mustCallSuper
  void addDefaultInteractions(List<ChartBehavior> behaviors) {
    // Update selection model
    behaviors.add(
      SelectNearest<D>(
        eventTrigger: SelectionTrigger.tap,
        selectionModelType: SelectionModelType.info,
        selectClosestSeries: true,
      ),
    );
  }

  bool _notACustomBehavior(ChartBehavior behavior) {
    return !behaviors.any(
        (ChartBehavior userBehavior) => userBehavior.role == behavior.role);
  }

  void _updateSelectionModel() {
    final prevTypes = List<SelectionModelType>.from(
        addedSelectionChangedListenersByType.keys);

    // Update any listeners for each type.
    widget.selectionModels?.forEach((SelectionModelConfig<D> model) {
      final selectionModel = getSelectionModel(model.type);

      final prevChangedListener =
          addedSelectionChangedListenersByType[model.type];
      if (!identical(model.changedListener, prevChangedListener)) {
        if (prevChangedListener != null) {
          selectionModel.removeSelectionChangedListener(prevChangedListener);
        }
        selectionModel.addSelectionChangedListener(model.changedListener!);
        addedSelectionChangedListenersByType[model.type] =
            model.changedListener!;
      }

      final prevUpdatedListener =
          addedSelectionUpdatedListenersByType[model.type];
      if (!identical(model.updatedListener, prevUpdatedListener)) {
        if (prevUpdatedListener != null) {
          selectionModel.removeSelectionUpdatedListener(prevUpdatedListener);
        }
        selectionModel.addSelectionUpdatedListener(model.updatedListener!);
        addedSelectionUpdatedListenersByType[model.type] =
            model.updatedListener!;
      }

      prevTypes.remove(model.type);
    });

    // Remove any lingering listeners.
    for (final type in prevTypes) {
      getSelectionModel(type)
        ..removeSelectionChangedListener(
          addedSelectionChangedListenersByType[type]!,
        )
        ..removeSelectionUpdatedListener(
          addedSelectionUpdatedListenersByType[type]!,
        );
    }
  }

  @override
  bool get isRTL => Directionality.of(context) == TextDirection.rtl;

  @override
  bool get chartContainerIsRtl => isRTL;

  @override
  RTLSpec? get rtlSpec => widget.rtlSpec;

  @override
  bool get isTappable => _behaviorTappableMap.isNotEmpty;

  @override
  bool get isVertical => false;

  @override
  DateTimeFactory get dateTimeFactory => const LocalDateTimeFactory();

  @override
  void requestRedraw() {}

  @override
  void requestAnimation([Duration? value]) {
    _playAnimation(value ?? transition);
  }

  @override
  void requestPaint() {
    setState(() {});
  }

  @override
  void enableA11yExploreMode(List<A11yNode> nodes, {String? announcement}) {
    throw 'Not implemented';
  }

  @override
  void disableA11yExploreMode({
    String? announcement,
  }) {
    throw 'Not implemented';
  }

  @override
  ChartsThemeData get themeData => ChartsTheme.of(context);

  Duration get transition =>
      widget.animate ? widget.animationDuration : Duration.zero;

  /// List of series that are currently drawn on the chart.
  ///
  /// This list should be used by interactive behaviors between chart draw
  /// cycles. It may be filtered or modified by some behaviors during the
  /// initial draw cycle (e.g. a [Legend] may hide some series).
  List<MutableSeries<D>>? _currentSeriesList;

  late Map<String, List<MutableSeries<D>>> _rendererToSeriesList;

  Set<String> _usingRenderers = <String>{};

  final _seriesRenderers = <String, GlobalKey>{};

  /// Map of named chart behaviors attached to this chart.
  final _behaviorRoles = <String, ChartBehavior<D>>{};
  final _behaviorStack = <ChartBehavior<D>>[];

  final _behaviorTappableMap = <String, ChartBehavior<D>>{};

  final _gestureProxy = ProxyGestureListener();

  final _selectionModels = <SelectionModelType, MutableSelectionModel<D>>{};

  /// Whether selected data should be restricted to only have points that
  /// cover this event location.
  ///
  /// When this is true, selection logic would ignore points that are close to
  /// event location but does not cover event location.
  bool get selectExactEventLocation => false;

  /// Whether data should be selected by nearest domain distance, or by relative
  /// distance.
  ///
  /// This should generally be true for chart types that are intended to be
  /// aggregated by domain, and false for charts that plot arbitrary x,y data.
  /// Scatter plots, for example, may have many overlapping data with the same
  /// domain value.
  bool get selectNearestByDomain => true;

  /// Whether data should be expanded by to include all points overlapping the
  /// selection point
  ///
  /// Should be true for Scatter plots.
  bool get selectOverlappingPoints => false;

  //
  // Gesture proxy methods
  //
  ProxyGestureListener get gestureProxy => _gestureProxy;

  /// Add a [GestureListener] to this chart.
  GestureListener addGestureListener(GestureListener listener) {
    _gestureProxy.add(listener);
    return listener;
  }

  /// Remove a [GestureListener] from this chart.
  void removeGestureListener(GestureListener listener) {
    _gestureProxy.remove(listener);
  }

  /// Returns MutableSelectionModel for the given type. Lazy creates one upon first
  /// request.
  MutableSelectionModel<D> getSelectionModel(SelectionModelType type) {
    return _selectionModels.putIfAbsent(type, () => MutableSelectionModel<D>());
  }

  /// Returns a list of datum details from selection model of [type].
  List<DatumDetails<D>> getDatumDetails(SelectionModelType type);

  //
  // Renderer methods
  //

  SeriesRenderer<D, S>? get defaultRenderer =>
      getSeriesRenderer(SeriesRenderer.defaultRendererId);

  SeriesRenderer<D, S>? getSeriesRenderer(String? rendererId) {
    return _seriesRenderers[rendererId]?.currentContext?.findRenderObject()
        as SeriesRenderer<D, S>?;
  }

  bool pointWithinRenderer(Offset chartPosition) {
    // TODO return _usingRenderers.any((String rendererId) =>
    // TODO     getSeriesRenderer(rendererId)!
    // TODO         .componentBounds!
    // TODO         .containsPoint(chartPosition));

    return false;
  }

  /// Retrieves the datum details that are nearest to the given [drawAreaPoint].
  ///
  /// [drawAreaPoint] represents a point in the chart, such as a point that was
  /// clicked/tapped on by a user.
  ///
  /// [selectAcrossAllDrawAreaComponents] specifies whether nearest data
  /// selection should be done across the combined draw area of all components
  /// with series draw areas, or just the chart's primary draw area bounds.
  List<DatumDetails<D>> getNearestDatumDetailPerSeries(
    Offset drawAreaPoint,
    bool selectAcrossAllDrawAreaComponents,
  ) {
    // Optionally grab the combined draw area bounds of all components. If this
    // is disabled, then we expect each series renderer to filter out the event
    // if [chartPoint] is located outside of its own component bounds.
    final boundsOverride =
        selectAcrossAllDrawAreaComponents ? drawableLayoutAreaBounds : null;

    final details = <DatumDetails<D>>[];

    for (final rendererId in _usingRenderers) {
      details
          .addAll(getSeriesRenderer(rendererId)!.getNearestDatumDetailPerSeries(
        drawAreaPoint,
        selectNearestByDomain,
        boundsOverride,
        selectOverlappingPoints: selectOverlappingPoints,
        selectExactEventLocation: selectExactEventLocation,
      ));
    }

    details.sort((DatumDetails<D> a, DatumDetails<D> b) {
      // Sort so that the nearest one is first.
      // Special sort, sort by domain distance first, then by measure distance.
      if (selectNearestByDomain) {
        final domainDiff = a.domainDistance!.compareTo(b.domainDistance!);
        if (domainDiff == 0) {
          return a.measureDistance!.compareTo(b.measureDistance!);
        }
        return domainDiff;
      } else {
        return a.relativeDistance!.compareTo(b.relativeDistance!);
      }
    });

    return details;
  }

  /// Retrieves the datum details for the current chart selection.
  ///
  /// [selectionModelType] specifies the type of the selection model to use.
  List<DatumDetails<D>> getSelectedDatumDetails(
      SelectionModelType selectionModelType) {
    final details = <DatumDetails<D>>[];

    if (_currentSeriesList == null) {
      return details;
    }

    final selectionModel = getSelectionModel(selectionModelType);
    if (!selectionModel.hasDatumSelection) {
      return details;
    }

    // Pass each selected datum to the appropriate series renderer to get full
    // details appropriate to its series type.
    for (final seriesDatum in selectionModel.selectedDatum) {
      final rendererId = seriesDatum.series.getAttr(rendererIdKey);
      details.add(
          getSeriesRenderer(rendererId)!.getDetailsForSeriesDatum(seriesDatum));
    }

    return details;
  }

  /// Retrieves the datum details for all data on the chart.
  List<DatumDetails<D>> getAllDatumDetails({
    bool includeOverlaySeries = false,
  }) {
    final details = <DatumDetails<D>>[];

    if (_currentSeriesList == null) {
      return details;
    }

    for (final series in _currentSeriesList!) {
      final rendererId = series.getAttr(rendererIdKey);

      if (!includeOverlaySeries && series.overlaySeries) {
        continue;
      }

      for (final datum in series.data) {
        details.add(getSeriesRenderer(rendererId)!
            .getDetailsForSeriesDatum(SeriesDatum<D>(series, datum)));
      }
    }

    return details;
  }

  //
  // Behavior methods
  //

  /// Helper method to create a behavior with congruent types.
  ///
  /// This invokes the provides helper with type parameters that match this
  /// chart.
  ChartBehavior<D> createBehavior(BehaviorCreator creator) => creator<D>();

  /// Attaches a behavior to the chart.
  ///
  /// Setting a behavior with the same role as a behavior already attached
  /// to the chart will replace the old behavior. The old behavior's removeFrom
  /// method will be called before we attach the behavior.
  void addBehavior(ChartBehavior<D> behavior) {
    final role = behavior.role;

    if (_behaviorRoles[role] != behavior) {
      // Remove any old behavior with the same role.
      removeBehavior(_behaviorRoles[role]);
      // Add the behavior.
      _behaviorRoles[role] = behavior;
    }

    // Add the behavior if it wasn't already added.
    if (!_behaviorStack.contains(behavior)) {
      _behaviorStack.add(behavior);
      behavior.attachTo(this);
    }
  }

  /// Removes a behavior from the chart.
  ///
  /// Returns true if a behavior was removed, otherwise returns false.
  bool removeBehavior(ChartBehavior<D>? behavior) {
    if (behavior == null) {
      return false;
    }

    final role = behavior.role;
    if (_behaviorRoles[role] == behavior) {
      _behaviorRoles.remove(role);
    }

    // Make sure the removed behavior is no longer registered for tap events.
    unregisterTappable(behavior);

    final wasAttached = _behaviorStack.remove(behavior);
    behavior.removeFrom(this);

    return wasAttached;
  }

  /// Tells the chart that this behavior responds to tap events.
  ///
  /// This should only be called after [behavior] has been attached to the chart
  /// via [addBehavior].
  void registerTappable(ChartBehavior<D> behavior) {
    final role = behavior.role;

    if (_behaviorRoles[role] == behavior &&
        _behaviorTappableMap[role] != behavior) {
      _behaviorTappableMap[role] = behavior;
    }
  }

  /// Tells the chart that this behavior no longer responds to tap events.
  void unregisterTappable(ChartBehavior<D> behavior) {
    final role = behavior.role;
    if (_behaviorTappableMap[role] == behavior) {
      _behaviorTappableMap.remove(role);
    }
  }

  /// Returns a list of behaviors that have been added.
  List<ChartBehavior<D>> get behaviors => List.unmodifiable(_behaviorStack);

  /// Returns whether or not [point] is within the draw area bounds.
  bool withinDrawArea(Offset point) {
    return false; // TODO
  }

  /// Returns the combined bounds of the chart draw area and all layout
  /// components that draw series data.
  Rect get drawableLayoutAreaBounds => Rect.zero; // TODO

  //
  // Draw methods
  //
  void _draw() {
    // Clear the selection model when [seriesList] changes.
    for (final selectionModel in _selectionModels.values) {
      selectionModel.clearSelection(notifyListeners: false);
    }

    final processedSeriesList = List.of(
      widget.seriesList.map<MutableSeries<D>>(makeSeries),
      growable: false,
    );

    // Allow listeners to manipulate the seriesList.
    dataNotifier.value = processedSeriesList;

    // Set an index on the series list.
    // This can be used by listeners of selection to determine the order of
    // series, because the selection details are not returned in this order.
    int seriesIndex = 0;

    for (final series in processedSeriesList) {
      series.seriesIndex = seriesIndex += 1;
    }

    // Initially save a reference to processedSeriesList. After drawInternal
    // finishes, we expect _currentSeriesList to contain a new, possibly
    // modified list.
    _currentSeriesList = processedSeriesList;

    final seriesList = processedSeriesList
        .map((MutableSeries<D> series) => MutableSeries<D>.clone(series))
        .toList();

    _rendererToSeriesList = <String, List<MutableSeries<D>>>{};
    _usingRenderers = <String>{};

    for (final series in seriesList) {
      final rendererId = series.getAttr(rendererIdKey);
      _rendererToSeriesList.putIfAbsent(rendererId!, () => []).add(series);
      _usingRenderers.add(rendererId);
    }

    // Allow listeners to manipulate the processed seriesList.
    preprocessNotifier.value = seriesList;

    preprocessSeries(seriesList);

    // Allow listeners to manipulate the processed seriesList.
    _fireOnPostprocess(seriesList);

    _currentSeriesList = seriesList;

    _playAnimation(transition);
  }

  void _fireOnPostprocess(List<MutableSeries<D>> seriesList) {
    _lifecycleListeners.forEach((LifecycleListener<D> listener) {
      listener.onPostprocess?.call(seriesList);
    });
  }

  void preprocessSeries(List<MutableSeries<D>> seriesList) {}

  /// Redraws and re-lays-out the chart using the previously rendered layout
  /// dimensions.
  void redraw({
    bool skipAnimation = false,
    bool skipLayout = false,
  }) {
    setState(() {});
  }

  List<MutableSeries<D>> get currentSeriesList => _currentSeriesList!;

  @mustCallSuper
  MutableSeries<D> makeSeries(Series<dynamic, D> series) {
    final s = MutableSeries<D>(series);

    // Setup the Renderer
    final rendererId =
        series.getAttribute(rendererIdKey) ?? SeriesRenderer.defaultRendererId;
    s.setAttr(rendererIdKey, rendererId);
    s.setAttr(rendererKey, getSeriesRenderer(rendererId));

    return s;
  }

  bool get animatingThisDraw => transition.inMilliseconds > 0;

  @mustCallSuper
  Widget buildChart() {
    return Stack(
      children: [
        widget.defaultRenderer!.build(
          context,
          chartState: this,
          key: _seriesRenderers[SeriesRenderer.defaultRendererId]!,
          seriesList: _rendererToSeriesList[SeriesRenderer.defaultRendererId]!,
          rendererId: SeriesRenderer.defaultRendererId,
        ),
        ...widget.customSeriesRenderers?.map((customSeriesRenderer) {
              final customRendererId = customSeriesRenderer.customRendererId!;

              return customSeriesRenderer.build(
                context,
                key: _seriesRenderers[customRendererId]!,
                chartState: this,
                seriesList: _rendererToSeriesList[customRendererId]!,
                rendererId: customRendererId,
              );
            }).toList() ??
            [],
      ],
    );
  }

  void setAnimation(Duration value) {
    _animationController.reset();
    _playAnimation(value);
  }

  // @override
  // void setState(fn) {
  //   if (mounted) {
  //     super.setState(fn);
  //   }
  // }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this);
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {}
    });

    _animationPosition = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutQuad,
    );

    _seriesRenderers[SeriesRenderer.defaultRendererId] = GlobalKey();

    if (widget.customSeriesRenderers != null) {
      for (final customSeriesRenderer in widget.customSeriesRenderers!) {
        if (customSeriesRenderer.customRendererId == null) {
          throw 'The `customRendererId` in `customSeriesRenderers` cannot be null.';
        }
        if (_seriesRenderers
            .containsKey(customSeriesRenderer.customRendererId)) {
          throw 'Cannot have duplicate keys in `customSeriesRenderers`.';
        }
        _seriesRenderers[customSeriesRenderer.customRendererId!] = GlobalKey();
      }
    }

    _updateBehaviors(); // TODO
    _updateSelectionModel();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _draw();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _animationPosition.dispose();
    _behaviorAnimationControllers
        .forEach((_, controller) => controller.dispose());
    _behaviorAnimationControllers.clear();

    // Walk them in add order to support behaviors that remove other behaviors.
    for (int i = 0; i < _behaviorStack.length; i += 1) {
      _behaviorStack[i].removeFrom(this);
    }
    _behaviorStack.clear();
    _behaviorRoles.clear();

    for (final selectionModel in _selectionModels.values) {
      selectionModel.clearAllListeners();
    }

    dataNotifier.dispose();
    preprocessNotifier.dispose();
    postprocessNotifier.dispose();
    axisConfiguredNotifier.dispose();
    // postrenderNotifier.dispose();
    animationCompleteNotifier.dispose();

    super.dispose();
  }

  @override
  void didUpdateWidget(covariant S oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.seriesList != oldWidget ||
        !ListEquality<Series<dynamic, D>>()
            .equals(widget.seriesList, oldWidget.seriesList)) {
      _draw();
    }

    final customSeriesRenderers = widget.customSeriesRenderers ?? [];
    final oldCustomSeriesRenderers = oldWidget.customSeriesRenderers ?? [];

    if (customSeriesRenderers.length > oldCustomSeriesRenderers.length) {
      for (int i = oldCustomSeriesRenderers.length;
          i < customSeriesRenderers.length;
          i += 1) {
        final customSeriesRenderer = customSeriesRenderers[i];
        if (customSeriesRenderer.customRendererId == null) {
          throw 'The `customRendererId` in `customSeriesRenderers` cannot be null.';
        }
        if (_seriesRenderers
            .containsKey(customSeriesRenderer.customRendererId)) {
          throw 'Cannot have duplicate keys in `customSeriesRenderers`.';
        }
        _seriesRenderers[customSeriesRenderer.customRendererId!] = GlobalKey();
      }
    } else if (customSeriesRenderers.length < oldCustomSeriesRenderers.length) {
      for (int i = customSeriesRenderers.length;
          i < oldCustomSeriesRenderers.length;
          i += 1) {
        final customSeriesRenderer = oldCustomSeriesRenderers[i];
        _seriesRenderers.remove(customSeriesRenderer.customRendererId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chartChildren = <LayoutId>[];
    final idAndBehaviorMap = <String, ChartBehavior>{};

    chartChildren.add(
      LayoutId(
        id: chartLayoutID,
        child: buildChart(),
      ),
    );

    // Add widget for each behavior that can build widgets
    addedCommonBehaviorsByRole.forEach((id, behavior) {
      assert(id != chartLayoutID);

      idAndBehaviorMap[id] = behavior;

      chartChildren.add(
        LayoutId(
          id: id,
          child: behavior.buildBehavior(context),
        ),
      );
    });

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: CustomMultiChildLayout(
        delegate: WidgetLayoutDelegate(
          chartLayoutID,
          idAndBehaviorMap,
          isRTL,
        ),
        children: chartChildren,
      ),
    );
  }
}

/// Layout delegate that layout chart widget with [Behavior] widgets.
class WidgetLayoutDelegate extends MultiChildLayoutDelegate {
  WidgetLayoutDelegate(this.chartID, this.idAndBehavior, this.isRTL);

  /// ID of the common chart widget.
  final String chartID;

  /// Directionality of the widget.
  final bool isRTL;

  /// ID and [Behavior] of the widgets for calculating offset.
  final Map<String, ChartBehavior> idAndBehavior;

  @override
  void performLayout(Size size) {
    // Size available for the chart widget.
    double availableWidth = size.width;
    double availableHeight = size.height;
    double chartOffsetX = 0.0;
    double chartOffsetY = 0.0;

    final behaviorIDs = idAndBehavior.keys;

    final Map<String, Size> behaviorSize = {};

    for (final behaviorID in behaviorIDs) {
      if (hasChild(behaviorID)) {
        final leftPosition =
            isRTL ? BehaviorPosition.end : BehaviorPosition.start;
        final rightPosition =
            isRTL ? BehaviorPosition.start : BehaviorPosition.end;
        final behaviorPosition = idAndBehavior[behaviorID]!.position;

        behaviorSize[behaviorID] =
            layoutChild(behaviorID, BoxConstraints.loose(size));
        if (behaviorPosition == BehaviorPosition.top) {
          chartOffsetY += behaviorSize[behaviorID]!.height;
          availableHeight -= behaviorSize[behaviorID]!.height;
        } else if (behaviorPosition == BehaviorPosition.bottom) {
          availableHeight -= behaviorSize[behaviorID]!.height;
        } else if (behaviorPosition == leftPosition) {
          chartOffsetX += behaviorSize[behaviorID]!.width;
          availableWidth -= behaviorSize[behaviorID]!.width;
        } else if (behaviorPosition == rightPosition) {
          availableWidth -= behaviorSize[behaviorID]!.width;
        }
      }
    }

    // Layout chart.
    if (hasChild(chartID)) {
      layoutChild(
        chartID,
        BoxConstraints.tightFor(
          width: availableWidth,
          height: availableHeight,
        ),
      );

      positionChild(chartID, Offset(chartOffsetX, chartOffsetY));
    }

    // Position buildable behavior.
    for (final behaviorID in behaviorIDs) {
      // TODO: Unable to relayout with smaller width.
      // In the delegate, all children are required to have layout called
      // exactly once.
      final behaviorOffset = _getBehaviorOffset(
        idAndBehavior[behaviorID]!,
        behaviorSize: behaviorSize[behaviorID]!,
        chartSize: Size(availableWidth, availableHeight),
        isRTL: isRTL,
      );

      positionChild(behaviorID, behaviorOffset);
    }
  }

  @override
  bool shouldRelayout(MultiChildLayoutDelegate delegate) {
    // TODO: Deep equality check because the instance will not be
    // the same on each build, even if the buildable behavior has not changed.
    return idAndBehavior != (delegate as WidgetLayoutDelegate).idAndBehavior;
  }

  // Calculate behavior's offset.
  Offset _getBehaviorOffset(
    dynamic behavior, {
    required Size behaviorSize,
    required Size chartSize,
    required bool isRTL,
  }) {
    late Offset behaviorOffset;

    final behaviorPosition = behavior.position;
    final outsideJustification = behavior.outsideJustification;
    final insideJustification = behavior.insideJustification;

    if (behaviorPosition == BehaviorPosition.top ||
        behaviorPosition == BehaviorPosition.bottom) {
      final heightOffset =
          behaviorPosition == BehaviorPosition.bottom ? chartSize.height : 0.0;

      final horizontalJustification =
          _getOutsideJustification(outsideJustification, isRTL);

      switch (horizontalJustification) {
        case _HorizontalJustification.leftDrawArea:
          behaviorOffset =
              Offset(behavior.drawAreaBounds!.left.toDouble(), heightOffset);
          break;
        case _HorizontalJustification.left:
          behaviorOffset = Offset(0.0, heightOffset);
          break;
        case _HorizontalJustification.rightDrawArea:
          behaviorOffset = Offset(
            behavior.drawAreaBounds!.right - behaviorSize.width,
            heightOffset,
          );
          break;
        case _HorizontalJustification.right:
          behaviorOffset =
              Offset(chartSize.width - behaviorSize.width, heightOffset);
          break;
      }
    } else if (behaviorPosition == BehaviorPosition.start ||
        behaviorPosition == BehaviorPosition.end) {
      final widthOffset =
          (isRTL && behaviorPosition == BehaviorPosition.start) ||
                  (!isRTL && behaviorPosition == BehaviorPosition.end)
              ? chartSize.width
              : 0.0;

      switch (outsideJustification) {
        case OutsideJustification.startDrawArea:
        case OutsideJustification.middleDrawArea:
          behaviorOffset =
              Offset(widthOffset, behavior.drawAreaBounds!.top.toDouble());
          break;
        case OutsideJustification.start:
        case OutsideJustification.middle:
          behaviorOffset = Offset(widthOffset, 0.0);
          break;
        case OutsideJustification.endDrawArea:
          behaviorOffset = Offset(widthOffset,
              behavior.drawAreaBounds!.bottom - behaviorSize.height);
          break;
        case OutsideJustification.end:
          behaviorOffset =
              Offset(widthOffset, chartSize.height - behaviorSize.height);
          break;
      }
    } else if (behaviorPosition == BehaviorPosition.inside) {
      final rightOffset = Offset(chartSize.width - behaviorSize.width, 0.0);

      switch (insideJustification) {
        case InsideJustification.topStart:
          behaviorOffset = isRTL ? rightOffset : Offset.zero;
          break;
        case InsideJustification.topEnd:
          behaviorOffset = isRTL ? Offset.zero : rightOffset;
          break;
      }
    }

    return behaviorOffset;
  }

  _HorizontalJustification _getOutsideJustification(
      OutsideJustification justification, bool isRTL) {
    _HorizontalJustification mappedJustification;

    switch (justification) {
      case OutsideJustification.startDrawArea:
      case OutsideJustification.middleDrawArea:
        mappedJustification = isRTL
            ? _HorizontalJustification.rightDrawArea
            : _HorizontalJustification.leftDrawArea;
        break;
      case OutsideJustification.start:
      case OutsideJustification.middle:
        mappedJustification = isRTL
            ? _HorizontalJustification.right
            : _HorizontalJustification.left;
        break;
      case OutsideJustification.endDrawArea:
        mappedJustification = isRTL
            ? _HorizontalJustification.leftDrawArea
            : _HorizontalJustification.rightDrawArea;
        break;
      case OutsideJustification.end:
        mappedJustification = isRTL
            ? _HorizontalJustification.left
            : _HorizontalJustification.right;
        break;
    }

    return mappedJustification;
  }
}

enum _HorizontalJustification {
  leftDrawArea,
  left,
  rightDrawArea,
  right,
}

@immutable
class LifecycleListener<D> {
  const LifecycleListener({
    this.onData,
    this.onPreprocess,
    this.onPostprocess,
    this.onAxisConfigured,
    this.onPostrender,
    this.onAnimationComplete,
  });

  /// Called when data is drawn to the chart (not a redraw).
  ///
  /// This step is good for processing the data (running averages, percentage of
  /// first, etc). It can also be used to add Series of data (trend line) or
  /// remove a line as mentioned above, removing Series.
  final LifecycleSeriesListCallback<D>? onData;

  /// Called for every redraw given the original SeriesList resulting from the
  /// previous onData.
  ///
  /// This step is good for injecting default attributes on the Series before
  /// the renderers process the data (ex: before stacking measures).
  final LifecycleSeriesListCallback<D>? onPreprocess;

  /// Called after the chart and renderers get a chance to process the data but
  /// before the axes process them.
  ///
  /// This step is good if you need to alter the Series measure values after the
  /// renderers have processed them (ex: after stacking measures).
  final LifecycleSeriesListCallback<D>? onPostprocess;

  /// Called after the Axes have been configured.
  /// This step is good if you need to use the axes to get any cartesian
  /// location information. At this point Axes should be immutable and stable.
  final LifecycleEmptyCallback? onAxisConfigured;

  /// Called after the chart is done rendering passing along the canvas allowing
  /// a behavior or other listener to render on top of the chart.
  ///
  /// This is a convenience callback, however if there is any significant canvas
  /// interaction or stacking needs, it is preferred that a AplosView/ChartView
  /// is added to the chart instead to fully participate in the view stacking.
  final LifecycleCanvasCallback? onPostrender;

  /// Called after animation hits 100%. This allows a behavior or other listener
  /// to chain animations to create a multiple step animation transition.
  final LifecycleEmptyCallback? onAnimationComplete;
}

typedef LifecycleSeriesListCallback<D> = void Function(
    List<MutableSeries<D>> seriesList);
typedef LifecycleCanvasCallback = void Function(Canvas canvas);
typedef LifecycleEmptyCallback = void Function();
