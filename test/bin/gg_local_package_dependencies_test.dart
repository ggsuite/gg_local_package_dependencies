// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import '../../bin/gg_local_package_dependencies.dart';

void main() {
  group('bin/gg_local_package_dependencies.dart', () {
    // #########################################################################

    test('should be executable', () async {
      // Execute bin/gg_local_package_dependencies.dart and check if it prints help
      final result = await Process.run(
        'dart',
        ['./bin/gg_local_package_dependencies.dart', 'xyz'],
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );

      final stdout = result.stdout as String;
      expect(stdout, contains('Could not find a subcommand named xyz'));
      expect(stdout, contains('graph  '));
      expect(stdout, contains('processing-list  '));
    });
  });

  // ###########################################################################
  group('run(args, log)', () {
    group('with args=[--param, value]', () {
      test('should print "value"', () async {
        // Execute bin/gg_local_package_dependencies.dart and check if it prints "value"
        final messages = <String>[];
        await run(args: ['graph', '--xyz', '5'], ggLog: messages.add);

        expect(
          messages.last,
          contains('Could not find an option named xyz.'),
        );
      });
    });
  });
}
