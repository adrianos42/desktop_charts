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
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../data/data.dart';
import '../date_time_factory.dart' show DateTimeFactory, LocalDateTimeFactory;
import '../rtl_spec.dart' show RTLSpec;
import '../theme.dart';
import 'behavior/behavior.dart'
    show
        ChartBehavior,
        ChartBehaviorState,
        BehaviorPosition,
        InsideJustification,
        OutsideJustification,
        SelectNearest,
        SelectionTrigger;
import 'chart_context.dart' show ChartContext;
import 'datum_details.dart' show DatumDetails;
import 'processed_series.dart' show MutableSeries;
import 'selection_model.dart'
    show SelectionModelType, SelectionModelListener, MutableSelectionModel;
import 'selection_model_config.dart' show SelectionModelConfig;
import 'series_datum.dart' show SeriesDatum;
import 'series_renderer.dart'
    show SeriesRenderer, SeriesRendererRender, rendererIdKey, rendererKey;
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
  CurvedAnimation get animationPosition => _animationPosition;

  final _lifecycleListeners = <LifecycleListener<D>>[];

  @protected
  List<LifecycleListener<D>> get lifecycleListeners => _lifecycleListeners;

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
  //final addedBehaviorsByRole =
  //    <String, ChartBehaviorState<D, BaseChart<D>, ChartBehavior<D>>>{};

  final addedSelectionChangedListenersByType =
      <SelectionModelType, SelectionModelListener<D>>{};
  final addedSelectionUpdatedListenersByType =
      <SelectionModelType, SelectionModelListener<D>>{};

  final _behaviorAnimationControllers =
      <ChartBehavior<D>, AnimationController>{};

  /// List of series that are currently drawn on the chart.
  ///
  /// This list should be used by interactive behaviors between chart draw
  /// cycles. It may be filtered or modified by some behaviors during the
  /// initial draw cycle (e.g. a [Legend] may hide some series).
  List<MutableSeries<D>>? _currentSeriesList;

  /// List of series that were passed into the previous draw call.
  ///
  /// This list will be used when redraw is called, to reset the state of all
  /// behaviors to the original list.
  late List<MutableSeries<D>> _originalSeriesList;

  late Map<String, List<MutableSeries<D>>> _rendererToSeriesList;

  Set<String> _usingRenderers = <String>{};

  final _seriesRenderers = <String, SeriesRenderer<D, S>>{};
  final _seriesRenderersKeys = <String, GlobalKey>{};

  /// Map of named chart behaviors attached to this chart.
  final _behaviorRoles = <String, ChartBehaviorState<D, S, ChartBehavior<D>>>{};
  final _behaviorStack = <ChartBehaviorState<D, S, ChartBehavior<D>>>[];

  @protected
  Map<String, ChartBehaviorState<D, S, ChartBehavior<D>>> get behaviorRoles =>
      _behaviorRoles;

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

  static const chartLayoutID = 'chart';

  bool _deferAnimation = false;

  @protected
  bool get deferAnimation => _deferAnimation;

  void _playAnimation(Duration duration) {
    if (!_deferAnimation) {
      _animationController.duration = duration;
      _animationController.forward(from: 0.0);
    }
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
    // for (int i = addedBehaviorWidgets.length - 1; i >= 0; i--) {
    //   final addedBehavior = addedBehaviorWidgets[i];
    //   if (!behaviorList.remove(addedBehavior)) {
    //     final role = addedBehavior.role;
    //     addedBehaviorWidgets.remove(addedBehavior);
    //     addedCommonBehaviorsByRole.remove(role);
    //     removeBehavior(addedCommonBehaviorsByRole[role]);
    //   }
    // }

    // Add any remaining/behaviors.
    for (final behavior in behaviorList) {
      final behaviorState = behavior.build(chartState: this);
      _behaviorStack.add(behaviorState);
      _behaviorRoles[behavior.role] = behaviorState;
      // addBehavior(behavior);
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
    // for (final type in prevTypes) {
    //   getSelectionModel(type)
    //     ..removeSelectionChangedListener(
    //       addedSelectionChangedListenersByType[type]!,
    //     )
    //     ..removeSelectionUpdatedListener(
    //       addedSelectionUpdatedListenersByType[type]!,
    //     );
    // }
  }

  void _updateUserManagedState() {
    if (widget.userManagedState == null) {
      return;
    }

    // Only override the selection model if it is different than the existing
    // selection model so update listeners are not unnecessarily triggered.
    for (final SelectionModelType type
        in widget.userManagedState!.selectionModels.keys) {
      final model = getSelectionModel(type);

      final userModel = widget.userManagedState!.selectionModels[type]!
          .getModel(currentSeriesList);

      if (model != userModel) {
        model.updateSelection(
            userModel.selectedDatum, userModel.selectedSeries);
      }
    }
  }

  @override
  bool get isRTL => Directionality.of(context) == TextDirection.rtl;

  @override
  bool get chartContainerIsRtl => isRTL;

  @override
  RTLSpec? get rtlSpec => widget.rtlSpec;

  @override
  bool get isVertical => false;

  @override
  DateTimeFactory get dateTimeFactory => const LocalDateTimeFactory();

  @override
  void requestAnimation([Duration? value]) {
    _playAnimation(value ?? transition);
  }

  @override
  void requestPaint() {
    setState(() {});
  }

  // @override
  // void enableA11yExploreMode(List<A11yNode> nodes, {String? announcement}) {
  //   throw 'Not implemented';
  // }

  //@override
  //void disableA11yExploreMode({
  //  String? announcement,
  //}) {
  //  throw 'Not implemented';
  //}

  @override
  ChartsThemeData get themeData => ChartsTheme.of(context);

  Duration get transition =>
      widget.animate ? widget.animationDuration : Duration.zero;

  /// Returns MutableSelectionModel for the given type. Lazy creates one upon first
  /// request.
  MutableSelectionModel<D> getSelectionModel(SelectionModelType type) {
    return _selectionModels.putIfAbsent(type, () => MutableSelectionModel<D>());
  }

  /// Returns a list of datum details from selection model of [type].
  List<DatumDetails<D>> getDatumDetails(SelectionModelType type);

  SeriesRenderer<D, S>? get defaultRenderer =>
      getSeriesRenderer(SeriesRenderer.defaultRendererId);

  SeriesRenderer<D, S>? getSeriesRenderer(String? rendererId) {
    return _seriesRenderers[rendererId];
  }

  SeriesRendererRender<D, S>? getSeriesRendererRender(String? rendererId) {
    return _seriesRenderersKeys[rendererId]?.currentContext?.findRenderObject()
        as SeriesRendererRender<D, S>?;
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
    final boundsOverride = selectAcrossAllDrawAreaComponents ? null : null;

    final details = <DatumDetails<D>>[];

    for (final rendererId in _usingRenderers) {
      details.addAll(
          getSeriesRendererRender(rendererId)!.getNearestDatumDetailPerSeries(
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

  /// Returns a list of behaviors that have been added.
  List<ChartBehavior<D>> get behaviors =>
      List.unmodifiable(_behaviorStack.map((e) => e.behavior));

  void _fireOnPreprocess(List<MutableSeries<D>> seriesList) {
    for (final listener in _lifecycleListeners) {
      listener.onPreprocess?.call(seriesList);
    }
  }

  void _fireOnPostprocess(List<MutableSeries<D>> seriesList) {
    for (final listener in _lifecycleListeners) {
      listener.onPostprocess?.call(seriesList);
    }
  }

  void _fireOnDraw(List<MutableSeries<D>> seriesList) {
    for (final listener in _lifecycleListeners) {
      listener.onData?.call(seriesList);
    }
  }

  @protected
  void _fireOnAnimationComplete() {
    for (final listener in _lifecycleListeners) {
      listener.onAnimationComplete?.call();
    }
  }

  void _updateList() {
    // Clear the selection model when [seriesList] changes.
    for (final selectionModel in _selectionModels.values) {
      selectionModel.clearSelection(notifyListeners: false);
    }

    _originalSeriesList = List.of(
      widget.seriesList.map<MutableSeries<D>>(makeSeries),
      growable: false,
    );

    _fireOnDraw(_originalSeriesList);

    // Set an index on the series list.
    // This can be used by listeners of selection to determine the order of
    // series, because the selection details are not returned in this order.
    int seriesIndex = 0;

    for (final series in _originalSeriesList) {
      series.seriesIndex = seriesIndex += 1;
    }

    _currentSeriesList = _originalSeriesList;
  }

  //
  // Draw methods
  //
  void _draw({
    bool skipAnimation = false,
  }) {
    if (_deferAnimation) {
      throw 'Invalid draw state.';
    }

    final seriesList = _originalSeriesList
        .map((MutableSeries<D> series) => MutableSeries<D>.clone(series))
        .toList();

    configureSeries(seriesList);

    // Allow listeners to manipulate the seriesList.
    _fireOnPreprocess(seriesList);

    _rendererToSeriesList = preprocessSeries(seriesList);

    // Allow listeners to manipulate the processed seriesList.
    _fireOnPostprocess(seriesList);

    _currentSeriesList = seriesList;

    _updateUserManagedState();

    for (final rendererId in _usingRenderers) {
      getSeriesRendererRender(rendererId)?.markNeedsUpdate();
    }

    if (!skipAnimation && transition > Duration.zero) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        onPostLayout(_rendererToSeriesList);
      });
      _playAnimation(transition);
    } else {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        onPostLayout(_rendererToSeriesList);
        _animationController.value = 1.0;
      });
    }
  }

  @mustCallSuper
  void onPostLayout(Map<String, List<MutableSeries<D>>> rendererToSeriesList) {}

  /// Preprocess series to assign missing color functions.
  @mustCallSuper
  void configureSeries(List<MutableSeries<D>> seriesList) {
    final rendererToSeriesList = <String?, List<MutableSeries<D>>>{};

    // Build map of rendererIds to SeriesLists. This map can't be re-used later
    // in the preprocessSeries call because some behaviors might alter the
    // seriesList.
    for (final series in seriesList) {
      final rendererId = series.getAttr(rendererIdKey);
      rendererToSeriesList.putIfAbsent(rendererId, () => []).add(series);
    }

    // Have each renderer add missing color functions to their seriesLists.
    rendererToSeriesList
        .forEach((String? rendererId, List<MutableSeries<D>> seriesList) {
      final renderer = getSeriesRenderer(rendererId)!;
      renderer.configureSeries(seriesList);
    });
  }

  @mustCallSuper
  Map<String, List<MutableSeries<D>>> preprocessSeries(
      List<MutableSeries<D>> seriesList) {
    final rendererToSeriesList = <String, List<MutableSeries<D>>>{};

    final unusedRenderers = _usingRenderers;
    _usingRenderers = <String>{};

    for (final series in seriesList) {
      final rendererId = series.getAttr(rendererIdKey);
      rendererToSeriesList.putIfAbsent(rendererId!, () => []).add(series);

      _usingRenderers.add(rendererId);
      unusedRenderers.remove(rendererId);
    }

    for (final rendererId in unusedRenderers) {
      rendererToSeriesList[rendererId] = [];
    }

    rendererToSeriesList.forEach((rendererId, seriesList) {
      getSeriesRenderer(rendererId)!.preprocessSeries(seriesList);
    });

    return rendererToSeriesList;
  }

  void redraw({
    bool skipAnimation = false,
  }) {
    setState(() {
      if (!_deferAnimation) {
        _draw(skipAnimation: skipAnimation);
      }
    });
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

  void setAnimation(Duration value) {
    _animationController.reset();
    _playAnimation(value);
  }

  @protected
  void animationCompleted() {
    _fireOnAnimationComplete();
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this);
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          animationCompleted();
        });
      }
    });

    _animationPosition = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInSine,
    );

    _seriesRenderers[SeriesRenderer.defaultRendererId] =
        widget.defaultRenderer!.build(
      chartState: this,
      rendererId: SeriesRenderer.defaultRendererId,
    );
    _seriesRenderersKeys[SeriesRenderer.defaultRendererId] = GlobalKey();

    if (widget.customSeriesRenderers != null) {
      for (final customSeriesRenderer in widget.customSeriesRenderers!) {
        if (customSeriesRenderer.customRendererId == null) {
          throw 'The `customRendererId` in `customSeriesRenderers` cannot be null.';
        }
        if (_seriesRenderers
            .containsKey(customSeriesRenderer.customRendererId)) {
          throw 'Cannot have duplicate keys in `customSeriesRenderers`.';
        }
        _seriesRenderers[customSeriesRenderer.customRendererId!] =
            customSeriesRenderer.build(
          chartState: this,
          rendererId: customSeriesRenderer.customRendererId,
        );
        _seriesRenderersKeys[customSeriesRenderer.customRendererId!] =
            GlobalKey();
      }
    }

    _updateSelectionModel();
    _updateBehaviors();
    _updateList();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _deferAnimation = !TickerMode.of(context);

    if (_deferAnimation) {
      _rendererToSeriesList = <String, List<MutableSeries<D>>>{};

      for (final series in _originalSeriesList) {
        final rendererId = series.getAttr(rendererIdKey);
        _rendererToSeriesList.putIfAbsent(rendererId!, () => []).add(series);
      }

      return;
    }

    _draw();
  }

  @protected
  @mustCallSuper
  bool didUpdateWidgetNeedsDrawing(covariant S oldWidget) {
    final customSeriesRenderers = widget.customSeriesRenderers ?? [];
    final oldCustomSeriesRenderers = oldWidget.customSeriesRenderers ?? [];

    bool needsDrawing = false;

    if (widget.defaultRenderer != oldWidget.defaultRenderer) {
      _seriesRenderers[SeriesRenderer.defaultRendererId] =
          widget.defaultRenderer!.build(
        chartState: this,
        rendererId: SeriesRenderer.defaultRendererId,
      );
      _seriesRenderersKeys[SeriesRenderer.defaultRendererId] = GlobalKey();

      needsDrawing = true;
    }

    if (widget.selectionModels != oldWidget.selectionModels) {
      _updateSelectionModel();
      needsDrawing = true;
    }

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
        _seriesRenderers[customSeriesRenderer.customRendererId!] =
            customSeriesRenderer.build(
          chartState: this,
          rendererId: customSeriesRenderer.customRendererId,
        );
        _seriesRenderersKeys[customSeriesRenderer.customRendererId!] =
            GlobalKey();
      }

      needsDrawing = true;
    } else if (customSeriesRenderers.length < oldCustomSeriesRenderers.length) {
      for (int i = customSeriesRenderers.length;
          i < oldCustomSeriesRenderers.length;
          i += 1) {
        final customSeriesRenderer = oldCustomSeriesRenderers[i];
        _seriesRenderers.remove(customSeriesRenderer.customRendererId);
        _seriesRenderersKeys.remove(customSeriesRenderer.customRendererId);
      }

      needsDrawing = true;
    }

    if (!ListEquality<Series<dynamic, D>>()
        .equals(widget.seriesList, oldWidget.seriesList)) {
      _updateBehaviors();
      _updateList();
      needsDrawing = true;
    }

    return needsDrawing;
  }

  @override
  void didUpdateWidget(covariant S oldWidget) {
    super.didUpdateWidget(oldWidget);

    _deferAnimation = !TickerMode.of(context);

    if (didUpdateWidgetNeedsDrawing(oldWidget) && !_deferAnimation) {
      _draw();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _animationPosition.dispose();
    _behaviorAnimationControllers
        .forEach((_, controller) => controller.dispose());
    _behaviorAnimationControllers.clear();

    _behaviorStack.clear();
    _behaviorRoles.clear();

    for (final selectionModel in _selectionModels.values) {
      selectionModel.clearAllListeners();
    }

    // dataNotifier.dispose();
    // preprocessNotifier.dispose();
    // postprocessNotifier.dispose();
    // axisConfiguredNotifier.dispose();
    // postrenderNotifier.dispose();
    //animationCompleteNotifier.dispose();

    super.dispose();
  }

  @mustCallSuper
  Widget buildChart() {
    final chartChildren = <LayoutId>[];
    final idAndBehaviors = <String, ChartBehavior<D>>{};

    chartChildren.add(
      LayoutId(
        id: chartLayoutID,
        child: Stack(
          children: [
            defaultRenderer!.build(
              context,
              seriesList:
                  _rendererToSeriesList[SeriesRenderer.defaultRendererId]!,
              key: _seriesRenderersKeys[SeriesRenderer.defaultRendererId]!,
            ),
            ...widget.customSeriesRenderers?.map((customSeriesRenderer) {
                  final customRendererId =
                      customSeriesRenderer.customRendererId!;

                  return _seriesRenderers[customRendererId]!.build(
                    context,
                    seriesList: _rendererToSeriesList[
                        customSeriesRenderer.customRendererId!]!,
                    key: _seriesRenderersKeys[
                        customSeriesRenderer.customRendererId!]!,
                  );
                }).toList() ??
                [],
          ],
        ),
      ),
    );

    // Ignore if there's only `SelectNearest` behavior added.
    if (_behaviorRoles.length > 1) {
      _behaviorRoles.forEach((id, behaviorState) {
        if (behaviorState.behavior.position == BehaviorPosition.inside) {
          assert(id != chartLayoutID);

          idAndBehaviors[id] = behaviorState.behavior;

          chartChildren.add(
            LayoutId(
              id: id,
              child: behaviorState.buildBehaviorWidget(context),
            ),
          );
        }
      });
    }

    return CustomMultiChildLayout(
      delegate: WidgetLayoutDelegate<D, S, ChartBehavior<D>>(
        chartID: chartLayoutID,
        idAndBehavior: idAndBehaviors,
        isRTL: isRTL,
      ),
      children: chartChildren,
    );
  }

  @override
  Widget build(BuildContext context) {
    final chartChildren = <LayoutId>[];
    final idAndBehaviorMap = <String, ChartBehavior<D>>{};

    chartChildren.add(
      LayoutId(
        id: chartLayoutID,
        child: buildChart(),
      ),
    );

    // Ignore if there's only `SelectNearest` behavior added.
    if (_behaviorRoles.length > 1) {
      // Add widget for each behavior that can build widgets
      _behaviorRoles.forEach((id, behaviorState) {
        if (behaviorState.behavior.position == BehaviorPosition.start ||
            behaviorState.behavior.position == BehaviorPosition.top ||
            behaviorState.behavior.position == BehaviorPosition.end ||
            behaviorState.behavior.position == BehaviorPosition.bottom) {
          assert(id != chartLayoutID);

          idAndBehaviorMap[id] = behaviorState.behavior;

          chartChildren.add(
            LayoutId(
              id: id,
              child: behaviorState.buildBehaviorWidget(context),
            ),
          );
        }
      });
    }

    final result = Padding(
      padding: const EdgeInsets.all(12.0),
      child: RepaintBoundary(
        child: CustomMultiChildLayout(
          delegate: WidgetLayoutDelegate<D, S, ChartBehavior<D>>(
            chartID: chartLayoutID,
            idAndBehavior: idAndBehaviorMap,
            isRTL: isRTL,
          ),
          children: chartChildren,
        ),
      ),
    );

    return result;
  }
}

/// Layout delegate that layout chart widget with [Behavior] widgets.
class WidgetLayoutDelegate<D, S extends BaseChart<D>,
    B extends ChartBehavior<D>> extends MultiChildLayoutDelegate {
  WidgetLayoutDelegate({
    this.chartID,
    required this.idAndBehavior,
    required this.isRTL,
  });

  /// ID of the common chart widget.
  final String? chartID;

  /// Directionality of the widget.
  final bool isRTL;

  /// ID and [Behavior] of the widgets for calculating offset.
  final Map<String, B> idAndBehavior;

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
    if (chartID != null && hasChild(chartID!)) {
      layoutChild(
        chartID!,
        BoxConstraints.tightFor(
          width: availableWidth,
          height: availableHeight,
        ),
      );

      positionChild(chartID!, Offset(chartOffsetX, chartOffsetY));
    }

    final chartSize = Size(availableWidth, availableHeight);

    for (final behaviorID in behaviorIDs) {
      final behaviorOffset = _getBehaviorOffset(
        idAndBehavior[behaviorID]!,
        behaviorSize: behaviorSize[behaviorID]!,
        chartSize: chartSize,
        isRTL: isRTL,
        drawAreaBounds: Offset.zero & chartSize,
      );

      positionChild(behaviorID, behaviorOffset);
    }
  }

  @override
  bool shouldRelayout(MultiChildLayoutDelegate oldDelegate) {
    // TODO: Deep equality check because the instance will not be
    // the same on each build, even if the buildable behavior has not changed.
    return idAndBehavior != (oldDelegate as WidgetLayoutDelegate).idAndBehavior;
  }

  // Calculate behavior's offset.
  Offset _getBehaviorOffset(
    ChartBehavior behavior, {
    required Size behaviorSize,
    required Size chartSize,
    required bool isRTL,
    required Rect drawAreaBounds,
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

      behaviorOffset = switch (horizontalJustification) {
        _HorizontalJustification.leftDrawArea =>
          Offset(drawAreaBounds.left.toDouble(), heightOffset),
        _HorizontalJustification.left => behaviorOffset =
            Offset(0.0, heightOffset),
        _HorizontalJustification.rightDrawArea => behaviorOffset = Offset(
            drawAreaBounds.right - behaviorSize.width,
            heightOffset,
          ),
        _HorizontalJustification.right => behaviorOffset =
            Offset(chartSize.width - behaviorSize.width, heightOffset),
      };
    } else if (behaviorPosition == BehaviorPosition.start ||
        behaviorPosition == BehaviorPosition.end) {
      final widthOffset =
          (isRTL && behaviorPosition == BehaviorPosition.start) ||
                  (!isRTL && behaviorPosition == BehaviorPosition.end)
              ? chartSize.width
              : 0.0;

      behaviorOffset = switch (outsideJustification) {
        OutsideJustification.startDrawArea ||
        OutsideJustification.middleDrawArea =>
          Offset(widthOffset, drawAreaBounds.top),
        OutsideJustification.start ||
        OutsideJustification.middle =>
          Offset(widthOffset, 0.0),
        OutsideJustification.endDrawArea =>
          Offset(widthOffset, drawAreaBounds.bottom - behaviorSize.height),
        OutsideJustification.end =>
          Offset(widthOffset, chartSize.height - behaviorSize.height),
      };
    } else if (behaviorPosition == BehaviorPosition.inside ||
        behaviorPosition == BehaviorPosition.insideBelowAxis) {
      final rightOffset = Offset(chartSize.width - behaviorSize.width, 0.0);

      behaviorOffset = switch (insideJustification) {
        InsideJustification.topStart => isRTL ? rightOffset : Offset.zero,
        InsideJustification.topEnd => isRTL ? Offset.zero : rightOffset,
      };
    }

    return behaviorOffset;
  }

  _HorizontalJustification _getOutsideJustification(
      OutsideJustification justification, bool isRTL) {
    return switch (justification) {
      OutsideJustification.startDrawArea ||
      OutsideJustification.middleDrawArea =>
        isRTL
            ? _HorizontalJustification.rightDrawArea
            : _HorizontalJustification.leftDrawArea,
      OutsideJustification.start ||
      OutsideJustification.middle =>
        isRTL ? _HorizontalJustification.right : _HorizontalJustification.left,
      OutsideJustification.endDrawArea => isRTL
          ? _HorizontalJustification.leftDrawArea
          : _HorizontalJustification.rightDrawArea,
      OutsideJustification.end =>
        isRTL ? _HorizontalJustification.left : _HorizontalJustification.right,
    };
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

  /// Called after animation hits 100%. This allows a behavior or other listener
  /// to chain animations to create a multiple step animation transition.
  final LifecycleEmptyCallback? onAnimationComplete;
}

typedef LifecycleSeriesListCallback<D> = void Function(
    List<MutableSeries<D>> seriesList);
typedef LifecycleCanvasCallback = void Function(Canvas canvas);
typedef LifecycleEmptyCallback = void Function();
