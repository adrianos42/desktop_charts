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
import 'package:flutter/widgets.dart';
import '../../../symbol_renderer.dart';

import '../../base_chart.dart';
import '../../datum_details.dart' show MeasureFormatter;
import '../../selection_model.dart' show SelectionModelType;
import '../chart_behavior.dart' show ChartBehaviorState, BehaviorPosition;
import 'legend.dart';
import 'legend_entry_generator.dart';
import 'per_datum_legend_entry_generator.dart';

/// Datum legend behavior for charts.
///
/// By default this behavior creates one legend entry per datum in the first
/// series rendered on the chart.
///
/// TODO: Allows for hovering over a datum in legend to highlight
/// corresponding datum in draw area.
///
/// TODO: Implement tap to hide individual data in the series.
class DatumLegend<D> extends Legend<D> {
  const DatumLegend({
    SelectionModelType? selectionModelType,
    LegendEntryGeneratorBuilder<D>? legendEntryGenerator,
    this.measureFormatter,
    this.secondaryMeasureFormatter,
    this.showMeasures,
    this.legendDefaultMeasure,
    super.position,
    super.insideJustification,
    super.outsideJustification,
    TextStyle? entryTextStyle,
  }) : super(
          selectionModelType: selectionModelType ?? SelectionModelType.info,
          legendEntryGeneratorBuilder:
              legendEntryGenerator ?? _perDatumLegendEntryGeneratorBuilder,
          entryTextStyle: entryTextStyle,
        );

  final MeasureFormatter? measureFormatter;
  final MeasureFormatter? secondaryMeasureFormatter;
  final bool? showMeasures;
  final LegendDefaultMeasure? legendDefaultMeasure;

  static LegendEntryGenerator<D> _perDatumLegendEntryGeneratorBuilder<D>() {
    return PerDatumLegendEntryGenerator<D>();
  }

  @override
  ChartBehaviorState<D, S, DatumLegend<D>> build<S extends BaseChart<D>>({
    required BaseChartState<D, S> chartState,
  }) {
    return _DatumLegendState(behavior: this, chartState: chartState);
  }
}

// class DatumLegendState<D> extends ChartBehaviorState {}

class _DatumLegendState<D, S extends BaseChart<D>>
    extends LegendState<D, S, DatumLegend<D>> {
  _DatumLegendState({
    required super.behavior,
    required super.chartState,
  }) {
    // Calling the setters will automatically use non-null default values.
    showMeasures = behavior.showMeasures;
    legendDefaultMeasure = behavior.legendDefaultMeasure;
    measureFormatter = behavior.measureFormatter;
    secondaryMeasureFormatter = behavior.secondaryMeasureFormatter;
  }

  /// Whether or not the series legend should show measures on datum selection.
  late bool _showMeasures;

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
      throw ''; // legendEntryGenerator.legendDefaultMeasure;

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

  @override
  Widget buildBehaviorWidget(BuildContext context) {
    final entryWidgets = (legendEntries ?? []).map((entry) {
      //final isHidden = isSeriesHidden(entry.series.id);

      return AnimatedBuilder(
        animation: chartState.animationPosition,
        builder: (context, child) {
          //final textStyle = entry.;

          final Color? foreground = entry.textStyle?.color;

          SymbolRendererBuilder? symbolBuilder;

          if (entry.symbolRenderer != null) {
            symbolBuilder = entry.symbolRenderer! is SymbolRendererBuilder
                ? entry.symbolRenderer! as SymbolRendererBuilder
                : SymbolRendererCanvas(
                    symbolRenderer: entry.symbolRenderer!,
                    dashPattern: entry.dashPattern,
                  );
          }

          return DefaultTextStyle(
            style: (entry.textStyle ?? Theme.of(context).textTheme.body1)
                .copyWith(color: foreground),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (symbolBuilder != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: symbolBuilder.build(
                        context,
                        size: const Size(12.0, 12.0),
                        color: entry.color,
                      ),
                    ),
                  Text(entry.label),
                  if (showMeasures)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(entry.formattedValue!),
                    ),
                ],
              ),
            ),
          );
        },
      );
    }).toList();

    return Flex(
      direction: behavior.position == BehaviorPosition.top ||
              behavior.position == BehaviorPosition.bottom
          ? Axis.horizontal
          : Axis.vertical,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: entryWidgets,
    );
  }
}
