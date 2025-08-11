// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_local_package_dependencies/gg_local_package_dependencies.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:pubspec_parse/pubspec_parse.dart';
import 'package:test/test.dart';

void main() {
  final d = Directory.systemTemp;

  group('Node', () {
    test('should work fine', () {
      final node = Node(
        name: 'name',
        directory: d,
        pubspec: Pubspec('name', version: Version(1, 0, 0)),
      );

      expect(node.name, 'name');
      expect(node.directory, d);
      expect(node.dependencies, <String, Node>{});
      expect(node.dependencies, <String, Node>{});
      expect(node.toString(), 'Node{name: name, dependencies: {}}');
    });
  });
}
