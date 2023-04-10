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

import 'dart:ui' show Color;

import '../chart/chart_canvas.dart';
import '../typed_registry.dart';
import 'graph_utils.dart';
import 'series.dart' show AttributeKey, Series, TypedAccessor;

/// Used for readability to indicate where any indexed value can be returned
/// by a [TypedAccessor].
const int indexNotRelevant = 0;

class Graph<N, L, D> {
  factory Graph({
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
  }) {
    return Graph.base(
      id: id,
      nodes:
          convertGraphNodes<N, L, D>(nodes, links, source, target, nodeDomain),
      links: convertGraphLinks<N, L>(links, source, target),
      nodeDomain: actOnNodeData<N, L, D>(nodeDomain)!,
      linkDomain: actOnLinkData<N, L, D>(linkDomain)!,
      nodeMeasure: actOnNodeData<N, L, num?>(nodeMeasure)!,
      linkMeasure: actOnLinkData<N, L, num?>(linkMeasure)!,
      nodeColor: actOnNodeData<N, L, Color>(nodeColor),
      nodeFillColor: actOnNodeData<N, L, Color>(nodeFillColor),
      nodeFillPattern: actOnNodeData<N, L, FillPatternType>(nodeFillPattern),
      nodeStrokeWidthPx: actOnNodeData<N, L, double>(nodeStrokeWidth),
      linkFillColor: actOnLinkData<N, L, Color>(linkFillColor),
    );
  }

  Graph.base({
    required this.id,
    required this.nodes,
    required this.links,
    required this.nodeDomain,
    required this.linkDomain,
    required this.nodeMeasure,
    required this.linkMeasure,
    required this.nodeColor,
    required this.nodeFillColor,
    required this.nodeFillPattern,
    required this.nodeStrokeWidthPx,
    required this.linkFillColor,
  });

  /// Unique identifier for this graph
  final String id;

  /// All nodes in the graph.
  final List<Node<N, L>> nodes;

  /// All links in the graph.
  final List<Link<N, L>> links;

  /// Accessor function that returns the domain for a node.
  ///
  /// The domain should be a unique identifier for the node
  final TypedAccessor<Node<N, L>, D> nodeDomain;

  /// Accessor function that returns the domain for a link.
  ///
  /// The domain should be a unique identifier for the link
  final TypedAccessor<Link<N, L>, D> linkDomain;

  /// Accessor function that returns the measure for a node.
  ///
  /// The measure should be the double value at the node.
  final TypedAccessor<Node<N, L>, num?> nodeMeasure;

  /// Accessor function that returns the measure for a link.
  ///
  /// The measure should be the double value through the link.
  final TypedAccessor<Link<N, L>, num?> linkMeasure;

  /// Accessor function that returns the stroke color of a node
  final TypedAccessor<Node<N, L>, Color>? nodeColor;

  /// Accessor function that returns the fill color of a node
  final TypedAccessor<Node<N, L>, Color>? nodeFillColor;

  /// Accessor function that returns the fill pattern of a node
  final TypedAccessor<Node<N, L>, FillPatternType>? nodeFillPattern;

  /// Accessor function that returns the stroke width of a node
  final TypedAccessor<Node<N, L>, double>? nodeStrokeWidthPx;

  /// Accessor function that returns the fill color of a node
  final TypedAccessor<Link<N, L>, Color>? linkFillColor;

  /// Store additional key-value pairs for node attributes
  final NodeAttributes nodeAttributes = NodeAttributes();

  /// Store additional key-value pairs for link attributes
  final LinkAttributes linkAttributes = LinkAttributes();

  /// Transform graph data given by links and nodes into a [Series] list.
  ///
  /// Output should contain two [Series] with the format:
  /// `[Series<Node<N,L>> nodeSeries, Series<Link<N,L>> linkSeries]`
  List<Series<GraphElement, D>> toSeriesList() {
    final Series<Node<N, L>, D> nodeSeries = Series(
      id: '${id}_nodes',
      data: nodes,
      domain: nodeDomain,
      measure: nodeMeasure,
      color: nodeColor,
      fillColor: nodeFillColor,
      fillPattern: nodeFillPattern,
      strokeWidth: nodeStrokeWidthPx,
    )..attributes.mergeFrom(nodeAttributes);

    final Series<Link<N, L>, D> linkSeries = Series(
      id: '${id}_links',
      data: links,
      domain: linkDomain,
      measure: linkMeasure,
      fillColor: linkFillColor,
    )..attributes.mergeFrom(linkAttributes);
    return [nodeSeries, linkSeries];
  }

  /// Set attribute of given generic type R for a node series
  void setNodeAttribute<R>(AttributeKey<R> key, R value) {
    nodeAttributes.setAttr(key, value);
  }

  /// Get attribute of given generic type R for a node series
  R? getNodeAttribute<R>(AttributeKey<R> key) {
    return nodeAttributes.getAttr<R>(key);
  }

  /// Set attribute of given generic type R for a link series
  void setLinkAttribute<R>(AttributeKey<R> key, R value) {
    linkAttributes.setAttr(key, value);
  }

  /// Get attribute of given generic type R for a link series
  R? getLinkAttribute<R>(AttributeKey<R> key) {
    return linkAttributes.getAttr<R>(key);
  }
}

/// Return a list of links from the generic link data type
List<Link<N, L>> convertGraphLinks<N, L>(
    List<L> links, TypedAccessor<L, N> source, TypedAccessor<L, N> target) {
  final List<Link<N, L>> graphLinks = [];

  for (int i = 0; i < links.length; i += 1) {
    final N sourceNode = source(links[i], i);
    final N targetNode = target(links[i], i);
    graphLinks.add(Link(Node(sourceNode), Node(targetNode), links[i]));
  }

  return graphLinks;
}

/// Return a list of nodes from the generic node data type
List<Node<N, L>> convertGraphNodes<N, L, D>(
  List<N> nodes,
  List<L> links,
  TypedAccessor<L, N> source,
  TypedAccessor<L, N> target,
  TypedAccessor<N, D> nodeDomain,
) {
  final List<Node<N, L>> graphNodes = [];

  final graphLinks = convertGraphLinks(links, source, target);
  final nodeClassDomain = actOnNodeData<N, L, D>(nodeDomain)!;
  final nodeMap = <D, Node<N, L>>{};

  // Populate nodeMap with user provided nodes
  for (final node in nodes) {
    nodeMap.putIfAbsent(nodeDomain(node, indexNotRelevant), () => Node(node));
  }

  // Add ingoing and outgoing links to the nodes in nodeMap
  for (final link in graphLinks) {
    nodeMap.update(nodeClassDomain(link.target, indexNotRelevant),
        (node) => addLinkToNode(node, link, isIncomingLink: true),
        ifAbsent: () => addLinkToAbsentNode(link, isIncomingLink: true));
    nodeMap.update(nodeClassDomain(link.source, indexNotRelevant),
        (node) => addLinkToNode(node, link, isIncomingLink: false),
        ifAbsent: () => addLinkToAbsentNode(link, isIncomingLink: false));
  }

  nodeMap.forEach((domainId, node) => graphNodes.add(node));

  return graphNodes;
}

/// A registry that stores key-value pairs of attributes for nodes.
class NodeAttributes extends TypedRegistry {}

/// A registry that stores key-value pairs of attributes for links.
class LinkAttributes extends TypedRegistry {}

/// A node in a graph containing user defined data and connected links.
class Node<N, L> extends GraphElement<N> {
  Node(
    N data, {
    List<Link<N, L>>? incomingLinks,
    List<Link<N, L>>? outgoingLinks,
  })  : incomingLinks = incomingLinks ?? [],
        outgoingLinks = outgoingLinks ?? [],
        super(data);

  /// Return.a copy of a node with all associated links.
  Node.clone(Node<N, L> node)
      : this(node.data,
            incomingLinks: _cloneLinkList<N, L>(node.incomingLinks),
            outgoingLinks: _cloneLinkList<N, L>(node.outgoingLinks));

  /// Return a copy of a node with user defined data only, no links.
  Node.cloneData(Node<N, L> node) : this(node.data);

  /// All links that flow into this SankeyNode. Calculated from graph links.
  List<Link<N, L>> incomingLinks;

  /// All links that flow from this SankeyNode. Calculated from graph links.
  List<Link<N, L>> outgoingLinks;
}

/// A link in a graph connecting a source node and target node.
class Link<N, L> extends GraphElement<L> {
  Link(this.source, this.target, L data) : super(data);

  Link.clone(Link<N, L> link)
      : this(
          Node.cloneData(link.source),
          Node.cloneData(link.target),
          link.data,
        );

  /// The source Node for this Link.
  final Node<N, L> source;

  /// The target Node for this Link.
  final Node<N, L> target;
}

List<Link<N, L>> _cloneLinkList<N, L>(List<Link<N, L>> linkList) {
  return linkList.map((link) => Link.clone(link)).toList();
}

/// A [Link] or [Node] element in a graph containing user defined data.
abstract class GraphElement<G> {
  GraphElement(this.data);

  /// Data associated with this graph element
  final G data;
}
