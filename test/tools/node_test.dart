// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_local_package_dependencies/gg_local_package_dependencies.dart';
import 'package:test/test.dart';

/// Simple test manifest implementation.
class _TestManifest implements PackageManifest {
  _TestManifest(this.name);

  @override
  final String name;

  @override
  Iterable<String> get dependencies => const <String>[];

  @override
  Iterable<String> get devDependencies => const <String>[];
}

void main() {
  final d = Directory.systemTemp;

  group('Node', () {
    test('should work fine', () {
      final node = Node(
        name: 'name',
        directory: d,
        manifest: _TestManifest('name'),
      );

      expect(node.name, 'name');
      expect(node.directory, d);
      expect(node.dependencies, <String, Node>{});
      expect(node.dependents, <String, Node>{});
      expect(node.manifest.name, 'name');
      expect(node.toString(), 'Node{name: name, dependencies: {}}');
    });
  });
}
