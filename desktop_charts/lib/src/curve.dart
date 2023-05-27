import 'dart:math' show pow, sqrt, min, max;

import 'package:flutter/rendering.dart';

const _defaultEpsilon = 2e-10;

/// Abstract class for spline interpolations.
abstract class LineCurve {
  void draw(Path path, List<Offset> points);

  (double?, double?) overflow(List<Offset> points);

  static const LineCurve linearCurve = LinearLineCurve();
  static const LineCurve basisCurve = BasisLineCurve();
  static const LineCurve cardinalCurve = CardinalLineCurve();
  static const LineCurve naturalCurve = NaturalLineCurve();
  static const LineCurve stepCurve = StepLineCurve.middle();
  static const LineCurve catmullRomCurve = CatmullRomLineCurve();
}

class LinearLineCurve implements LineCurve {
  const LinearLineCurve();

  @override
  (double?, double?) overflow(List<Offset> points) => (null, null);

  @override
  void draw(Path path, List<Offset> points) {
    for (final point in points) {
      path.lineTo(point.dx, point.dy);
    }
  }
}

class BasisLineCurve implements LineCurve {
  const BasisLineCurve();

  static void _point(
    double x,
    double y,
    double x0,
    double x1,
    double y0,
    double y1,
    Path path,
  ) {
    path.cubicTo(
      (2.0 * x0 + x1) / 3.0,
      (2.0 * y0 + y1) / 3.0,
      (x0 + 2.0 * x1) / 3.0,
      (y0 + 2.0 * y1) / 3.0,
      (x0 + 4.0 * x1 + x) / 6.0,
      (y0 + 4.0 * y1 + y) / 6.0,
    );
  }

  @override
  (double?, double?) overflow(List<Offset> points) => (null, null);

  @override
  void draw(Path path, List<Offset> points) {
    int p = 0;
    double x0 = 0.0;
    double x1 = 0.0;
    double y0 = 0.0;
    double y1 = 0.0;

    for (int i = 0; i < points.length; i += 1) {
      final dx = points[i].dx;
      final dy = points[i].dy;

      if (p == 0 || p == 1) {
        p += 1;
      } else {
        if (p == 2) {
          p += 1;
          path.lineTo((5.0 * x0 + x1) / 6.0, (5.0 * y0 + y1) / 6.0);
        }

        _point(dx, dy, x0, x1, y0, y1, path);
      }

      x0 = x1;
      x1 = dx;
      y0 = y1;
      y1 = dy;
    }

    if (p == 3) {
      _point(x1, y1, x0, x1, y0, y1, path);
      path.lineTo(x1, y1);
    } else if (p == 2) {
      path.lineTo(x1, y1);
    }
  }
}

class CardinalLineCurve implements LineCurve {
  const CardinalLineCurve([this._tension = 0.0]);

  final double _tension;

  CardinalLineCurve withTension(double tension) {
    return CardinalLineCurve(tension);
  }

  static void _point(
    double x,
    double y,
    double x0,
    double x1,
    double x2,
    double y0,
    double y1,
    double y2,
    double k,
    Path path,
  ) {
    path.cubicTo(
      x1 + k * (x2 - x0),
      y1 + k * (y2 - y0),
      x2 + k * (x1 - x),
      y2 + k * (y1 - y),
      x2,
      y2,
    );
  }

  @override
  (double?, double?) overflow(List<Offset> points) => (null, null);

  @override
  void draw(Path path, List<Offset> points) {
    final double k = (1.0 - _tension) / 6.0;

    int p = 0;
    double x0 = 0.0;
    double x1 = 0.0;
    double x2 = 0.0;
    double y0 = 0.0;
    double y1 = 0.0;
    double y2 = 0.0;

    for (int i = 0; i < points.length; i += 1) {
      final dx = points[i].dx;
      final dy = points[i].dy;

      if (p == 0) {
        p += 1;
      } else if (p == 1) {
        x1 = dx;
        y1 = dy;
        p += 1;
      } else {
        if (p == 2) {
          p += 1;
        }
        _point(dx, dy, x0, x1, x2, y0, y1, y2, k, path);
      }

      x0 = x1;
      x1 = x2;
      x2 = dx;
      y0 = y1;
      y1 = y2;
      y2 = dy;
    }

    if (p == 3) {
      _point(x1, y1, x0, x1, x2, y0, y1, y2, k, path);
    } else if (p == 2) {
      path.lineTo(x2, y2);
    }
  }
}

class NaturalLineCurve implements LineCurve {
  const NaturalLineCurve();

  (List<double>, List<double>) _controlPoints(List<double> x) {
    int i;
    double m;
    final int n = x.length - 1;
    final a = List.filled(n, 0.0);
    final b = List.filled(n, 0.0);
    final r = List.filled(n, 0.0);

    a[0] = 0.0;
    b[0] = 2.0;
    r[0] = x[0] + 2.0 * x[1];

    for (i = 1; i < n - 1; i += 1) {
      a[i] = 1.0;
      b[i] = 4.0;
      r[i] = 4.0 * x[i] + 2.0 * x[i + 1];
    }

    a[n - 1] = 2.0;
    b[n - 1] = 7.0;
    r[n - 1] = 8.0 * x[n - 1] + x[n];

    for (i = 1; i < n; i += 1) {
      m = a[i] / b[i - 1];
      b[i] -= m;
      r[i] -= m * r[i - 1];
    }

    a[n - 1] = r[n - 1] / b[n - 1];

    for (i = n - 2; i >= 0; i -= 1) {
      a[i] = (r[i] - a[i + 1]) / b[i];
    }

    b[n - 1] = (x[n] + a[n - 1]) / 2.0;

    for (i = 0; i < n - 1; i += 1) {
      b[i] = 2.0 * x[i + 1] - a[i + 1];
    }

    return (a, b);
  }

  @override
  (double?, double?) overflow(List<Offset> points) => (null, null);

  @override
  void draw(Path path, List<Offset> points) {
    final x = <double>[];
    final y = <double>[];

    for (final p in points) {
      x.add(p.dx);
      y.add(p.dy);
    }

    final int n = points.length;

    if (n == 2) {
      path.lineTo(x[1], y[1]);
    } else if (n > 2) {
      final (px0, px1) = _controlPoints(x);
      final (py0, py1) = _controlPoints(y);

      for (int i0 = 0, i1 = 1; i1 < n; i0 += 1, i1 += 1) {
        path.cubicTo(
          px0[i0],
          py0[i0],
          px1[i0],
          py1[i0],
          x[i1],
          y[i1],
        );
      }
    }
  }
}

class StepLineCurve implements LineCurve {
  const StepLineCurve(this._t);

  const StepLineCurve.before() : _t = 0.0;
  const StepLineCurve.middle() : _t = 0.5;
  const StepLineCurve.after() : _t = 1.0;

  final double _t;

  @override
  (double?, double?) overflow(List<Offset> points) => (null, null);

  @override
  void draw(Path path, List<Offset> points) {
    int p = 0;

    double x = 0.0;
    double y = 0.0;

    for (int i = 0; i < points.length; i += 1) {
      final dx = points[i].dx;
      final dy = points[i].dy;

      if (p == 0) {
        p += 1;
      } else {
        if (p == 1) {
          p += 1;
        }

        if (_t <= 0.0) {
          path.lineTo(x, dy);
          path.lineTo(dx, dy);
        } else {
          final x1 = x * (1 - _t) + dx * _t;
          path.lineTo(x1, y);
          path.lineTo(x1, dy);
        }
      }

      x = dx;
      y = dy;
    }

    if (_t > 0.0 && _t < 1.0 && p == 2) {
      path.lineTo(x, y);
    }
  }
}

class _CatmullRomCurveContext {
  _CatmullRomCurveContext();

  double x0 = 0.0;
  double y0 = 0.0;
  double x1 = 0.0;
  double y1 = 0.0;
  double x2 = 0.0;
  double y2 = 0.0;
  double l01a = 0.0;
  double l012a = 0.0;
  double l12a = 0.0;
  double l122a = 0.0;
  double l23a = 0.0;
  double l232a = 0.0;
}

class CatmullRomLineCurve implements LineCurve {
  const CatmullRomLineCurve([this._alpha = 0.5]);

  final double _alpha;

  static void _point(
    double x,
    double y,
    _CatmullRomCurveContext context,
    Path path,
  ) {
    double x1 = context.x1;
    double x2 = context.x2;
    double y1 = context.y1;
    double y2 = context.y2;

    if (context.l01a > _defaultEpsilon) {
      final a = 2.0 * context.l012a +
              3 * context.l01a * context.l12a +
              context.l122a,
          n = 3.0 * context.l01a * (context.l01a + context.l12a);
      x1 = (x1 * a - context.x0 * context.l122a + context.x2 * context.l012a) /
          n;
      y1 = (y1 * a - context.y0 * context.l122a + context.y2 * context.l012a) /
          n;
    }

    if (context.l23a > _defaultEpsilon) {
      final b = 2.0 * context.l232a +
              3.0 * context.l23a * context.l12a +
              context.l122a,
          m = 3.0 * context.l23a * (context.l23a + context.l12a);
      x2 = (x2 * b + context.x1 * context.l232a - x * context.l122a) / m;
      y2 = (y2 * b + context.y1 * context.l232a - y * context.l122a) / m;
    }

    path.cubicTo(x1, y1, x2, y2, context.x2, context.y2);
  }

  @override
  (double?, double?) overflow(List<Offset> points) {
    double maxMeasure = 0.0;
    double minMeasure = double.infinity;

    for (final point in points) {
      maxMeasure = max(maxMeasure, point.dy);
      minMeasure = min(minMeasure, point.dy);
    }

    return (
      maxMeasure,
      minMeasure,
    );
  }

  @override
  void draw(Path path, List<Offset> points) {
    int p = 0;

    final context = _CatmullRomCurveContext();

    for (int i = 0; i < points.length; i += 1) {
      final dx = points[i].dx;
      final dy = points[i].dy;

      if (p > 0) {
        final double x23 = context.x2 - dx;
        final double y23 = context.y2 - dy;
        context.l232a = pow(x23 * x23 + y23 * y23, _alpha) as double;
        context.l23a = sqrt(context.l232a);
      }

      if (p == 0 || p == 1) {
        p += 1;
      } else {
        if (p == 2) {
          p += 1;
        }

        _point(dx, dy, context, path);
      }

      context.l01a = context.l12a;
      context.l12a = context.l23a;
      context.l012a = context.l122a;
      context.l122a = context.l232a;
      context.x0 = context.x1;
      context.x1 = context.x2;
      context.x2 = dx;
      context.y0 = context.y1;
      context.y1 = context.y2;
      context.y2 = dy;
    }

    if (p == 2) {
      path.lineTo(context.x2, context.y2);
    } else if (p == 3) {
      context.l232a = pow(0.0, _alpha) as double;
      context.l23a = sqrt(context.l232a);

      _point(context.x2, context.y2, context, path);
    }
  }
}
