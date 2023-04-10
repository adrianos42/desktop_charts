// Copyright (C) 2023 Adriano Souza (adriano.souza113@gmail.com)

import 'package:desktop/desktop.dart';
import 'palette.dart';

@immutable
class LineStyle {
  const LineStyle({
    this.color,
    this.dashPattern,
    this.strokeWidth,
  });

  final Color? color;
  final List<int>? dashPattern;
  final double? strokeWidth;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is LineStyle &&
            color == other.color &&
            dashPattern == other.dashPattern &&
            strokeWidth == other.strokeWidth);
  }

  @override
  int get hashCode => Object.hash(color, dashPattern, strokeWidth);
}

/// The data for the [ChartsTheme] for desktop apps.
@immutable
class ChartsThemeData {
  /// Creates a [ChartsThemeData].
  const ChartsThemeData({
    required this.arcLabelOutsideLeaderLine,
    required this.arcStrokeColor,
    required this.foreground,
    required this.chartBackgroundColor,
    required this.defaultSeriesColor,
    required this.legendEntryTextColor,
    required this.legendTitleTextColor,
    required this.linePointHighlighterColor,
    required this.noDataColor,
    required this.rangeAnnotationColor,
    required this.rangeBandSize,
    required this.sliderFillColor,
    required this.sliderStrokeColor,
    required this.tickColor,
    required this.tickLength,
    required this.transparent,
    required this.background,
    required this.labelStyle,
  });

  ChartsThemeData copyWith({
    Color? background,
    Color? transparent,
    Color? foreground,
    int? tickLength,
    Color? tickColor,
    Color? arcLabelOutsideLeaderLine,
    Color? defaultSeriesColor,
    Color? arcStrokeColor,
    Color? legendEntryTextColor,
    Color? legendTitleTextColor,
    Color? linePointHighlighterColor,
    Color? noDataColor,
    Color? rangeAnnotationColor,
    Color? sliderFillColor,
    Color? sliderStrokeColor,
    Color? chartBackgroundColor,
    double? rangeBandSize,
    TextStyle? labelStyle,
  }) {
    return ChartsThemeData(
      background: background ?? this.background,
      transparent: transparent ?? this.transparent,
      foreground: foreground ?? this.foreground,
      tickLength: tickLength ?? this.tickLength,
      tickColor: tickColor ?? this.tickColor,
      arcLabelOutsideLeaderLine:
          arcLabelOutsideLeaderLine ?? this.arcLabelOutsideLeaderLine,
      defaultSeriesColor: defaultSeriesColor ?? this.defaultSeriesColor,
      arcStrokeColor: arcStrokeColor ?? this.arcStrokeColor,
      legendEntryTextColor: legendEntryTextColor ?? this.legendEntryTextColor,
      legendTitleTextColor: legendTitleTextColor ?? this.legendTitleTextColor,
      linePointHighlighterColor:
          linePointHighlighterColor ?? this.linePointHighlighterColor,
      noDataColor: noDataColor ?? this.noDataColor,
      rangeAnnotationColor: rangeAnnotationColor ?? this.rangeAnnotationColor,
      sliderFillColor: sliderFillColor ?? this.sliderFillColor,
      sliderStrokeColor: sliderStrokeColor ?? this.sliderStrokeColor,
      chartBackgroundColor: chartBackgroundColor ?? this.chartBackgroundColor,
      rangeBandSize: rangeBandSize ?? this.rangeBandSize,
      labelStyle: labelStyle ?? this.labelStyle,
    );
  }

  const ChartsThemeData.fallbackw({
    this.arcLabelOutsideLeaderLine = const Color(0xff606060),
    this.arcStrokeColor = const Color(0xff000000),
    this.legendEntryTextColor = const Color(0xfff0f0f0),
    this.legendTitleTextColor = const Color(0xfff0f0f0),
    this.foreground = const Color(0xfff0f0f0),
    this.background = const Color(0xff000000),
    this.chartBackgroundColor = const Color(0xff000000),
    this.defaultSeriesColor = const Color(0xff101010),
    this.linePointHighlighterColor = const Color(0xfff0f0f0),
    this.noDataColor = const Color(0xff404040),
    this.rangeAnnotationColor = const Color(0xff606060),
    this.rangeBandSize = 0.65,
    this.sliderFillColor = const Color(0xff000000),
    this.sliderStrokeColor = const Color(0xff202020),
    this.tickColor = const Color(0xffffffff),
    this.tickLength = 3,
    this.transparent = const Color.fromARGB(0, 0, 0, 0),
    this.labelStyle = const TextStyle(),
  });

  final Color foreground;

  final Color transparent;

  final Color background;

  /// Default tick length.
  final int tickLength;

  /// Default tick color.
  final Color tickColor;

  /// Default color for outside label leader lines for [ArcLabelDecorator].
  final Color arcLabelOutsideLeaderLine;

  /// Default series color for legends, used as a fallback when a series has no
  /// data.
  final Color defaultSeriesColor;

  /// Default color for strokes for [ArcRendererConfig].
  final Color arcStrokeColor;

  /// Default color for entry text for [Legend].
  final Color legendEntryTextColor;

  /// Default color for title text for [Legend].
  final Color legendTitleTextColor;

  /// Default color for [LinePointHighlighter].
  final Color linePointHighlighterColor;

  /// Default color for "no data" states on charts.
  final Color noDataColor;

  /// Default color for [RangeAnnotation].
  final Color rangeAnnotationColor;

  /// Default fill color for [Slider].
  final Color sliderFillColor;

  /// Default stroke color for [Slider].
  final Color sliderStrokeColor;

  /// Default background color for the chart.
  final Color chartBackgroundColor;

  /// The width of the band specified as fraction of step.
  final double rangeBandSize;

  final TextStyle labelStyle;

  /// Gets list with [count] of palettes.
  List<Palette> getOrderedPalettes(int count) {
    return DesktopPalette.getOrderedPalettes(count);
  }

  /// Creates [LineStyle] for axis line from style.
  ///
  /// Fill missing value(s) with default.
  LineStyle createAxisLineStyle(LineStyle? style) {
    return LineStyle(
      color: style?.color ?? sliderFillColor,
      dashPattern: style?.dashPattern,
      strokeWidth: style?.strokeWidth ?? 1.0,
    );
  }

  /// Creates [LineStyle] for tick lines from style.
  ///
  /// Fill missing value(s) with default.
  LineStyle createTickLineStyle(LineStyle? style) {
    return LineStyle(
      color: style?.color ?? labelStyle.color,
      dashPattern: style?.dashPattern,
      strokeWidth: style?.strokeWidth ?? 1.0,
    );
  }

  /// Creates [LineStyle] for axis grid lines from style.
  ///
  /// Fill missing value(s) with default.
  LineStyle createGridlineStyle(LineStyle? style) {
    return LineStyle(
      color: style?.color ?? rangeAnnotationColor,
      dashPattern: style?.dashPattern,
      strokeWidth: style?.strokeWidth ?? 1.0,
    );
  }

  @override
  int get hashCode {
    return Object.hash(
      foreground,
      transparent,
      background,
      tickLength,
      tickColor,
      arcLabelOutsideLeaderLine,
      defaultSeriesColor,
      arcStrokeColor,
      legendEntryTextColor,
      legendTitleTextColor,
      linePointHighlighterColor,
      noDataColor,
      rangeAnnotationColor,
      sliderFillColor,
      sliderStrokeColor,
      chartBackgroundColor,
      rangeBandSize,
      labelStyle,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is ChartsThemeData &&
        other.foreground == foreground &&
        other.transparent == transparent &&
        other.background == background &&
        other.tickLength == tickLength &&
        other.tickColor == tickColor &&
        other.arcLabelOutsideLeaderLine == arcLabelOutsideLeaderLine &&
        other.defaultSeriesColor == defaultSeriesColor &&
        other.arcStrokeColor == arcStrokeColor &&
        other.legendEntryTextColor == legendEntryTextColor &&
        other.legendTitleTextColor == legendTitleTextColor &&
        other.linePointHighlighterColor == linePointHighlighterColor &&
        other.noDataColor == noDataColor &&
        other.rangeAnnotationColor == rangeAnnotationColor &&
        other.sliderFillColor == sliderFillColor &&
        other.sliderStrokeColor == sliderStrokeColor &&
        other.chartBackgroundColor == chartBackgroundColor &&
        other.rangeBandSize == rangeBandSize &&
        other.labelStyle == labelStyle;
  }
}

@immutable
class ChartsTheme extends InheritedTheme {
  const ChartsTheme({
    super.key,
    this.data,
    required super.child,
  });

  final ChartsThemeData? data;

  static ChartsThemeData of(BuildContext context) {
    final ChartsTheme? chartsTheme =
        context.dependOnInheritedWidgetOfExactType<ChartsTheme>();
    final ChartsThemeData? chartsThemeData = chartsTheme?.data;

    if (chartsThemeData == null) {
      final themeData = Theme.of(context);
      final colorScheme = themeData.colorScheme;
      final textTheme = themeData.textTheme;

      final Color arcLabelOutsideLeaderLine = colorScheme.shade[60];
      final Color arcStrokeColor = colorScheme.background[0];
      final Color legendEntryTextColor = textTheme.textHigh;
      final Color legendTitleTextColor = textTheme.textHigh;
      final Color background = colorScheme.background[0];
      final Color foreground = textTheme.textHigh;
      final Color chartBackgroundColor = colorScheme.background[0];
      final Color defaultSeriesColor = colorScheme.background[12];
      final Color linePointHighlighterColor = colorScheme.shade[100];
      final Color noDataColor = colorScheme.disabled;
      final Color rangeAnnotationColor = colorScheme.shade[30];
      const double rangeBandSize = 0.65;
      final Color sliderFillColor = colorScheme.background[0];
      final Color sliderStrokeColor = colorScheme.background[20];
      final Color tickColor = colorScheme.background[20];
      const int tickLength = 3;
      const Color transparent = Color.fromARGB(0, 0, 0, 0);
      final TextStyle labelStyle = textTheme.caption.copyWith(
        color: textTheme.textMedium,
      );

      return ChartsThemeData(
        arcLabelOutsideLeaderLine: arcLabelOutsideLeaderLine,
        arcStrokeColor: arcStrokeColor,
        legendEntryTextColor: legendEntryTextColor,
        legendTitleTextColor: legendTitleTextColor,
        foreground: foreground,
        background: background,
        chartBackgroundColor: chartBackgroundColor,
        defaultSeriesColor: defaultSeriesColor,
        linePointHighlighterColor: linePointHighlighterColor,
        noDataColor: noDataColor,
        rangeAnnotationColor: rangeAnnotationColor,
        rangeBandSize: rangeBandSize,
        sliderFillColor: sliderFillColor,
        sliderStrokeColor: sliderStrokeColor,
        tickColor: tickColor,
        tickLength: tickLength,
        transparent: transparent,
        labelStyle: labelStyle,
      );
    }

    return chartsThemeData;
  }

  @override
  Widget wrap(BuildContext context, Widget child) {
    final ChartsTheme? ancestorTheme =
        context.findAncestorWidgetOfExactType<ChartsTheme>();
    return identical(this, ancestorTheme)
        ? child
        : ChartsTheme(data: data, child: child);
  }

  @override
  bool updateShouldNotify(ChartsTheme oldWidget) => data != oldWidget.data;
}

class PaletteColor extends Palette {
  const PaletteColor(this._color);

  final Color _color;

  @override
  Color get shadeDefault => _color;
}

class DesktopPalette {
  static Palette get blue => const MaterialBlue();
  static Palette get red => const MaterialRed();
  static Palette get yellow => const MaterialYellow();
  static Palette get green => const MaterialGreen();
  static Palette get purple => const MaterialPurple();
  static Palette get cyan => const MaterialCyan();
  static Palette get deepOrange => const MaterialDeepOrange();
  static Palette get lime => const MaterialLime();
  static Palette get indigo => const MaterialIndigo();
  static Palette get pink => const MaterialPink();
  static Palette get teal => const MaterialTeal();
  static Color get gray => const Color(0xff808080);
  static Color get transparent => const Color(0x00000000);
  static Color get foreground => const Color(0xffffffff);
  static Color get background => const Color(0xff000000);

  // Lazily-instantiated iterable, to avoid allocating colors that are not used.
  static final Iterable<Palette> _orderedPalettes = [
    blue,
    red,
    yellow,
    green,
    purple,
    cyan,
    deepOrange,
    lime,
    indigo,
    pink,
    teal
  ];

  static List<Palette> getOrderedPalettes(int count) {
    return _orderedPalettes.take(count).toList();
  }
}

class MaterialBlue extends Palette {
  static const _shade500 = Color(0xff2196F3);

  const MaterialBlue();

  @override
  Color get shadeDefault => _shade500;
}

class MaterialRed extends Palette {
  static const _shade500 = Color(0xffF44336);

  const MaterialRed();

  @override
  Color get shadeDefault => _shade500;
}

class MaterialYellow extends Palette {
  static const _shade500 = Color(0xffFFEB3B);

  const MaterialYellow();

  @override
  Color get shadeDefault => _shade500;
}

class MaterialGreen extends Palette {
  static const _shade500 = Color(0xff4CAF50);

  const MaterialGreen();

  @override
  Color get shadeDefault => _shade500;
}

class MaterialPurple extends Palette {
  static const _shade500 = Color(0xff9C27B0);

  const MaterialPurple();

  @override
  Color get shadeDefault => _shade500;
}

class MaterialCyan extends Palette {
  static const _shade500 = Color(0xff00BCD4);

  const MaterialCyan();

  @override
  Color get shadeDefault => _shade500;
}

class MaterialDeepOrange extends Palette {
  static const _shade500 = Color(0xffFF5722);

  const MaterialDeepOrange();

  @override
  Color get shadeDefault => _shade500;
}

class MaterialLime extends Palette {
  static const _shade500 = Color(0xffCDDC39);

  const MaterialLime();

  @override
  Color get shadeDefault => _shade500;
}

class MaterialIndigo extends Palette {
  static const _shade500 = Color(0xff3F51B5);

  const MaterialIndigo();

  @override
  Color get shadeDefault => _shade500;
}

class MaterialPink extends Palette {
  static const _shade500 = Color(0xffE91E63);

  const MaterialPink();

  @override
  Color get shadeDefault => _shade500;
}

class MaterialTeal extends Palette {
  static const _shade500 = Color(0xff009688);

  const MaterialTeal();

  @override
  Color get shadeDefault => _shade500;
}
