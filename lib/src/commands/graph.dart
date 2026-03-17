// @license
// Copyright (c) 2019 - 2025 Göran Hegenberg. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_args/gg_args.dart';
import 'package:gg_console_colors/gg_console_colors.dart';
import 'package:gg_local_package_dependencies/gg_local_package_dependencies.dart';
import 'package:gg_log/gg_log.dart';
import 'package:mocktail/mocktail.dart';

/// Returns dependency graph of packages in a local folder.
class Graph extends DirCommand<void> {
  /// Creates the graph command.
  Graph({
    required super.ggLog,
    super.name = 'graph',
    super.description =
        'Returns dependency graph of packages in a local folder.',
    List<PackageLanguage>? languages,
  }) : languages =
           languages ??
           <PackageLanguage>[
             DartPackageLanguage(),
             TypeScriptPackageLanguage(),
           ];

  /// Supported package languages used for discovery within folders.
  final List<PackageLanguage> languages;

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

  /// Returns a map of all root nodes in the dependency graph.
  @override
  Future<Map<String, Node>> get({
    required Directory directory,
    GgLog? ggLog,
  }) async {
    final log = ggLog ?? this.ggLog;

    // Get a list of all direct sub directories.
    final allDirs = directory.listSync().whereType<Directory>().toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    // Create a dictionary of name to node.
    final nodes = <String, Node>{};

    for (final dir in allDirs) {
      for (final language in languages) {
        if (!language.isPackageDirectory(dir)) {
          continue;
        }

        final manifest = await language.loadManifest(dir);
        final node = Node(
          name: manifest.name,
          directory: dir,
          manifest: manifest,
        );

        if (nodes.containsKey(node.name)) {
          _logDuplicatePackage(
            ggLog: log,
            packageName: node.name,
            packagePath: dir.path,
          );
          break;
        }

        nodes[node.name] = node;

        // A directory should be handled by at most one language, so stop
        // iterating languages once a match is found.
        break;
      }
    }

    // Estimate dependencies of all nodes.
    for (final node in nodes.values) {
      final dependencyNames = <String>[
        ...node.manifest.dependencies,
        ...node.manifest.devDependencies,
      ];

      for (final dependency in dependencyNames) {
        // Is the dependency locally found?
        final isFound = nodes.containsKey(dependency);
        if (!isFound) {
          continue;
        }

        // Get the dependent node.
        final dependentNode = nodes[dependency]!;

        // Add the dependency to the dependencies list.
        node.dependencies[dependency] = dependentNode;

        // Add this node to the dependents list of the dependent node.
        dependentNode.dependents[node.name] = node;
      }
    }

    // Detect circular dependencies.
    final coveredNodes = <Node>[];
    for (final node in nodes.values) {
      _detectCircularDependencies(node, coveredNodes);
    }

    // We want only root nodes.
    // A root node is a node that has no dependents.
    final rootNodes = nodes.values.where((node) => node.dependents.isEmpty);
    final result = <String, Node>{
      for (final item in rootNodes) item.name: item,
    };
    return result;
  }

  /// Returns all nodes that lie between the given nodes when moving strictly
  /// along a single hierarchy direction (only dependencies or only dependents)
  /// in the dependency forest.
  ///
  /// Semantics:
  /// - For every unordered pair of endpoints in [givenNodes], this method
  ///   determines the union of inner nodes (without endpoints) across all
  ///   simple directed paths that go exclusively via dependencies or
  ///   exclusively via dependents.
  /// - If multiple paths exist (e.g., diamond shape), the result contains the
  ///   union of all inner nodes on all such simple paths.
  /// - Endpoints are not included in the result.
  /// - The resulting list is unique and deterministically sorted by name.
  ///
  /// Edge cases:
  /// - If [givenNodes] has fewer than two nodes, an empty list is returned.
  /// - Nodes in [givenNodes] that are not present in [allNodes] are ignored.
  List<Node> getNodesBetween(
    Map<String, Node> allNodes,
    List<Node> givenNodes,
  ) {
    // Filter to nodes contained in allNodes and remove duplicates by identity
    // Collect all unique nodes
    final allowed = <Node>{};
    void collect(Node node) {
      if (allowed.contains(node)) {
        return;
      }
      allowed.add(node);
      for (final dep in node.dependencies.values) {
        collect(dep);
      }
    }

    for (final root in allNodes.values) {
      collect(root);
    }

    final endpoints = <Node>[];
    final seen = <Node>{};
    for (final n in givenNodes) {
      if (!allowed.contains(n)) {
        continue;
      }
      if (seen.contains(n)) {
        continue;
      }
      seen.add(n);
      endpoints.add(n);
    }

    if (endpoints.length < 2) {
      return <Node>[];
    }

    final resultSet = <Node>{};

    // Create a deterministic copy of allowed for neighbor filtering.
    final allowedByName = {for (final n in allowed) n.name: n};

    // Iterate over all unordered pairs (i < j).
    for (var i = 0; i < endpoints.length; i++) {
      for (var j = i + 1; j < endpoints.length; j++) {
        final a = endpoints[i];
        final b = endpoints[j];

        // Direction 1: dependencies only from A to B.
        List<Node> depsNeighbors(Node n) =>
            n.dependencies.values
                .where((x) => allowedByName.containsKey(x.name))
                .toList()
              ..sort((l, r) => l.name.compareTo(r.name));

        final pathsDeps = _allSimpleDirectedPaths(
          start: a,
          end: b,
          neighbors: depsNeighbors,
          allowed: allowed,
        );

        for (final p in pathsDeps) {
          _addInnerNodesToSet(p, resultSet);
        }

        // Direction 2: dependents only from A to B.
        List<Node> parentsNeighbors(Node n) =>
            n.dependents.values
                .where((x) => allowedByName.containsKey(x.name))
                .toList()
              ..sort((l, r) => l.name.compareTo(r.name));

        final pathsParents = _allSimpleDirectedPaths(
          start: a,
          end: b,
          neighbors: parentsNeighbors,
          allowed: allowed,
        );

        for (final p in pathsParents) {
          _addInnerNodesToSet(p, resultSet);
        }
      }
    }

    final result = resultSet.toList()..sort((l, r) => l.name.compareTo(r.name));
    return result;
  }

  /// Logs that a duplicate package was found and ignored.
  void _logDuplicatePackage({
    required GgLog ggLog,
    required String packageName,
    required String packagePath,
  }) {
    ggLog(
      yellow('Found duplicate package name: $packageName in ') +
          blue(packagePath),
    );
    ggLog(yellow("Project won't be added to dependency graph."));
  }

  /// Prints a node and its dependencies using indentation for hierarchy.
  void _printNode(Node node, GgLog ggLog, int indentation) {
    ggLog(' ' * indentation * 2 + node.name);
    for (final dependency in node.dependencies.values) {
      _printNode(dependency, ggLog, indentation + 1);
    }
  }

  /// Detects circular dependencies and throws an exception if a cycle is found.
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

  /// Returns all simple directed paths from [start] to [end] using [neighbors].
  List<List<Node>> _allSimpleDirectedPaths({
    required Node start,
    required Node end,
    required Iterable<Node> Function(Node) neighbors,
    required Set<Node> allowed,
  }) {
    final paths = <List<Node>>[];

    void dfs(Node current, List<Node> path, Set<Node> onPath) {
      if (identical(current, end)) {
        // Store a copy of the current path.
        paths.add(List<Node>.from(path));
        return;
      }

      for (final next in neighbors(current)) {
        if (!allowed.contains(next)) {
          continue;
        }
        if (onPath.contains(next)) {
          // Avoid cycles on the current path.
          continue;
        }
        onPath.add(next);
        path.add(next);
        dfs(next, path, onPath);
        path.removeLast();
        onPath.remove(next);
      }
    }

    dfs(start, [start], {start});
    return paths;
  }

  /// Adds all inner nodes of the path (without first and last) to [set].
  void _addInnerNodesToSet(List<Node> path, Set<Node> set) {
    if (path.length <= 2) {
      // Direct neighbors or identical.
      return;
    }
    for (var i = 1; i < path.length - 1; i++) {
      set.add(path[i]);
    }
  }
}

/// Mock of Graph.
class MockGraph extends Mock implements Graph {}
