// @license
// Copyright (c) 2019 - 2025 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_args/gg_args.dart';
import 'package:gg_local_package_dependencies/gg_local_package_dependencies.dart';
import 'package:gg_log/gg_log.dart';
import 'package:mocktail/mocktail.dart';

/// Creates a sorted processing list of dart packages in a folder
///
/// - First dependencies are processed
/// - Dependents follow
/// - Among nodes ready for processing, the one with the smallest name is chosen
class SortedProcessingList extends DirCommand<void> {
  /// Constructor
  SortedProcessingList({
    required super.ggLog,
    super.name = 'sorted-processing-list',
    super.description =
        'Creates a sorted processing list of all dart packages in a folder',
    Graph? graph,
  }) : _graph = graph ?? Graph(ggLog: ggLog);

  // ...........................................................................
  @override
  Future<void> exec({
    required Directory directory,
    required GgLog ggLog,
  }) async {
    final list = await get(directory: directory, ggLog: ggLog);
    for (final node in list) {
      ggLog(node.name);
    }
  }

  // ...........................................................................
  /// Returns a list of all nodes in processing order
  @override
  Future<List<Node>> get({
    required Directory directory,
    required GgLog ggLog,
  }) async {
    // Get the graph
    final graph = await _graph.get(directory: directory, ggLog: ggLog);

    // Collect all unique nodes
    final allNodesSet = <Node>{};
    void collect(Node node) {
      if (allNodesSet.contains(node)) return;
      allNodesSet.add(node);
      for (final dep in node.dependencies.values) {
        collect(dep);
      }
    }

    for (final root in graph.values) {
      collect(root);
    }

    // Sort by name
    final remaining = allNodesSet.toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    // Apply the algorithm
    final sortedNodes = <Node>[];
    while (remaining.isNotEmpty) {
      for (final item in [...remaining]) {
        if (item.dependencies.isEmpty) {
          sortedNodes.add(item);
          removeNodeFromList(remaining, item);
          break;
        }
      }
    }

    return sortedNodes;
  }

  // ######################
  // Private
  // ######################

  /// Removes a node from the list and all its dependencies
  void removeNodeFromList(List<Node> list, Node node) {
    list.remove(node);
    for (final item in list) {
      item.dependencies.removeWhere((key, value) => value == node);
    }
  }

  final Graph _graph;
}

/// Mock of SortedProcessingList
class MockSortedProcessingList extends Mock implements SortedProcessingList {}
