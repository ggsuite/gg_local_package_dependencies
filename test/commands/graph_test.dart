// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:gg_local_package_dependencies/gg_local_package_dependencies.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:pubspec_parse/pubspec_parse.dart';

void main() {
  final d = Directory(join('test', 'sample_folder', 'hierarchical'));
  final dPlain = Directory(join('test', 'sample_folder', 'plain'));
  final dDuplicate = Directory(join('test', 'sample_folder', 'duplicates'));
  final dCircular = Directory(join('test', 'sample_folder', 'circular'));
  final dDev = Directory(join('test', 'sample_folder', 'dev'));
  late Graph graph;
  final messages = <String>[];
  final ggLog = messages.add;
  late CommandRunner<void> runner;

  // ...........................................................................
  setUp(() async {
    expect(await d.exists(), isTrue);
    messages.clear();
    runner = CommandRunner<void>('test', 'test');
    graph = Graph(ggLog: ggLog);
    runner.addCommand(graph);
  });

  // ...........................................................................
  tearDown(() {});

  group('Graph', () {
    group('main case', () {
      group('should return a graph showing package dependencies', () {
        test('programmatically', () async {
          final result = await graph.get(directory: d, ggLog: ggLog);
          expect(result.length, 1);
          expect(result.keys, {'pack0'});

          // pack0
          final pack0 = result['pack0']!;
          expect(pack0.name, 'pack0');
          expect(pack0.directory.path, join(d.path, 'pack0'));
          expect(pack0.dependents, isEmpty);
          expect(pack0.dependencies.keys, {'pack01', 'pack02', 'pack03'});

          // ......
          // pack01
          final pack01 = pack0.dependencies['pack01']!;
          expect(pack01.name, 'pack01');
          expect(pack01.directory.path, join(d.path, 'pack01'));
          expect(pack01.dependents.keys, {'pack0'});
          expect(pack01.dependencies.keys, {'pack011', 'pack012'});

          // pack01
          final pack02 = pack0.dependencies['pack02']!;
          expect(pack02.name, 'pack02');
          expect(pack02.directory.path, join(d.path, 'pack02'));
          expect(pack02.dependents.keys, {'pack0'});
          expect(pack02.dependencies, isEmpty);

          // pack03
          final pack03 = pack0.dependencies['pack03']!;
          expect(pack03.name, 'pack03');
          expect(pack03.directory.path, join(d.path, 'pack03'));
          expect(pack03.dependents.keys, {'pack0'});
          expect(pack03.dependencies.keys, {'pack031'});

          // .......
          // pack011
          final pack011 = pack01.dependencies['pack011']!;
          expect(pack011.name, 'pack011');
          expect(pack011.directory.path, join(d.path, 'pack011'));
          expect(pack011.dependents.keys, {'pack01'});
          expect(pack011.dependencies, isEmpty);

          // pack012
          final pack012 = pack01.dependencies['pack012']!;
          expect(pack012.name, 'pack012');
          expect(pack012.directory.path, join(d.path, 'pack012'));
          expect(pack012.dependents.keys, {'pack01'});
          expect(pack012.dependencies, isEmpty);

          // pack031
          final pack031 = pack03.dependencies['pack031']!;
          expect(pack031.name, 'pack031');
          expect(pack031.directory.path, join(d.path, 'pack031'));
          expect(pack031.dependents.keys, {'pack03'});
          expect(pack031.dependencies, isEmpty);
        });

        test('via CLI', () async {
          await runner.run(['graph', '-i', d.path]);
          expect(messages[0], 'pack0');
          expect(messages[1], '  pack01');
          expect(messages[2], '    pack011');
          expect(messages[3], '    pack012');
          expect(messages[4], '  pack02');
          expect(messages[5], '  pack03');
          expect(messages[6], '    pack031');
        });
      });

      test('should complain about circular dependencies', () async {
        late String exception;
        try {
          await graph.get(directory: dCircular, ggLog: ggLog);
        } catch (e) {
          exception = e.toString();
        }

        expect(exception, contains('Please remove circular dependency:'));
        expect(
          exception,
          contains('pack1 -> pack2 -> pack3b -> pack1'),
        );
      });

      test('should incorporate dev dependencies', () async {
        final result = await graph.get(directory: dDev, ggLog: ggLog);

        final names = result.keys.toList()..sort();
        expect(names, ['pack0', 'pack1', 'pack2']);

        final pack1 = result['pack1']!;
        expect(pack1.dependencies.keys.toList()..sort(), ['pack_dev_0']);

        final packDev0 = pack1.dependencies['pack_dev_0']!;
        expect(packDev0.dependencies.keys.toList()..sort(), ['pack_dev_1']);
      });
    });
    group('special case', () {
      test(
        'folder does contain a plain list of independent packages',
        () async {
          final result = await graph.get(directory: dPlain, ggLog: ggLog);

          final names = result.keys.toList()..sort();
          expect(names, ['pack0', 'pack1', 'pack2']);
        },
      );

      group('should throw', () {
        test('when multiple packages have the same name', () async {
          late Exception exception;
          try {
            await graph.get(directory: dDuplicate, ggLog: ggLog);
          } catch (e) {
            exception = e as Exception;
          }

          expect(exception, isA<Exception>());
          expect(
            exception.toString(),
            'Exception: Duplicate package name: pack0',
          );
        });

        test('when a package contains an invalid pubspec.yaml', () async {
          final d = await Directory.systemTemp.createTemp();
          final d0 = Directory(join(d.path, 'p0'));
          await d0.create();

          final f = File(join(d0.path, 'pubspec.yaml'));
          await f.writeAsString('no-name: pack0\n');

          late String exception;
          try {
            await graph.get(directory: d, ggLog: ggLog);
          } catch (e) {
            exception = e.toString();
          }
          expect(exception, contains('Error parsing pubspec.yaml'));
        });
      });
    });
  });

  // ###########################################################################
  group('getNodesBetween', () {
    late Graph localGraph;

    setUp(() async {
      localGraph = Graph(ggLog: (_) {});
    });

    // Helper to collect all nodes reachable via dependencies from roots
    Map<String, Node> collectAllNodes(Map<String, Node> roots) {
      final map = <String, Node>{};
      void dfs(Node n) {
        if (map.containsKey(n.name)) return;
        map[n.name] = n;
        for (final dep in n.dependencies.values) {
          dfs(dep);
        }
      }

      for (final r in roots.values) {
        dfs(r);
      }

      return map;
    }

    test('hierarchy downward (dependencies only)', () async {
      final roots = await localGraph.get(directory: d, ggLog: (_) {});
      final all = collectAllNodes(roots);

      final pack0 = all['pack0']!;
      final pack011 = all['pack011']!;

      final between = localGraph.getNodesBetween(all, [pack0, pack011]);
      final names = between.map((e) => e.name).toList();
      expect(names, ['pack01']);
    });

    test('hierarchy upward (dependents only)', () async {
      final roots = await localGraph.get(directory: d, ggLog: (_) {});
      final all = collectAllNodes(roots);

      final pack0 = all['pack0']!;
      final pack011 = all['pack011']!;

      final between = localGraph.getNodesBetween(all, [pack011, pack0]);
      final names = between.map((e) => e.name).toList();
      expect(names, ['pack01']);
    });

    test('direct neighbors produce empty result', () async {
      final roots = await localGraph.get(directory: d, ggLog: (_) {});
      final all = collectAllNodes(roots);

      final pack03 = all['pack03']!;
      final pack031 = all['pack031']!;

      final between = localGraph.getNodesBetween(all, [pack03, pack031]);
      expect(between, isEmpty);
    });

    test('siblings or mixed-direction-only unreachable pairs yield empty',
        () async {
      final roots = await localGraph.get(directory: d, ggLog: (_) {});
      final all = collectAllNodes(roots);

      final pack011 = all['pack011']!;
      final pack012 = all['pack012']!;
      final pack031 = all['pack031']!;

      expect(localGraph.getNodesBetween(all, [pack011, pack012]), isEmpty);
      expect(localGraph.getNodesBetween(all, [pack011, pack031]), isEmpty);
    });

    test('multiple endpoints union of inner nodes', () async {
      final roots = await localGraph.get(directory: d, ggLog: (_) {});
      final all = collectAllNodes(roots);

      final pack0 = all['pack0']!;
      final pack011 = all['pack011']!;
      final pack031 = all['pack031']!;

      final between = localGraph.getNodesBetween(
        all,
        [pack0, pack011, pack031],
      );
      final names = between.map((e) => e.name).toList();
      expect(names, ['pack01', 'pack03']);
    });

    test('diamond graph: longer and shorter paths union', () {
      // Create synthetic nodes A, B, C, D
      final tmp = Directory.systemTemp;
      final A = Node(
        name: 'A',
        directory: tmp,
        pubspec: Pubspec('A', version: Version(1, 0, 0)),
      );
      final B = Node(
        name: 'B',
        directory: tmp,
        pubspec: Pubspec('B', version: Version(1, 0, 0)),
      );
      final C = Node(
        name: 'C',
        directory: tmp,
        pubspec: Pubspec('C', version: Version(1, 0, 0)),
      );
      final D = Node(
        name: 'D',
        directory: tmp,
        pubspec: Pubspec('D', version: Version(1, 0, 0)),
      );

      // A -> B -> D, A -> C -> D
      A.dependencies['B'] = B;
      B.dependents['A'] = A;

      A.dependencies['C'] = C;
      C.dependents['A'] = A;

      B.dependencies['D'] = D;
      D.dependents['B'] = B;

      C.dependencies['D'] = D;
      D.dependents['C'] = C;

      final all = {
        for (final n in [A, B, C, D]) n.name: n
      };

      final between = localGraph.getNodesBetween(all, [A, D]);
      final names = between.map((e) => e.name).toList();
      expect(names, ['B', 'C']);
    });

    test('diamond graph: siblings B and C have no single-direction path', () {
      final tmp = Directory.systemTemp;
      final A = Node(
        name: 'A',
        directory: tmp,
        pubspec: Pubspec('A', version: Version(1, 0, 0)),
      );
      final B = Node(
        name: 'B',
        directory: tmp,
        pubspec: Pubspec('B', version: Version(1, 0, 0)),
      );
      final C = Node(
        name: 'C',
        directory: tmp,
        pubspec: Pubspec('C', version: Version(1, 0, 0)),
      );
      final D = Node(
        name: 'D',
        directory: tmp,
        pubspec: Pubspec('D', version: Version(1, 0, 0)),
      );

      // A -> B -> D, A -> C -> D
      A.dependencies['B'] = B;
      B.dependents['A'] = A;

      A.dependencies['C'] = C;
      C.dependents['A'] = A;

      B.dependencies['D'] = D;
      D.dependents['B'] = B;

      C.dependencies['D'] = D;
      D.dependents['C'] = C;

      final all = {
        for (final n in [A, B, C, D]) n.name: n
      };

      final between = localGraph.getNodesBetween(all, [B, C]);
      expect(between, isEmpty);
    });

    test('disjoint roots return empty', () {
      final tmp = Directory.systemTemp;
      final x1 = Node(
        name: 'X1',
        directory: tmp,
        pubspec: Pubspec('X1', version: Version(1, 0, 0)),
      );
      final x2 = Node(
        name: 'X2',
        directory: tmp,
        pubspec: Pubspec('X2', version: Version(1, 0, 0)),
      );
      final y1 = Node(
        name: 'Y1',
        directory: tmp,
        pubspec: Pubspec('Y1', version: Version(1, 0, 0)),
      );
      final y2 = Node(
        name: 'Y2',
        directory: tmp,
        pubspec: Pubspec('Y2', version: Version(1, 0, 0)),
      );

      // X1 -> X2, Y1 -> Y2
      x1.dependencies['X2'] = x2;
      x2.dependents['X1'] = x1;

      y1.dependencies['Y2'] = y2;
      y2.dependents['Y1'] = y1;

      final all = {
        for (final n in [x1, x2, y1, y2]) n.name: n
      };

      final between = localGraph.getNodesBetween(all, [x1, y2]);
      expect(between, isEmpty);
    });

    test('duplicate endpoints are ignored', () {
      final tmp = Directory.systemTemp;
      final A = Node(
        name: 'A',
        directory: tmp,
        pubspec: Pubspec('A', version: Version(1, 0, 0)),
      );
      final B = Node(
        name: 'B',
        directory: tmp,
        pubspec: Pubspec('B', version: Version(1, 0, 0)),
      );
      final C = Node(
        name: 'C',
        directory: tmp,
        pubspec: Pubspec('C', version: Version(1, 0, 0)),
      );
      final D = Node(
        name: 'D',
        directory: tmp,
        pubspec: Pubspec('D', version: Version(1, 0, 0)),
      );

      // A -> B -> D, A -> C -> D
      A.dependencies['B'] = B;
      B.dependents['A'] = A;

      A.dependencies['C'] = C;
      C.dependents['A'] = A;

      B.dependencies['D'] = D;
      D.dependents['B'] = B;

      C.dependencies['D'] = D;
      D.dependents['C'] = C;

      final all = {
        for (final n in [A, B, C, D]) n.name: n
      };

      final between = localGraph.getNodesBetween(all, [A, D, D, A]);
      final names = between.map((e) => e.name).toList();
      expect(names, ['B', 'C']);
    });
  });
}
