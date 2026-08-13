// @license
// Copyright (c) ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package_manifest.dart';

/// A node in the dependency graph.
class Node {
  /// Constructor.
  ///
  /// When [aliases] or [manifests] are omitted they default to the single
  /// [name] / [manifest], which keeps single-language nodes behaving exactly
  /// as before.
  Node({
    required this.name,
    required this.directory,
    required this.manifest,
    Set<String>? aliases,
    List<PackageManifest>? manifests,
  }) : aliases = aliases ?? <String>{name},
       manifests = manifests ?? <PackageManifest>[manifest];

  /// The name of the node.
  final String name;

  /// Language-agnostic manifest describing this package.
  ///
  /// When a directory provides several manifests (e.g. a cross-language repo
  /// with both `pubspec.yaml` and `package.json`) this is the primary one;
  /// see [manifests] for all of them.
  PackageManifest manifest;

  /// All manifests this package provides.
  ///
  /// A cross-language package (a repo carrying both a Dart and a TypeScript
  /// manifest) lists more than one entry here. The first entry equals
  /// [manifest].
  final List<PackageManifest> manifests;

  /// All names this package can be referenced by across languages.
  ///
  /// Contains the name of every manifest (e.g. the Dart package name and the
  /// npm package name) plus the directory name. Used to resolve dependency
  /// edges that cross language boundaries, where a dependent declares the
  /// dependency under a different name than its primary [name].
  final Set<String> aliases;

  /// Nodes this package needs to work.
  final Map<String, Node> dependencies = {};

  /// Nodes that need this package to work.
  final Map<String, Node> dependents = {};

  /// The directory of the node.
  final Directory directory;

  /// The string representation of the node.
  @override
  String toString() {
    return 'Node{name: $name, dependencies: $dependencies}';
  }
}
