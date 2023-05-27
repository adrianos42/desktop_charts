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

import 'dart:math';

import 'package:desktop/desktop.dart';
import 'package:desktop_charts/desktop_charts.dart' as charts;
import 'package:flutter/scheduler.dart';

import '../defaults.dart';

class SliderLinePage extends StatefulWidget {
  const SliderLinePage({super.key});

  @override
  State<SliderLinePage> createState() => _SliderLinePageState();
}

class _SliderLinePageState extends State<SliderLinePage> {
  bool _hasAnimation = true;

  void _updateRandomData() {
    _data = SliderLine.createRandomData();
  }

  void _refresh() {
    setState(() => _updateRandomData());
  }

  @override
  void initState() {
    super.initState();

    _updateRandomData();
  }

  late List<charts.Series<LinearSales, num>> _data;

  @override
  Widget build(BuildContext context) {
    return Defaults(
      header: 'Behaviors',
      items: [
        ItemTitle(
          title: SliderLine.title,
          subtitle: SliderLine.subtitle,
          body: (context) => SliderLine(
            _data,
            animate: _hasAnimation,
          ),
          options: [
            Button.icon(
              Icons.animation,
              onPressed: () => setState(() => _hasAnimation = !_hasAnimation),
              active: _hasAnimation,
            ),
            Button.icon(Icons.refresh, onPressed: _refresh),
          ],
        ),
      ],
    );
  }
}

class SliderLineBuilder extends ExampleBuilder {
  const SliderLineBuilder();

  @override
  Widget page([int? index, List<ExampleBuilder>? children]) =>
      const SliderLinePage();

  @override
  String? get subtitle => SliderLine.subtitle;

  @override
  String get title => SliderLine.title;

  @override
  Widget withSampleData([bool animate = true]) =>
      SliderLine.withSampleData(animate);
}

/// This is just a simple line chart with a behavior that adds slider controls.
///
/// A [Slider] behavior is added manually to enable slider controls, with an
/// initial position at 1 along the domain axis.
///
/// An onChange event handler has been configured to demonstrate updating a div
/// with data from the slider's current position. An "initial" drag state event
/// will be fired when the chart is drawn because an initial domain value is
/// set.
///
/// [Slider.moveSliderToDomain] can be called to programmatically position the
/// slider. This is useful for synchronizing the slider with external elements.
class SliderLine extends StatefulWidget {
  const SliderLine(
    this.seriesList, {
    this.animate = true,
    super.key,
  });

  /// Creates a [LineChart] with sample data and no transition.
  factory SliderLine.withSampleData([bool animate = true]) {
    return SliderLine(
      createSampleData(),
      animate: animate,
    );
  }

  static String get title => 'Line Chart with Slider';
  static String? get subtitle => 'Line chart with a slider behavior';

  final List<charts.Series<dynamic, num>> seriesList;
  final bool animate;

  /// Create random data.
  static List<charts.Series<LinearSales, num>> createRandomData() {
    final random = Random();

    final data = [
      LinearSales(0, random.nextInt(100)),
      LinearSales(1, random.nextInt(100)),
      LinearSales(2, random.nextInt(100)),
      LinearSales(3, random.nextInt(100)),
    ];

    return [
      charts.Series<LinearSales, int>(
        id: 'Sales',
        domain: (LinearSales sales, _) => sales.year,
        measure: (LinearSales sales, _) => sales.sales,
        data: data,
      )
    ];
  }

  /// Create one series with sample hard coded data.
  static List<charts.Series<LinearSales, int>> createSampleData() {
    const data = [
      LinearSales(0, 5),
      LinearSales(1, 25),
      LinearSales(2, 100),
      LinearSales(3, 75),
    ];

    return [
      charts.Series<LinearSales, int>(
        id: 'Sales',
        domain: (LinearSales sales, _) => sales.year,
        measure: (LinearSales sales, _) => sales.sales,
        data: data,
      )
    ];
  }

  // We need a Stateful widget to build the selection details with the current
  // selection as the state.
  @override
  State<StatefulWidget> createState() => _SliderCallbackState();
}

class _SliderCallbackState extends State<SliderLine> {
  num? _sliderDomainValue;
  String? _sliderDragState;
  Offset? _sliderPosition;

  // Handles callbacks when the user drags the slider.
  void _onSliderChange(
    Offset point,
    dynamic domain,
    String roleId,
    charts.SliderListenerDragState dragState,
  ) {
    // Request a build.
    void rebuild(_) {
      setState(() {
        _sliderDomainValue = (domain * 10).round() / 10;
        _sliderDragState = dragState.toString();
        _sliderPosition = point;
      });
    }

    SchedulerBinding.instance.addPostFrameCallback(rebuild);
  }

  @override
  Widget build(BuildContext context) {
    // The children consist of a Chart and Text widgets below to hold the info.
    final children = <Widget>[
      Expanded(
        child: charts.LineChart(
          widget.seriesList,
          animate: widget.animate,
          // Configures a [Slider] behavior.
          //
          // Available options include:
          //
          // [eventTrigger] configures the type of mouse gesture that controls
          // the slider.
          //
          // [handleRenderer] draws a handle for the slider. Defaults to a
          // rectangle.
          //
          // [initialDomainValue] sets the initial position of the slider in
          // domain units. The default is the center of the chart.
          //
          // [onChangeCallback] will be called when the position of the slider
          // changes during a drag event.
          //
          // [roleId] optional custom role ID for the slider. This can be used to
          // allow multiple [Slider] behaviors on the same chart. Normally, there can
          // only be one slider (per event trigger type) on a chart. This setting
          // allows for configuring multiple independent sliders.
          //
          // [snapToDatum] configures the slider to snap snap onto the nearest
          // datum (by domain distance) when dragged. By default, the slider
          // can be positioned anywhere along the domain axis.
          //
          // [style] takes in a [SliderStyle] configuration object, and
          // configures the color and sizing of the slider line and handle.
          behaviors: [
            charts.SliderBehavior(
              initialDomainValue: 1.0,
              onChangeCallback: _onSliderChange,
            ),
          ],
        ),
      ),
    ];

    // If there is a slider change event, then include the details.
    if (_sliderDomainValue != null) {
      children.add(
        Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            'Slider domain value: $_sliderDomainValue',
          ),
        ),
      );
    }
    if (_sliderPosition != null) {
      children.add(
        Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            'Slider position: ${_sliderPosition!.dx}, ${_sliderPosition!.dy}',
          ),
        ),
      );
    }
    if (_sliderDragState != null) {
      children.add(
        Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            'Slider drag state: $_sliderDragState',
          ),
        ),
      );
    }

    return Column(children: children);
  }
}

/// Sample linear data type.
@immutable
class LinearSales {
  const LinearSales(this.year, this.sales);

  final int year;
  final int sales;
}
