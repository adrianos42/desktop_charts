// Copyright (C) 2023 Adriano Souza (adriano.souza113@gmail.com)

// Copyright 2021 the Charts project authors. Please see the AUTHORS file
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

import 'graph.dart';
import 'series.dart' show TypedAccessor;

const graphCycleErrorMsg = 'The given graph contains a cycle.';

/// If the node accessor is not null return a function to act on a graph [Node].
TypedAccessor<Node<N, L>, R>? actOnNodeData<N, L, R>(
    TypedAccessor<N, R>? f) {
  return f == null
      ? null
      : (Node<N, L> node, int? index) => f(node.data, index);
}

/// If the node accessor is not null return a function to act on a graph [Link].
TypedAccessor<Link<N, L>, R>? actOnLinkData<N, L, R>(
    TypedAccessor<L, R>? f) {
  return f == null
      ? null
      : (Link<N, L> link, int? index) => f(link.data, index);
}

/// Add an incoming or outgoing link to a [Node].
Node<N, L> addLinkToNode<N, L>(
  Node<N, L> node,
  Link<N, L> link, {
  required bool isIncomingLink,
}) {
  if (isIncomingLink) {
    node.incomingLinks.add(link);
  } else {
    node.outgoingLinks.add(link);
  }

  return node;
}

/// Construct a [Node] with the added [Link].
Node<N, L> addLinkToAbsentNode<N, L>(
  Link<N, L> link, {
  required bool isIncomingLink,
}) {
  Node<N, L> node = isIncomingLink ? link.target : link.source;

  return addLinkToNode(node, link, isIncomingLink: isIncomingLink);
}

/// Call an accessor if it exists on input else return null.
R? accessorIfExists<T, R>(TypedAccessor<T, R>? method, T input, int index) {
  return method == null ? null : method(input, index);
}
