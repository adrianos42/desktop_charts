// Copyright (C) 2023 Adriano Souza (adriano.souza113@gmail.com)

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../base_chart.dart' show LifecycleListener, BaseChart;
import '../../processed_series.dart' show MutableSeries;
import '../../selection_model.dart' show SelectionModel, SelectionModelType;
import '../chart_behavior.dart' show ChartBehaviorState;
import '../chart_behavior.dart'
    show
        BehaviorPosition,
        ChartBehavior,
        InsideJustification,
        OutsideJustification;
import 'legend_entry.dart';
import 'legend_entry_generator.dart';

/// Legend behavior for charts.
///
/// Since legends are desired to be customizable, building and displaying the
/// visual content of legends is done on the native platforms. This allows users
/// to specify customized content for legends using the native platform (ex. for
/// Flutter, using widgets).
abstract class Legend<D> extends ChartBehavior<D> {
  const Legend({
    BehaviorPosition position = BehaviorPosition.end,
    OutsideJustification outsideJustification =
        OutsideJustification.startDrawArea,
    InsideJustification insideJustification = InsideJustification.topStart,
    required this.selectionModelType,
    required this.legendEntryGeneratorBuilder,
    this.entryTextStyle,
  })  : _position = position,
        _insideJustification = insideJustification,
        _outsideJustification = outsideJustification;

  final SelectionModelType selectionModelType;

  final LegendEntryGeneratorBuilder<D> legendEntryGeneratorBuilder;

  final TextStyle? entryTextStyle;

  final BehaviorPosition _position;

  final OutsideJustification _outsideJustification;

  final InsideJustification _insideJustification;

  @override
  BehaviorPosition get position => _position;

  @override
  OutsideJustification get outsideJustification => _outsideJustification;

  @override
  InsideJustification get insideJustification => _insideJustification;

  @override
  String get role => 'legend-$selectionModelType';
}

/// Stores legend data used by native legend content builder.
abstract class LegendState<D, S extends BaseChart<D>, B extends Legend<D>>
    extends ChartBehaviorState<D, S, B> {
  LegendState({
    required super.behavior,
    required super.chartState,
  }) {
    legendEntryGenerator = behavior.legendEntryGeneratorBuilder();

    _lifecycleListener = LifecycleListener(
      onPostprocess: _postProcess,
      onPreprocess: _preProcess,
      onData: onData,
    );

    chartState.addLifecycleListener(_lifecycleListener);

    legendEntryGenerator.entryTextStyle = behavior.entryTextStyle;

    // Calling the setter will automatically use a non-null default value.
    showOverlaySeries = null;

    chartState
        .getSelectionModel(behavior.selectionModelType)
        .addSelectionChangedListener(_selectionChanged);
  }

  /// The title text to display before legend entries.
  late String title;

  late LifecycleListener<D> _lifecycleListener;

  List<LegendEntry<D>>? _legendEntries;
  SelectionModel<D>? _selectionModel;

  List<LegendEntry<D>>? get legendEntries => _legendEntries;
  SelectionModel<D>? get selectionModel => _selectionModel;

  LegendCellPadding? cellPadding;

  LegendCellPadding? legendPadding;

  /// Text style of the legend title text.
  TextStyle? titleTextStyle;

  late LegendEntryGenerator<D> legendEntryGenerator;

  /// Configures the behavior of the legend when the user taps/clicks on an
  /// entry. Defaults to no behavior.
  ///
  /// Tapping on a legend entry will update the data visible on the chart. For
  /// example, when [LegendTapHandling.hide] is configured, the series or datum
  /// associated with that entry will be removed from the chart. Tapping on that
  /// entry a second time will make the data visible again.
  LegendTapHandling legendTapHandling = LegendTapHandling.hide;

  /// List of series IDs in the order the series should appear in the legend.
  /// Series that are not specified in the ordering will be sorted
  /// alphabetically at the bottom.
  List<String>? _customEntryOrder;

  /// Save this in order to check if series list have changed and regenerate
  /// the legend entries.
  List<MutableSeries<D>>? _postProcessSeriesList;

  static final _decimalPattern = NumberFormat.decimalPattern();

  /// Default measure formatter for legends.
  @protected
  String defaultLegendMeasureFormatter(num? value) {
    return (value == null) ? '' : _decimalPattern.format(value);
  }

  /// Text style of the legend entry text.

  set entryTextStyle(TextStyle? entryTextStyle) {
    legendEntryGenerator.entryTextStyle = entryTextStyle;
  }

  set customEntryOrder(List<String>? customEntryOrder) {
    _customEntryOrder = customEntryOrder;
  }

  /// Whether or not the legend show overlay series.
  ///
  /// By default this is false, the overlay series are not shown on the legend.
  ///
  /// if [showOverlaySeries] is set to null, it is changed to the default of
  /// false.
  bool get showOverlaySeries => legendEntryGenerator.showOverlaySeries;

  set showOverlaySeries(bool? showOverlaySeries) {
    legendEntryGenerator.showOverlaySeries = showOverlaySeries ?? false;
  }

  late List<MutableSeries<D>> _currentSeriesList;

  /// Resets any hidden series data when data is drawn on the chart.
  @protected
  void onData(List<MutableSeries<D>> seriesList) {}

  /// Store off a copy of the series list for use when we render the legend.
  void _preProcess(List<MutableSeries<D>> seriesList) {
    _currentSeriesList = List.of(seriesList);
    preProcessSeriesList(seriesList);
  }

  /// Override method that may be used by concrete [Legend] instances to
  /// manipulate the series list.
  @protected
  void preProcessSeriesList(List<MutableSeries<D>> seriesList) {}

  /// Build LegendEntries from list of series.
  void _postProcess(List<MutableSeries<D>> seriesList) {
    // Get the selection model directly from chart on post process.
    //
    // This is because if initial selection is set as a behavior, it will be
    // handled during onData. onData is prior to this behavior's postProcess
    // call, so the selection will have changed prior to the entries being
    // generated.
    final selectionModel =
        chartState.getSelectionModel(behavior.selectionModelType);

    // Update entries if the selection model is different because post
    // process is called on each draw cycle, so this is called on each animation
    // frame and we don't want to update and request the native platform to
    // rebuild if nothing has changed.
    //
    // Also update legend entries if the series list has changed.
    if (_selectionModel != selectionModel ||
        _postProcessSeriesList != seriesList) {
      if (_customEntryOrder != null) {
        _currentSeriesList.sort((a, b) {
          final aIndex = _customEntryOrder!.indexOf(a.id);
          final bIndex = _customEntryOrder!.indexOf(b.id);
          if (aIndex == -1) {
            if (aIndex == bIndex) {
              return a.displayName!.compareTo(b.displayName!);
            }
            return 1;
          } else if (bIndex == -1) {
            return -1;
          }
          return aIndex.compareTo(bIndex);
        });
      }

      _legendEntries =
          legendEntryGenerator.getLegendEntries(_currentSeriesList);

      _selectionModel = selectionModel;
      _postProcessSeriesList = seriesList;
      _updateLegendEntries(seriesList: seriesList);
    }
  }

  // need to handle when series data changes, selection should be reset

  /// Update the legend state with [selectionModel] and request legend update.
  void _selectionChanged(SelectionModel<D> selectionModel) {
    _selectionModel = selectionModel;
    _updateLegendEntries();
  }

  /// Internally update legend entries, before calling [updateLegend] that
  /// notifies the native platform.
  void _updateLegendEntries({List<MutableSeries<D>>? seriesList}) {
    legendEntryGenerator.updateLegendEntries(_legendEntries!, _selectionModel!,
        seriesList ?? chartState.currentSeriesList);
  }

  bool get isRtl => chartState.chartContainerIsRtl;

  bool get isAxisFlipped => chartState.isRTL;

  @override
  void dispose() {
    chartState
        .getSelectionModel(behavior.selectionModelType)
        .removeSelectionChangedListener(_selectionChanged);
    chartState.removeLifecycleListener(_lifecycleListener);

    super.dispose();
  }
}

/// Stores legend cell padding, in percents or pixels.
///
/// If a percent is specified, it takes precedence over a flat pixel value.
class LegendCellPadding {
  /// Creates padding in percents from the left, top, right, and bottom.
  const LegendCellPadding.fromLTRBPct(
      this.leftPct, this.topPct, this.rightPct, this.bottomPct)
      : left = null,
        top = null,
        right = null,
        bottom = null;

  /// Creates padding in pixels from the left, top, right, and bottom.
  const LegendCellPadding.fromLTRB(this.left, this.top, this.right, this.bottom)
      : leftPct = null,
        topPct = null,
        rightPct = null,
        bottomPct = null;

  /// Creates padding in percents from the top, right, bottom, and left.
  const LegendCellPadding.fromTRBLPct(
      this.topPct, this.rightPct, this.bottomPct, this.leftPct)
      : top = null,
        right = null,
        bottom = null,
        left = null;

  /// Creates padding in pixels from the top, right, bottom, and left.
  const LegendCellPadding.fromTRBL(this.top, this.right, this.bottom, this.left)
      : topPct = null,
        rightPct = null,
        bottomPct = null,
        leftPct = null;

  /// Creates cell padding where all the offsets are `value` in percent.
  ///
  /// ## Sample code
  ///
  /// Typical eight percent margin on all sides:
  ///
  /// ```dart
  /// const LegendCellPadding.allPct(8.0)
  /// ```
  const LegendCellPadding.allPct(double value)
      : this.fromLTRBPct(value, value, value, value);

  /// Creates cell padding where all the offsets are `value` in pixels.
  ///
  /// ## Sample code
  ///
  /// Typical eight-pixel margin on all sides:
  ///
  /// ```dart
  /// const LegendCellPadding.all(8.0)
  /// ```
  const LegendCellPadding.all(double value)
      : this.fromLTRB(value, value, value, value);

  final double? bottomPct;
  final double? bottom;
  final double? leftPct;
  final double? left;
  final double? rightPct;
  final double? right;
  final double? topPct;
  final double? top;

  double getBttom(double height) =>
      bottomPct != null ? bottomPct! * height : bottom!;

  double getLeft(double width) => leftPct != null ? leftPct! * width : left!;

  double getRight(double width) =>
      rightPct != null ? rightPct! * width : right!;

  double getTop(double height) => topPct != null ? topPct! * height : top!;
}

/// Options for behavior of tapping/clicking on entries in the legend.
enum LegendTapHandling {
  /// No associated behavior.
  none,

  /// Hide elements on the chart associated with this legend entry.
  hide,
}
