// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_args/gg_args.dart';
import 'package:gg_console_colors/gg_console_colors.dart';
import 'package:gg_local_package_dependencies/gg_local_package_dependencies.dart';
import 'package:gg_log/gg_log.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pubspec_parse/pubspec_parse.dart';

// #############################################################################
/// Returns dependency graph of packages in a local folder.
class Graph extends DirCommand<void> {
  /// Constructor
  Graph({
    required super.ggLog,
    super.name = 'graph',
    super.description =
        'Returns dependency graph of packages in a local folder.',
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
  @override
  Future<Map<String, Node>> get({
    required Directory directory,
    required GgLog ggLog,
  }) async {
    // Get a list of all direct sub directories
    final allDirs = directory.listSync().whereType<Directory>().toList()
      ..sort((a, b) => a.path.compareTo(b.path));

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
      late Pubspec pubspecYaml;
      try {
        pubspecYaml = Pubspec.parse(pubspecContent);
      } catch (e) {
        throw Exception(red('Error parsing pubspec.yaml:') + e.toString());
      }
      final node = Node(
        name: pubspecYaml.name,
        directory: dartPackage,
        pubspec: pubspecYaml,
      );

      if (nodes.containsKey(node.name)) {
        throw Exception('Duplicate package name: ${node.name}');
      }

      nodes[node.name] = node;
    }

    // Estimate dependencies of all nodes
    for (final node in nodes.values) {
      // Iterate all dependencies
      final keys = [
        ...node.pubspec.dependencies.keys,
        ...node.pubspec.devDependencies.keys,
      ];

      for (final dependency in keys) {
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

    // Detect circular dependencies
    final coveredNodes = <Node>[];
    for (final node in nodes.values) {
      _detectCircularDependencies(node, coveredNodes);
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

  // ...........................................................................
  void _detectCircularDependencies(Node node, List<Node> coveredNodes) {
    if (coveredNodes.contains(node)) {
      final indexOCoveredNode = coveredNodes.indexOf(node);
      final circularNodes = [...coveredNodes.sublist(indexOCoveredNode), node];
      final circularNodeNames = circularNodes.map((n) => n.name).join(' -> ');

      final part0 = red('Please remove circular dependency:\n');
      final part1 = yellow(circularNodeNames);

      throw Exception('$part0$part1');
    }

    for (final dependency in node.dependencies.values) {
      _detectCircularDependencies(dependency, [...coveredNodes, node]);
    }
  }
}

/// Mock of Graph
class MockGraph extends Mock implements Graph {}
