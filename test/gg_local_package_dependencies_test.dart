// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_local_package_dependencies/gg_local_package_dependencies.dart';
import 'package:test/test.dart';
import 'package:gg_args/gg_args.dart';

void main() {
  final messages = <String>[];

  setUp(() {
    messages.clear();
  });

  group('GgLocalPackageDependencies()', () {
    // #########################################################################
    group('GgLocalPackageDependencies', () {
      final ggLocalPackageDependencies =
          GgLocalPackageDependencies(ggLog: messages.add);

      // .......................................................................
      test('should show all sub commands', () async {
        final (subCommands, errorMessage) = await missingSubCommands(
          directory: Directory('lib/src/commands'),
          command: ggLocalPackageDependencies,
        );

        expect(subCommands, isEmpty, reason: errorMessage);
      });
    });
  });
}
