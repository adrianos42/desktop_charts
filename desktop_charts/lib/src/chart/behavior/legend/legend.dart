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

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';

import '../../base_chart.dart'
    show BaseChartState, LifecycleListener, BaseChart;
import '../../layout/layout_view.dart' show LayoutPosition, layoutPosition;
import '../../processed_series.dart' show MutableSeries;
import '../../selection_model.dart' show SelectionModel, SelectionModelType;
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
  Legend({
    required this.selectionModelType,
    required this.legendEntryGenerator,
    TextStyle? entryTextStyle,
  }) {
    _lifecycleListener = LifecycleListener(
        onPostprocess: _postProcess, onPreprocess: _preProcess, onData: onData);
    legendEntryGenerator.entryTextStyle = entryTextStyle;

    // Calling the setter will automatically use a non-null default value.
    showOverlaySeries = null;
  }

  final SelectionModelType selectionModelType;
  final legendState = LegendState<D>();
  final LegendEntryGenerator<D> legendEntryGenerator;

  /// The title text to display before legend entries.
  late String title;

  late BaseChartState<D, BaseChart<D>> _chart;
  late final LifecycleListener<D> _lifecycleListener;

  Rect? _componentBounds;
  Rect? _drawAreaBounds;

  BehaviorPosition behaviorPosition = BehaviorPosition.end;
  OutsideJustification outsideJustification =
      OutsideJustification.startDrawArea;
  InsideJustification insideJustification = InsideJustification.topStart;
  LegendCellPadding? cellPadding;
  LegendCellPadding? legendPadding;

  /// Text style of the legend title text.
  TextStyle? titleTextStyle;

  /// Configures the behavior of the legend when the user taps/clicks on an
  /// entry. Defaults to no behavior.
  ///
  /// Tapping on a legend entry will update the data visible on the chart. For
  /// example, when [LegendTapHandling.hide] is configured, the series or datum
  /// associated with that entry will be removed from the chart. Tapping on that
  /// entry a second time will make the data visible again.
  LegendTapHandling legendTapHandling = LegendTapHandling.hide;

  late List<MutableSeries<D>> _currentSeriesList;

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
  TextStyle? get entryTextStyle => legendEntryGenerator.entryTextStyle;

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
    final selectionModel = chart.getSelectionModel(selectionModelType);

    // Update entries if the selection model is different because post
    // process is called on each draw cycle, so this is called on each animation
    // frame and we don't want to update and request the native platform to
    // rebuild if nothing has changed.
    //
    // Also update legend entries if the series list has changed.
    if (legendState._selectionModel != selectionModel ||
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

      legendState._legendEntries =
          legendEntryGenerator.getLegendEntries(_currentSeriesList);

      legendState._selectionModel = selectionModel;
      _postProcessSeriesList = seriesList;
      _updateLegendEntries(seriesList: seriesList);
    }
  }

  // need to handle when series data changes, selection should be reset

  /// Update the legend state with [selectionModel] and request legend update.
  void _selectionChanged(SelectionModel<D> selectionModel) {
    legendState._selectionModel = selectionModel;
    _updateLegendEntries();
  }

  /// Internally update legend entries, before calling [updateLegend] that
  /// notifies the native platform.
  void _updateLegendEntries({List<MutableSeries<D>>? seriesList}) {
    legendEntryGenerator.updateLegendEntries(legendState._legendEntries,
        legendState._selectionModel!, seriesList ?? chart.currentSeriesList);

    updateLegend();
  }

  /// Requires override to show in native platform
  void updateLegend() {}

  @override
  void attachTo<S extends BaseChart<D>>(BaseChartState<D, S> chart) {
    _chart = chart;
    chart.addLifecycleListener(_lifecycleListener);
    chart
        .getSelectionModel(selectionModelType)
        .addSelectionChangedListener(_selectionChanged);

    // TODO chart.addView(this);
  }

  @override
  void removeFrom<S extends BaseChart<D>>(BaseChartState<D, S> chart) {
    chart
        .getSelectionModel(selectionModelType)
        .removeSelectionChangedListener(_selectionChanged);
    chart.removeLifecycleListener(_lifecycleListener);

    // TODO chart.removeView(this);
  }

  @protected
  BaseChartState<D, BaseChart<D>> get chart => _chart;

  @override
  String get role => 'legend-$selectionModelType';

  bool get isRtl => _chart.chartContainerIsRtl;

  bool get isAxisFlipped => _chart.isRTL;

  //@override
  //LayoutViewConfig get layoutConfig {
  //  return LayoutViewConfig(
  //    position: _layoutPosition,
  //    positionOrder: LayoutViewPositionOrder.legend,
  //    paintOrder: LayoutViewPaintOrder.legend,
  //  );
  //}

  /// Get layout position from legend position.
  LayoutPosition get _layoutPosition {
    return layoutPosition(behaviorPosition, outsideJustification, isRtl);
  }

  @override
  Size measure(double maxWidth, double maxHeight) {
    // Native child classes should override this method to return real
    // measurements.
    // return const ViewMeasuredSizes(preferredWidth: 0, preferredHeight: 0);
    return Size.zero;
  }

  @override
  void layout(Rect componentBounds, Rect drawAreaBounds) {
    _componentBounds = componentBounds;
    _drawAreaBounds = drawAreaBounds;

    updateLegend();
  }

  @override
  void paint(Canvas canvas, double animationPercent) {}

  // Gets the draw area bounds for native legend content to position itself
  // accordingly.
  Rect? get drawAreaBounds => _drawAreaBounds;
}

/// Stores legend data used by native legend content builder.
class LegendState<D> {
  late List<LegendEntry<D>> _legendEntries;
  SelectionModel<D>? _selectionModel;

  List<LegendEntry<D>> get legendEntries => _legendEntries;
  SelectionModel<D>? get selectionModel => _selectionModel;
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
