// @license
// Copyright (c) 2019 - 2025 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:gg_local_package_dependencies/gg_local_package_dependencies.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';

void main() {
  group('SortedProcessingList', () {
    final d = Directory(join('test', 'sample_folder', 'hierarchical'));
    final dPlain = Directory(join('test', 'sample_folder', 'plain'));

    late SortedProcessingList sortedProcessingList;
    final messages = <String>[];
    final ggLog = messages.add;
    late CommandRunner<void> runner;

    // .........................................................................
    setUp(() async {
      expect(await d.exists(), isTrue);
      messages.clear();
      runner = CommandRunner<void>('test', 'test');
      sortedProcessingList = SortedProcessingList(ggLog: ggLog);
      runner.addCommand(sortedProcessingList);
    });

    group('main cases', () {
      group(
          'should return a sorted processing list of all dart packages '
          'in a folder', () {
        test('programmatically', () async {
          final result = await sortedProcessingList.get(
            directory: d,
            ggLog: ggLog,
          );
          expect(result.length, 7);
          final names = result.map((e) => e.name).toList();
          expect(names, [
            'pack011',
            'pack012',
            'pack01',
            'pack02',
            'pack031',
            'pack03',
            'pack0',
          ]);
        });

        test('via CLI', () async {
          await runner.run(['sorted-processing-list', '-i', d.path]);
          expect(messages.length, 7);
          expect(messages[0], 'pack011');
          expect(messages[1], 'pack012');
          expect(messages[2], 'pack01');
          expect(messages[3], 'pack02');
          expect(messages[4], 'pack031');
          expect(messages[5], 'pack03');
          expect(messages[6], 'pack0');
        });
      });
    });

    group('special cases', () {
      test(
        'folder does contain a plain list of independent packages',
        () async {
          final result = await sortedProcessingList.get(
            directory: dPlain,
            ggLog: ggLog,
          );
          final names = result.map((e) => e.name).toList();
          expect(names, ['pack0', 'pack1', 'pack2']);
        },
      );
    });
  });
}
