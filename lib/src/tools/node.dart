// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:pubspec_parse/pubspec_parse.dart';

/// A node in the dependency graph
class Node {
  /// Constructor
  Node({
    required this.name,
    required this.directory,
    required this.pubspec,
  });

  /// The name of the node
  final String name;

  /// Nodes this package needs to work
  final Map<String, Node> dependencies = {};

  /// Nodes that need this package to work
  final Map<String, Node> dependents = {};

  /// The directory of the node
  final Directory directory;

  /// The parsed pubspec.yaml file
  Pubspec pubspec;

  /// The string representation of the node
  @override
  String toString() {
    return 'Node{name: $name, dependencies: $dependencies}';
  }
}
