// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_args/gg_args.dart';
import 'package:gg_local_package_dependencies/gg_local_package_dependencies.dart';
import 'package:gg_log/gg_log.dart';
import 'package:mocktail/mocktail.dart';

// #############################################################################
/// Creates a processing list of dart packages in a folder
///
/// - First dependencies are processed
/// - Dependents follow
class ProcessingList extends DirCommand<void> {
  /// Constructor
  ProcessingList({
    required super.ggLog,
    super.name = 'processing-list',
    super.description =
        'Creates a processing list of all dart packages in a folder',
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
  /// Returns a map of all root nodes in the dependency graph
  @override
  Future<List<Node>> get({
    required Directory directory,
    GgLog? ggLog,
  }) async {
    final result = <Node>[];

    // Calculate a graph
    final graph = await _graph.get(directory: directory, ggLog: ggLog);

    for (final node in graph.values) {
      _processNode(node, result);
    }

    return result;
  }

  // ######################
  // Private
  // ######################

  void _processNode(Node node, List<Node> result) {
    if (result.contains(node)) {
      return;
    }

    for (final dependency in node.dependencies.values) {
      _processNode(dependency, result);
    }

    result.add(node);
  }

  final Graph _graph;
}

/// Mock of Graph
class MockProcessingList extends Mock implements ProcessingList {}
