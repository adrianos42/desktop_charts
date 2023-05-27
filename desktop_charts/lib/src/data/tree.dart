// Copyright (C) 2023 Adriano Souza (adriano.souza113@gmail.com)

// Copyright 2019 the Charts project authors. Please see the AUTHORS file
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

import 'dart:collection';
import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show TextStyle;

import '../chart/chart_canvas.dart';
import '../typed_registry.dart';
import 'series.dart' show AttributeKey, Series, TypedAccessor;

/// A tree structure that contains metadata of a rendering tree.
class Tree<T, D> {
  factory Tree({
    required String id,
    required TreeNode<T> root,
    required TypedAccessor<T, D> domain,
    required TypedAccessor<T, num?> measure,
    TypedAccessor<T, Color>? color,
    TypedAccessor<T, Color>? fillColor,
    TypedAccessor<T, Color>? patternColor,
    TypedAccessor<T, FillPatternType>? fillPattern,
    TypedAccessor<T, double>? strokeWidth,
    TypedAccessor<T, String>? label,
    TypedAccessor<T, TextStyle>? labelStyle,
  }) {
    return Tree._(
      id: id,
      root: root,
      domain: _castFrom<T, D>(domain)!,
      measure: _castFrom<T, num?>(measure)!,
      color: _castFrom<T, Color>(color),
      fillColor: _castFrom<T, Color>(fillColor),
      fillPattern: _castFrom<T, FillPatternType>(fillPattern),
      patternColor: _castFrom<T, Color>(patternColor),
      strokeWidth: _castFrom<T, double>(strokeWidth),
      label: _castFrom<T, String>(label),
      labelStyle: _castFrom<T, TextStyle>(labelStyle),
    );
  }

  Tree._({
    required this.id,
    required this.root,
    required this.domain,
    required this.measure,
    required this.color,
    required this.fillColor,
    required this.fillPattern,
    required this.patternColor,
    required this.strokeWidth,
    required this.label,
    required this.labelStyle,
  });

  /// Unique identifier for this [tree].
  final String id;

  /// Root node of this tree.
  final TreeNode<T> root;

  /// Accessor function that returns the domain for a tree node.
  final TypedAccessor<TreeNode<T>, D> domain;

  /// Accessor function that returns the measure for a tree node.
  final TypedAccessor<TreeNode<T>, num?> measure;

  /// Accessor function that returns the rendered stroke color for a tree node.
  final TypedAccessor<TreeNode<T>, Color>? color;

  /// Accessor function that returns the rendered fill color for a tree node.
  /// If not provided, then [color] will be used as a fallback.
  final TypedAccessor<TreeNode<T>, Color>? fillColor;

  /// Accessor function that returns the pattern color for a tree node
  /// If not provided, then background color is used as default.
  final TypedAccessor<TreeNode<T>, Color>? patternColor;

  /// Accessor function that returns the fill pattern for a tree node.
  final TypedAccessor<TreeNode<T>, FillPatternType>? fillPattern;

  /// Accessor function that returns the stroke width for a tree node.
  final TypedAccessor<TreeNode<T>, double>? strokeWidth;

  /// Accessor function that returns the label for a tree node.
  final TypedAccessor<TreeNode<T>, String>? label;

  /// Accessor function that returns the style spec for a tree node label.
  final TypedAccessor<TreeNode<T>, TextStyle>? labelStyle;

  /// [attributes] stores additional key-value pairs of attributes this tree is
  /// associated with (e.g. rendererIdKey to renderer).
  final TreeAttributes attributes = TreeAttributes();

  /// Creates a [Series] that contains all [TreeNode]s traversing from the
  /// [root] of this tree.
  ///
  /// Considers the following tree:
  /// ```
  ///       A
  ///     / | \
  ///    B  C  D      --->    [A, B, C, D, E, F]
  ///         / \
  ///        E   F
  /// ```
  /// This method traverses from root node "A" in breadth-first order and
  /// adds all its children to a list. The order of [TreeNode]s in the list
  /// is based on the insertion order to children of a particular node.
  /// All [TreeNode]s are accessible through [Series].data.
  Series<TreeNode<T>, D> toSeries() {
    final data = <TreeNode<T>>[];
    root.visit(data.add);

    return Series(
      id: id,
      data: data,
      domain: domain,
      measure: measure,
      color: color,
      fillColor: fillColor,
      fillPattern: fillPattern,
      patternColor: patternColor,
      strokeWidth: strokeWidth,
      labelAccessor: label,
      insideLabelStyleAccessor: labelStyle,
    )..attributes.mergeFrom(attributes);
  }

  void setAttribute<R>(AttributeKey<R> key, R value) {
    attributes.setAttr(key, value);
  }

  R? getAttribute<R>(AttributeKey<R> key) {
    return attributes.getAttr<R>(key);
  }
}

class TreeNode<T> {
  TreeNode(this.data);

  /// Associated data this node stores.
  final T data;

  final List<TreeNode<T>> _children = [];

  int _depth = 0;

  TreeNode<T>? parent;

  /// Distance between this node and the root node.
  int get depth => _depth;

  @protected
  set depth(int val) {
    _depth = val;
  }

  /// List of child nodes.
  Iterable<TreeNode<T>> get children => _children;

  /// Whether or not this node has any children.
  bool get hasChildren => _children.isNotEmpty;

  /// Adds a single child to this node.
  void addChild(TreeNode<T> child) {
    child.parent = this;
    final delta = depth - child.depth + 1;
    if (delta != 0) {
      child.visit((node) => node.depth += delta);
    }
    _children.add(child);
  }

  /// Adds a list of children to this node.
  void addChildren(Iterable<TreeNode<T>> newChildren) {
    newChildren.forEach(addChild);
  }

  /// Applies the function [f] to all child nodes rooted from this node in
  /// breadth first order.
  void visit(void Function(TreeNode<T> node) f) {
    final queue = Queue<TreeNode<T>>()..add(this);

    while (queue.isNotEmpty) {
      final node = queue.removeFirst();
      f(node);
      queue.addAll(node.children);
    }
  }
}

/// A registry that stores key-value pairs of attributes.
class TreeAttributes extends TypedRegistry {}

/// Adapts a TypedAccessor<T, R> type to a TypedAccessor<TreeNode<T>, R>.
TypedAccessor<TreeNode<T>, R>? _castFrom<T, R>(TypedAccessor<T, R>? f) {
  return f == null
      ? null
      : (TreeNode<T> node, int? index) => f(node.data, index);
}
