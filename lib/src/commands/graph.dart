// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_args/gg_args.dart';
import 'package:gg_local_package_dependencies/gg_local_package_dependencies.dart';
import 'package:gg_log/gg_log.dart';
import 'package:pubspec_parse/pubspec_parse.dart';

// #############################################################################
/// An example command
class Graph extends DirCommand<void> {
  /// Constructor
  Graph({
    required super.ggLog,
    super.name = 'graph',
    super.description = 'Prints dependency graph of packages in a folder',
  });

  // ...........................................................................
  @override
  Future<void> exec({
    required Directory directory,
    required GgLog ggLog,
  }) async {
    final graph = await get(directory: directory, ggLog: ggLog);
    for (final node in graph.values) {
      _printNode(node, ggLog, 0);
    }
  }

  // ...........................................................................
  /// Returns a map of all root nodes in the dependency graph
  Future<Map<String, Node>> get({
    required Directory directory,
    required GgLog ggLog,
  }) async {
    // Get a list of all direct sub directories
    final allDirs = directory.listSync().whereType<Directory>();

    // Filter out dart packages
    final dartPackages = <Directory>[];
    for (final dir in allDirs) {
      final pubspec = File('${dir.path}/pubspec.yaml');
      if (await pubspec.exists()) {
        dartPackages.add(dir);
      }
    }

    // Create a dictionary of name to node
    final nodes = <String, Node>{};
    for (final dartPackage in dartPackages) {
      final pubspec = File('${dartPackage.path}/pubspec.yaml');
      final pubspecContent = await pubspec.readAsString();
      final pubspecYaml = Pubspec.parse(pubspecContent);
      final node = Node(
        name: pubspecYaml.name,
        directory: dartPackage,
        pubspec: pubspecYaml,
      );
      nodes[node.name] = node;
    }

    // Estimate dependencies of all nodes
    for (final node in nodes.values) {
      // Iterate all dependencies
      for (final dependency in node.pubspec.dependencies.keys) {
        // Is the dependency locally found?
        final isFound = nodes.containsKey(dependency);
        if (!isFound) continue;

        // Get the dependent node
        final dependentNode = nodes[dependency]!;

        // Add the dependency to the dependencies list
        node.dependencies[dependency] = dependentNode;

        // Add this node to the dependents list of the dependent node
        dependentNode.dependents[node.name] = node;
      }
    }

    // We want only root nodes.
    // A root node is a node that has no dependents.
    final rootNodes = nodes.values.where((node) => node.dependents.isEmpty);
    Map<String, Node> result = {for (var item in rootNodes) item.name: item};
    return result;
  }

  // ...........................................................................
  void _printNode(Node node, GgLog ggLog, int indentation) {
    ggLog(' ' * indentation * 2 + node.name);
    for (final dependency in node.dependencies.values) {
      _printNode(dependency, ggLog, indentation + 1);
    }
  }
}
