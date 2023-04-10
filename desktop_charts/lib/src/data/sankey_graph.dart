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

import 'package:desktop/desktop.dart';

import '../chart/chart_canvas.dart' show FillPatternType;
import 'graph.dart';
import 'graph_utils.dart';
import 'series.dart' show TypedAccessor;

/// Directed acyclic graph with Sankey diagram related data.
class SankeyGraph<N, L, D> extends Graph<N, L, D> {
  factory SankeyGraph({
    required String id,
    required List<N> nodes,
    required List<L> links,
    required TypedAccessor<N, D> nodeDomain,
    required TypedAccessor<L, D> linkDomain,
    required TypedAccessor<L, N> source,
    required TypedAccessor<L, N> target,
    required TypedAccessor<N, num?> nodeMeasure,
    required TypedAccessor<L, num?> linkMeasure,
    TypedAccessor<N, Color>? nodeColor,
    TypedAccessor<N, Color>? nodeFillColor,
    TypedAccessor<N, FillPatternType>? nodeFillPattern,
    TypedAccessor<N, double>? nodeStrokeWidth,
    TypedAccessor<L, Color>? linkFillColor,
    TypedAccessor<L, num>? secondaryLinkMeasure,
    TypedAccessor<N, int>? column,
  }) {
    return SankeyGraph._(
      id: id,
      nodes: _convertSankeyNodes<N, L, D>(
          nodes, links, source, target, nodeDomain),
      links: _convertSankeyLinks<N, L>(
          links, source, target, secondaryLinkMeasure),
      nodeDomain: actOnNodeData<N, L, D>(nodeDomain)!,
      linkDomain: actOnLinkData<N, L, D>(linkDomain)!,
      nodeMeasure: actOnNodeData<N, L, num?>(nodeMeasure)!,
      linkMeasure: actOnLinkData<N, L, num?>(linkMeasure)!,
      nodeColor: actOnNodeData<N, L, Color>(nodeColor),
      nodeFillColor: actOnNodeData<N, L, Color>(nodeFillColor),
      nodeFillPattern: actOnNodeData<N, L, FillPatternType>(nodeFillPattern),
      nodeStrokeWidth: actOnNodeData<N, L, double>(nodeStrokeWidth),
      linkFillColor: actOnLinkData<N, L, Color>(linkFillColor),
    );
  }

  SankeyGraph._({
    required super.nodes,
    required super.links,
    required String id,
    required TypedAccessor<Node<N, L>, D> nodeDomain,
    required TypedAccessor<Link<N, L>, D> linkDomain,
    required TypedAccessor<Node<N, L>, num?> nodeMeasure,
    required TypedAccessor<Link<N, L>, num?> linkMeasure,
    TypedAccessor<Node<N, L>, Color>? nodeColor,
    TypedAccessor<Node<N, L>, Color>? nodeFillColor,
    TypedAccessor<Node<N, L>, FillPatternType>? nodeFillPattern,
    TypedAccessor<Node<N, L>, double>? nodeStrokeWidth,
    TypedAccessor<Link<N, L>, Color>? linkFillColor,
  }) : super.base(
          id: id,
          nodeDomain: nodeDomain,
          nodeMeasure: nodeMeasure,
          linkDomain: linkDomain,
          linkMeasure: linkMeasure,
          nodeColor: nodeColor,
          nodeFillColor: nodeFillColor,
          nodeFillPattern: nodeFillPattern,
          nodeStrokeWidthPx: nodeStrokeWidth,
          linkFillColor: linkFillColor,
        );
}

/// Return a list of links from the Sankey link data type
List<SankeyLink<N, L>> _convertSankeyLinks<N, L>(
  List<L> links,
  TypedAccessor<L, N> source,
  TypedAccessor<L, N> target, [
  TypedAccessor<L, num>? secondaryLinkMeasureFn,
]) {
  final List<SankeyLink<N, L>> graphLinks = [];
  for (final link in links) {
    final sourceNode = source(link, indexNotRelevant);
    final targetNode = target(link, indexNotRelevant);
    final secondaryLinkMeasure = accessorIfExists<L, num>(
        secondaryLinkMeasureFn, link, indexNotRelevant);
    graphLinks.add(SankeyLink(
        SankeyNode(sourceNode), SankeyNode(targetNode), link,
        secondaryLinkMeasure: secondaryLinkMeasure));
  }
  return graphLinks;
}

/// Return a list of nodes from the Sankey node data type
List<SankeyNode<N, L>> _convertSankeyNodes<N, L, D>(
  List<N> nodes,
  List<L> links,
  TypedAccessor<L, N> source,
  TypedAccessor<L, N> target,
  TypedAccessor<N, D> nodeDomain,
) {
  final List<SankeyNode<N, L>> graphNodes = [];
  final graphLinks = _convertSankeyLinks(links, source, target);
  final nodeClassDomain = actOnNodeData<N, L, D>(nodeDomain)!;
  final nodeMap = <D, SankeyNode<N, L>>{};

  for (final node in nodes) {
    nodeMap.putIfAbsent(
        nodeDomain(node, indexNotRelevant), () => SankeyNode(node));
  }

  for (final link in graphLinks) {
    nodeMap.update(nodeClassDomain(link.target, indexNotRelevant),
        (node) => _addLinkToSankeyNode(node, link, isIncomingLink: true),
        ifAbsent: () => _addLinkToAbsentSankeyNode(link, isIncomingLink: true));
    nodeMap.update(nodeClassDomain(link.source, indexNotRelevant),
        (node) => _addLinkToSankeyNode(node, link, isIncomingLink: false),
        ifAbsent: () =>
            _addLinkToAbsentSankeyNode(link, isIncomingLink: false));
  }

  nodeMap.forEach((domainId, node) => graphNodes.add(node));
  return graphNodes;
}

/// Returns a list of nodes sorted topologically for a directed acyclic graph.
@visibleForTesting
List<Node<N, L>> topologicalNodeSort<N, L, D>(
  List<Node<N, L>> givenNodes,
  TypedAccessor<Node<N, L>, D> nodeDomain,
  TypedAccessor<Link<N, L>, D> linkDomain,
) {
  final nodeMap = <D, Node<N, L>>{};
  final givenNodeMap = <D, Node<N, L>>{};
  final sortedNodes = <Node<N, L>>[];
  final sourceNodes = <Node<N, L>>[];
  final nodes = _cloneNodeList(givenNodes);

  for (int i = 0; i < nodes.length; i += 1) {
    nodeMap.putIfAbsent(nodeDomain(nodes[i], indexNotRelevant), () => nodes[i]);
    givenNodeMap.putIfAbsent(
        nodeDomain(givenNodes[i], indexNotRelevant), () => givenNodes[i]);
    if (nodes[i].incomingLinks.isEmpty) {
      sourceNodes.add(nodes[i]);
    }
  }

  while (sourceNodes.isNotEmpty) {
    final source = sourceNodes.removeLast();
    sortedNodes
        .add(givenNodeMap[nodeDomain(source, indexNotRelevant)] as Node<N, L>);
    while (source.outgoingLinks.isNotEmpty) {
      final toRemove = source.outgoingLinks.removeLast();
      nodeMap[nodeDomain(toRemove.target, indexNotRelevant)]
          ?.incomingLinks
          .removeWhere((link) =>
              linkDomain(link, indexNotRelevant) ==
              linkDomain(toRemove, indexNotRelevant));
      if (nodeMap[nodeDomain(toRemove.target, indexNotRelevant)]!
          .incomingLinks
          .isEmpty) {
        sourceNodes.add(nodeMap[nodeDomain(toRemove.target, indexNotRelevant)]
            as Node<N, L>);
      }
    }
  }

  if (nodeMap.values.any((node) =>
      node.incomingLinks.isNotEmpty || node.outgoingLinks.isNotEmpty)) {
    throw UnsupportedError(graphCycleErrorMsg);
  }

  return sortedNodes;
}

List<Node<N, L>> _cloneNodeList<N, L>(List<Node<N, L>> nodeList) {
  return nodeList.map((node) => Node.clone(node)).toList();
}

SankeyNode<N, L> _addLinkToSankeyNode<N, L>(
  SankeyNode<N, L> node,
  SankeyLink<N, L> link, {
  required bool isIncomingLink,
}) {
  return addLinkToNode(node, link, isIncomingLink: isIncomingLink)
      as SankeyNode<N, L>;
}

SankeyNode<N, L> _addLinkToAbsentSankeyNode<N, L>(
  SankeyLink<N, L> link, {
  required bool isIncomingLink,
}) {
  return addLinkToAbsentNode(link, isIncomingLink: isIncomingLink)
      as SankeyNode<N, L>;
}

/// A Sankey specific [Node] in the graph.
///
/// We store the Sankey specific column, and the depth and height given that a
/// [SankeyGraph] is directed and acyclic. These cannot be stored on a [Series].
class SankeyNode<N, L> extends Node<N, L> {
  SankeyNode(
    super.data, {
    super.incomingLinks,
    super.outgoingLinks,
    this.depth,
    this.height,
    this.column,
  });

  /// Number of links from node to nearest root.
  ///
  /// Calculated from graph structure.
  int? depth;

  /// Number of links on the longest path to a leaf node.
  ///
  /// Calculated from graph structure.
  int? height;

  /// The column this node occupies in the Sankey graph.
  ///
  /// Sankey column may or may not be equal to depth. It can be assigned to
  /// height or defined to align nodes left or right, depending on if they are
  /// roots or leaves.
  int? column;
}

/// A Sankey specific [Link] in the graph.
///
/// We store the optional Sankey exclusive secondary link measure on the
/// [SankeyLink] for variable links since it cannot be stored on a [Series].
class SankeyLink<N, L> extends Link<N, L> {
  SankeyLink(
    super.source,
    super.target,
    super.data, {
    this.secondaryLinkMeasure,
  });

  /// Measure of a link at the target node if the link has variable value.
  ///
  /// Standard series measure will be the source value.
  num? secondaryLinkMeasure;
}
