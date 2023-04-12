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

import 'package:desktop/desktop.dart';
import 'package:flutter/rendering.dart';

import '../../datum_details.dart' show MeasureFormatter;
import '../../processed_series.dart' show MutableSeries;
import '../../selection_model.dart' show SelectionModelType;
import '../../../symbol_renderer.dart' show SymbolRenderer;
import 'legend.dart';
import 'legend_entry_generator.dart';
import 'per_series_legend_entry_generator.dart';
import '../chart_behavior.dart' show BehaviorPosition;
import '../../../symbol_renderer.dart';

// TODO: Allows for hovering over a series in legend to highlight
// corresponding series in draw area.

/// Series legend behavior for charts.
///
/// By default this behavior creates a legend entry per series.
class SeriesLegend<D> extends Legend<D> {
  SeriesLegend({
    SelectionModelType? selectionModelType,
    LegendEntryGenerator<D>? legendEntryGenerator,
    MeasureFormatter? measureFormatter,
    MeasureFormatter? secondaryMeasureFormatter,
    bool? showMeasures,
    LegendDefaultMeasure? legendDefaultMeasure,
    TextStyle? entryTextStyle,
    super.position,
  }) : super(
          selectionModelType: selectionModelType ?? SelectionModelType.info,
          legendEntryGenerator:
              legendEntryGenerator ?? PerSeriesLegendEntryGenerator(),
          entryTextStyle: entryTextStyle,
        ) {
    // Calling the setters will automatically use non-null default values.
    this.showMeasures = showMeasures;
    this.legendDefaultMeasure = legendDefaultMeasure;
    this.measureFormatter = measureFormatter;
    this.secondaryMeasureFormatter = secondaryMeasureFormatter;
  }

  /// List of currently hidden series, by ID.
  final _hiddenSeriesList = <String>{};

  /// List of series IDs that should be hidden by default.
  List<String>? _defaultHiddenSeries;

  /// List of series IDs that should not be hideable.
  List<String>? _alwaysVisibleSeries;

  /// Whether or not the series legend should show measures on datum selection.
  late bool _showMeasures;

  /// Sets a list of series IDs that should be hidden by default on first chart
  /// draw.
  ///
  /// This will also reset the current list of hidden series, filling it in with
  /// the default list.
  set defaultHiddenSeries(List<String>? defaultHiddenSeries) {
    _defaultHiddenSeries = defaultHiddenSeries;

    _hiddenSeriesList.clear();

    _defaultHiddenSeries?.forEach(hideSeries);
  }

  /// Gets a list of series IDs that should be hidden by default on first chart
  /// draw.
  List<String>? get defaultHiddenSeries => _defaultHiddenSeries;

  /// Sets a list of series IDs that should always be visible and therefore
  /// cannot be hidden.
  ///
  /// This also shows any series that should always be visible in case
  /// it was previously hidden.
  set alwaysVisibleSeries(List<String>? alwaysVisibleSeries) {
    _alwaysVisibleSeries = alwaysVisibleSeries;
    _alwaysVisibleSeries?.forEach(showSeries);
  }

  /// Gets a list of series IDs that should always be visible.
  List<String>? get alwaysVisibleSeries => _alwaysVisibleSeries;

  /// Whether or not the legend should show measures.
  ///
  /// By default this is false, measures are not shown. When set to true, the
  /// default behavior is to show measure only if there is selected data.
  /// Please set [legendDefaultMeasure] to something other than none to enable
  /// showing measures when there is no selection.
  ///
  /// If [showMeasures] is set to null, it is changed to the default of false.
  bool get showMeasures => _showMeasures;

  set showMeasures(bool? showMeasures) {
    _showMeasures = showMeasures ?? false;
  }

  /// Option to show measures when selection is null.
  ///
  /// By default this is set to none, so no measures are shown when there is
  /// no selection.
  ///
  /// If [legendDefaultMeasure] is set to null, it is changed to the default of
  /// none.
  LegendDefaultMeasure get legendDefaultMeasure =>
      legendEntryGenerator.legendDefaultMeasure;

  set legendDefaultMeasure(LegendDefaultMeasure? legendDefaultMeasure) {
    legendEntryGenerator.legendDefaultMeasure =
        legendDefaultMeasure ?? LegendDefaultMeasure.none;
  }

  /// Formatter for measure values.
  ///
  /// This is optional. The default formatter formats measure values with
  /// NumberFormat.decimalPattern. If the measure value is null, a dash is
  /// returned.
  set measureFormatter(MeasureFormatter? formatter) {
    legendEntryGenerator.measureFormatter =
        formatter ?? defaultLegendMeasureFormatter;
  }

  /// Formatter for measure values of series that uses the secondary axis.
  ///
  /// This is optional. The default formatter formats measure values with
  /// NumberFormat.decimalPattern. If the measure value is null, a dash is
  /// returned.
  set secondaryMeasureFormatter(MeasureFormatter? formatter) {
    legendEntryGenerator.secondaryMeasureFormatter =
        formatter ?? defaultLegendMeasureFormatter;
  }

  /// Remove series IDs from the currently hidden list if those series have been
  /// removed from the chart data. The goal is to allow any metric that is
  /// removed from a chart, and later re-added to it, to be visible to the user.
  @override
  void onData(List<MutableSeries<D>> seriesList) {
    // If a series was removed from the chart, remove it from our current list
    // of hidden series.
    final seriesIds = seriesList.map((MutableSeries<D> series) => series.id);

    _hiddenSeriesList.removeWhere((String id) => !seriesIds.contains(id));
  }

  @override
  void preProcessSeriesList(List<MutableSeries<D>> seriesList) {
    seriesList.removeWhere((MutableSeries<D> series) {
      return _hiddenSeriesList.contains(series.id);
    });
  }

  /// Hides the data for a series on the chart by [seriesId].
  ///
  /// The entry in the legend for this series will be grayed out to indicate
  /// that it is hidden.
  @protected
  void hideSeries(String seriesId) {
    if (!isSeriesAlwaysVisible(seriesId)) {
      _hiddenSeriesList.add(seriesId);
    }
  }

  /// Shows the data for a series on the chart by [seriesId].
  ///
  /// The entry in the legend for this series will be returned to its normal
  /// color if it was previously hidden.
  @protected
  void showSeries(String seriesId) {
    _hiddenSeriesList.removeWhere((String id) => id == seriesId);
  }

  /// Returns whether or not a given series [seriesId] is currently hidden.
  bool isSeriesHidden(String seriesId) {
    return _hiddenSeriesList.contains(seriesId);
  }

  /// Returns whether or not a given series is always visible.
  bool isSeriesAlwaysVisible(String seriesId) {
    return _alwaysVisibleSeries != null &&
        _alwaysVisibleSeries!.contains(seriesId);
  }

  @override
  void updateLegend() {
    chartState.requestPaint();
  }

  @override
  Widget buildBehavior(BuildContext context) {
    final entryWidgets = (legendState.legendEntries ?? []).map((entry) {
      final isHidden = isSeriesHidden(entry.series.id);

      return AnimatedBuilder(
        animation: chartState.animationPosition,
        builder: (context, child) {
          //final textStyle = entry.;

          final Color foreground =
              entry.textStyle?.color ?? ButtonTheme.of(context).color!;

          SymbolRendererBuilder? symbolBuilder;

          if (entry.symbolRenderer != null) {
            symbolBuilder = entry.symbolRenderer! is SymbolRendererBuilder
                ? entry.symbolRenderer! as SymbolRendererBuilder
                : SymbolRendererCanvas(
                    symbolRenderer: entry.symbolRenderer!,
                    dashPattern: entry.dashPattern,
                  );
          }

          final disabledInteraction =
              legendTapHandling == LegendTapHandling.hide &&
                  isSeriesAlwaysVisible(entry.series.id);

          return Button(
            onPressed: !disabledInteraction
                ? () {
                    if (legendTapHandling == LegendTapHandling.hide) {
                      final seriesId = entry.series.id;

                      if (!isSeriesHidden(seriesId)) {
                        hideSeries(seriesId);
                      } else {
                        showSeries(seriesId);
                      }

                      chartState.redraw(
                          skipLayout: true, skipAnimation: false);
                    }
                  }
                : null,
            body: Text(
              entry.label,
              style: entry.textStyle,
            ),
            leading: symbolBuilder?.build(
              context,
              size: const Size(12.0, 12.0),
              color: entry.color,
              enabled: !isHidden,
            ),
            theme: ButtonThemeData(
              textStyle: entry.textStyle,
              color: foreground,
            ),
          );
        },
      );
    }).toList();

    return Flex(
      direction: position == BehaviorPosition.top ||
              position == BehaviorPosition.bottom
          ? Axis.horizontal
          : Axis.vertical,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: entryWidgets,
    );
  }
}

@immutable
class _SymbolRenderer extends SingleChildRenderObjectWidget {
  _SymbolRenderer({
    required this.symbolRenderer,
  });

  final SymbolRenderer symbolRenderer;

  @override
  SymbolRendererRender createRenderObject(BuildContext context) {
    return SymbolRendererRender(
      symbolRenderer: symbolRenderer,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant SymbolRendererRender renderObject) {}
}

class SymbolRendererRender extends RenderBox {
  SymbolRendererRender({required this.symbolRenderer});

  final SymbolRenderer symbolRenderer;

  @override
  void performLayout() {
    size = constraints.biggest;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    symbolRenderer.draw(context.canvas, offset, Offset.zero & size);
  }
}
