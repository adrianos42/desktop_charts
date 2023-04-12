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

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import '../../../rate_limit_utils.dart' show throttle;
import '../../base_chart.dart' show BaseChartState, BaseChart;
import '../../datum_details.dart' show DatumDetails;
import '../../processed_series.dart' show ImmutableSeries;
import '../../selection_model.dart' show SelectionModelType;
import '../../series_datum.dart' show SeriesDatum;
import '../chart_behavior.dart' show ChartBehavior;
import 'selection_trigger.dart' show SelectionTrigger;

/// Chart behavior that listens to the given eventTrigger and updates the
/// specified [SelectionModel]. This is used to pair input events to behaviors
/// that listen to selection changes.
///
/// Input event types:
///   hover (default) - Mouse over/near data.
///   tap - Mouse/Touch on/near data.
///   pressHold - Mouse/Touch and drag across the data instead of panning.
///   longPressHold - Mouse/Touch for a while in one place then drag across the
///       data.
///
/// SelectionModels that can be updated:
///   info - To view the details of the selected items (ie: hover for web).
///   action - To select an item as an input, drill, or other selection.
///
/// Other options available
///   [selectionMode] - Optional mode for expanding the selection beyond the
///       nearest datum. Defaults to selecting just the nearest datum.
///
///   [selectAcrossAllSeriesRendererComponents] - Events in any component that
///       draw Series data will propagate to other components that draw Series
///       data to get a union of points that match across all series renderer
///       components. This is useful when components in the margins draw series
///       data and a selection is supposed to bridge the two adjacent
///       components. (Default: true)
///   [selectClosestSeries] - If true, the closest Series itself will be marked
///       as selected in addition to the datum. This is useful for features like
///       highlighting the closest Series. (Default: true)
///
/// You can add one SelectNearest for each model type that you are updating.
/// Any previous SelectNearest behavior for that selection model will be
/// removed.
class SelectNearest<D> extends ChartBehavior<D> {
  SelectNearest({
    this.selectionModelType = SelectionModelType.info,
    this.selectionMode = SelectionMode.expandToDomain,
    this.selectAcrossAllSeriesRendererComponents = true,
    this.selectClosestSeries = true,
    this.eventTrigger = SelectionTrigger.hover,
    this.maximumDomainDistance,
    this.hoverEventDelay,
  });

  /// Type of selection model that should be updated by input events.
  final SelectionModelType selectionModelType;

  /// Type of input event that should trigger selection.
  final SelectionTrigger eventTrigger;

  /// Optional mode for expanding the selection beyond the nearest datum.
  /// Defaults to selecting just the nearest datum.
  final SelectionMode selectionMode;

  /// Whether or not events in any component that draw Series data will
  /// propagate to other components that draw Series data to get a union of
  /// points that match across all series renderer components.
  ///
  /// This is useful when components in the margins draw series data and a
  /// selection is supposed to bridge the two adjacent components.
  final bool selectAcrossAllSeriesRendererComponents;

  /// Whether or not the closest Series itself will be marked as selected in
  /// addition to the datum.
  final bool selectClosestSeries;

  /// The farthest away a domain value can be from the mouse position on the
  /// domain axis before we'll ignore the datum.
  ///
  /// This allows sparse data to not get selected until the mouse is some
  /// reasonable distance. Defaults to no maximum distance.
  final int? maximumDomainDistance;

  /// Wait time in milliseconds for when the next event can be called.
  final int? hoverEventDelay;

  late BaseChartState<D, BaseChart<D>> _chartState;

  bool _onSelect(Offset globalPosition, [double? ignored]) {
    final details = _chartState.getNearestDatumDetailPerSeries(
      globalPosition,
      selectAcrossAllSeriesRendererComponents,
    );

    final seriesList = <ImmutableSeries<D>>[];
    var seriesDatumList = <SeriesDatum<D>>[];

    if (details.isNotEmpty) {
      details.sort((a, b) => a.domainDistance!.compareTo(b.domainDistance!));

      if (maximumDomainDistance == null ||
          details[0].domainDistance! <= maximumDomainDistance!) {
        seriesDatumList = _extractSeriesFromNearestSelection(details);

        // Filter out points from overlay series.
        seriesDatumList
            .removeWhere((SeriesDatum<D> datum) => datum.series.overlaySeries);

        if (selectClosestSeries && seriesList.isEmpty) {
          if (details.first.series!.overlaySeries) {
            // If the closest "details" was from an overlay series, grab the
            // closest remaining series instead. In this case, we need to sort a
            // copy of the list by domain distance because we do not want to
            // re-order the actual return values here.
            final sortedSeriesDatumList =
                List<SeriesDatum<D>>.from(seriesDatumList);
            sortedSeriesDatumList.sort((a, b) {
              final detailsA = a.datum as DatumDetails<D>;
              final detailsB = b.datum as DatumDetails<D>;
              return detailsA.domainDistance!
                  .compareTo(detailsB.domainDistance!);
            });
            seriesList.add(sortedSeriesDatumList.first.series);
          } else {
            seriesList.add(details.first.series!);
          }
        }
      }
    }

    return _chartState
        .getSelectionModel(selectionModelType)
        .updateSelection(seriesDatumList, seriesList);
  }

  List<SeriesDatum<D>> _extractSeriesFromNearestSelection(
      List<DatumDetails<D>> details) {
    return switch (selectionMode) {
      SelectionMode.expandToDomain => _expandToDomain(details.first),
      SelectionMode.selectOverlapping => details
          .map((datumDetails) =>
              SeriesDatum<D>(datumDetails.series!, datumDetails.datum))
          .toList(),
      SelectionMode.single => [
          SeriesDatum<D>(details.first.series!, details.first.datum)
        ]
    };
  }

  bool _onDeselectAll() {
    _chartState
        .getSelectionModel(selectionModelType)
        .updateSelection(<SeriesDatum<D>>[], <ImmutableSeries<D>>[]);
    return false;
  }

  List<SeriesDatum<D>> _expandToDomain(DatumDetails<D> nearestDetails) {
    // Make sure that the "nearest" datum is at the top of the list.
    final data = <SeriesDatum<D>>[
      SeriesDatum(nearestDetails.series!, nearestDetails.datum)
    ];
    final nearestDomain = nearestDetails.domain;

    for (final ImmutableSeries<D> series in _chartState.currentSeriesList) {
      final domainFn = series.domainFn;
      final domainLowerBoundFn = series.domainLowerBoundFn;
      final domainUpperBoundFn = series.domainUpperBoundFn;
      final testBounds =
          domainLowerBoundFn != null && domainUpperBoundFn != null;

      for (int i = 0; i < series.data.length; i += 1) {
        final Object? datum = series.data[i];
        final domain = domainFn(i);

        // Don't re-add the nearest details.
        if (nearestDetails.series == series && nearestDetails.datum == datum) {
          continue;
        }

        if (domain == nearestDomain) {
          data.add(SeriesDatum(series, datum));
        } else if (testBounds) {
          final domainLowerBound = domainLowerBoundFn(i);
          final domainUpperBound = domainUpperBoundFn(i);

          bool addDatum = false;

          if (domainLowerBound != null && domainUpperBound != null) {
            if (domain is int) {
              addDatum =
                  (domainLowerBound as int) <= (nearestDomain as int?)! &&
                      nearestDomain! <= (domainUpperBound as int);
            } else if (domain is double) {
              addDatum =
                  (domainLowerBound as double) <= (nearestDomain as double?)! &&
                      nearestDomain! <= (domainUpperBound as double);
            } else if (domain is DateTime) {
              addDatum = domainLowerBound == nearestDomain ||
                  domainUpperBound == nearestDomain ||
                  ((domainLowerBound as DateTime)
                          .isBefore((nearestDomain as DateTime?)!) &&
                      (nearestDomain!).isBefore(domainUpperBound as DateTime));
            }
          }

          if (addDatum) {
            data.add(SeriesDatum(series, datum));
          }
        }
      }
    }

    return data;
  }

  Map<Type, GestureRecognizerFactory> get _gestures {
    final Map<Type, GestureRecognizerFactory> gestures =
        <Type, GestureRecognizerFactory>{};

    if (eventTrigger == SelectionTrigger.tapAndDrag ||
        eventTrigger == SelectionTrigger.pressHold) {
      gestures[PanGestureRecognizer] =
          GestureRecognizerFactoryWithHandlers<PanGestureRecognizer>(
        () => PanGestureRecognizer(debugOwner: this),
        (DragGestureRecognizer instance) {
          instance.onStart = (details) => _onSelect(details.globalPosition);
          instance.onUpdate = (details) => _onSelect(details.globalPosition);
          instance.onCancel = () => _onDeselectAll();

          if (eventTrigger == SelectionTrigger.pressHold) {
            instance.onEnd = (_) => _onDeselectAll();
          }
        },
      );
    }

    if (eventTrigger == SelectionTrigger.tapAndDrag ||
        eventTrigger == SelectionTrigger.tap) {
      gestures[TapGestureRecognizer] =
          GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
        () => TapGestureRecognizer(debugOwner: this),
        (TapGestureRecognizer instance) {
          instance.onTapUp = (details) => _onSelect(details.globalPosition);
        },
      );
    }

    if (eventTrigger == SelectionTrigger.longPressHold ||
        eventTrigger == SelectionTrigger.pressHold) {
      gestures[LongPressGestureRecognizer] =
          GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
        () => LongPressGestureRecognizer(debugOwner: this),
        (LongPressGestureRecognizer instance) {
          instance.onLongPressStart =
              (details) => _onSelect(details.globalPosition);

          instance.onLongPressMoveUpdate =
              (details) => _onSelect(details.globalPosition);

          instance.onLongPressCancel = () => _onDeselectAll();
        },
      );
    }

    return gestures;
  }

  @override
  void attachTo<S extends BaseChart<D>>(BaseChartState<D, S> chartState) {
    _chartState = chartState;
  }

  @override
  void dispose() {}

  @override
  String get role => 'SelectNearest-$selectionModelType';

  @override
  Widget buildBehavior(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onHover: eventTrigger == SelectionTrigger.hover
          ? (event) => hoverEventDelay == null
              ? _onSelect(event.position)
              : throttle<Offset, bool>(
                  _onSelect,
                  delay: Duration(milliseconds: hoverEventDelay!),
                  defaultReturn: false,
                )(event.position)
          : null,
      child: RawGestureDetector(
        gestures: _gestures,
        behavior: HitTestBehavior.translucent,
        child: const Center(
          child: SizedBox(),
        ),
      ),
    );
  }
}

/// Mode for expanding the selection beyond just the nearest datum.
enum SelectionMode {
  /// All data sharing the same domain value as the nearest datum will be
  /// selected (in charts that have a concept of domain).
  expandToDomain,

  /// All data for overlapping points in a series will be selected.
  selectOverlapping,

  /// Select only the nearest datum selected by the chart. This is the default
  /// mode.
  single,
}
