// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_local_package_dependencies/gg_local_package_dependencies.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('PackageManifest', () {
    group('DartPackageLanguage', () {
      test('detects Dart package directories via pubspec.yaml', () async {
        final tempDir = await Directory.systemTemp.createTemp('dart_pkg_test_');
        try {
          final pkgDir = Directory(p.join(tempDir.path, 'pkg'));
          await pkgDir.create(recursive: true);

          final pubspecFile = File(p.join(pkgDir.path, 'pubspec.yaml'));
          await pubspecFile.writeAsString(
            // Minimal, valid pubspec with dependencies and
            // dev_dependencies.
            '''
name: my_pkg
version: 1.0.0

dependencies:
  dep1: ^1.0.0

dev_dependencies:
  dev_dep1: ^1.0.0
''',
          );

          final language = DartPackageLanguage();

          // isPackageDirectory should detect the pubspec.yaml file.
          expect(language.isPackageDirectory(pkgDir), isTrue);

          final manifest =
              await language.loadManifest(pkgDir) as DartPackageManifest;

          expect(manifest.name, 'my_pkg');
          expect(manifest.dependencies, contains('dep1'));
          expect(manifest.devDependencies, contains('dev_dep1'));
        } finally {
          // Clean up temporary directory.
          await tempDir.delete(recursive: true);
        }
      });

      test('exposes id and description', () {
        final language = DartPackageLanguage();

        expect(language.id, 'dart');
        expect(
          language.description,
          'Dart packages using pubspec.yaml manifests.',
        );
      });

      test(
        'isPackageDirectory returns false when pubspec.yaml is missing',
        () async {
          final tempDir = await Directory.systemTemp.createTemp(
            'dart_pkg_test_',
          );
          try {
            final pkgDir = Directory(p.join(tempDir.path, 'pkg'));
            await pkgDir.create(recursive: true);

            final language = DartPackageLanguage();

            expect(language.isPackageDirectory(pkgDir), isFalse);
          } finally {
            await tempDir.delete(recursive: true);
          }
        },
      );

      test('loadManifest throws for invalid pubspec.yaml', () async {
        final tempDir = await Directory.systemTemp.createTemp('dart_pkg_test_');
        try {
          final pkgDir = Directory(p.join(tempDir.path, 'pkg'));
          await pkgDir.create(recursive: true);

          final pubspecFile = File(p.join(pkgDir.path, 'pubspec.yaml'));
          // Missing required fields such as name; parse should fail.
          await pubspecFile.writeAsString('no-name: value\n');

          final language = DartPackageLanguage();

          late String message;
          try {
            await language.loadManifest(pkgDir);
          } catch (e) {
            message = e.toString();
          }

          expect(message, contains('Error parsing pubspec.yaml'));
        } finally {
          await tempDir.delete(recursive: true);
        }
      });
    });

    group('TypeScriptPackageLanguage', () {
      test('detects TS/JS package directories via package.json', () async {
        final tempDir = await Directory.systemTemp.createTemp(
          'ts_pkg_language_test_',
        );
        try {
          final pkgDir = Directory(p.join(tempDir.path, 'pkg'));
          await pkgDir.create(recursive: true);

          final packageJsonFile = File(p.join(pkgDir.path, 'package.json'));
          await packageJsonFile.writeAsString(
            // Minimal, valid package.json with dependencies and
            // devDependencies
            '''
{
  "name": "my_ts_pkg",
  "version": "1.0.0",
  "dependencies": {
    "dep1": "^1.0.0"
  },
  "devDependencies": {
    "dev_dep1": "^1.0.0"
  }
}
''',
          );

          final language = TypeScriptPackageLanguage();

          // isPackageDirectory should detect the package.json file.
          expect(language.isPackageDirectory(pkgDir), isTrue);

          final manifest =
              await language.loadManifest(pkgDir) as TypeScriptPackageManifest;

          expect(manifest.name, 'my_ts_pkg');
          expect(manifest.dependencies, contains('dep1'));
          expect(manifest.devDependencies, contains('dev_dep1'));
        } finally {
          await tempDir.delete(recursive: true);
        }
      });

      test('exposes id and description', () {
        final language = TypeScriptPackageLanguage();

        expect(language.id, 'typescript');
        expect(
          language.description,
          'TypeScript / JavaScript packages using package.json '
          'manifests.',
        );
      });

      test(
        'isPackageDirectory returns false when package.json is missing',
        () async {
          final tempDir = await Directory.systemTemp.createTemp(
            'ts_pkg_language_test_',
          );
          try {
            final pkgDir = Directory(p.join(tempDir.path, 'pkg'));
            await pkgDir.create(recursive: true);

            final language = TypeScriptPackageLanguage();

            expect(language.isPackageDirectory(pkgDir), isFalse);
          } finally {
            await tempDir.delete(recursive: true);
          }
        },
      );

      test('loadManifest throws for invalid JSON in package.json', () async {
        final tempDir = await Directory.systemTemp.createTemp(
          'ts_pkg_language_test_',
        );
        try {
          final pkgDir = Directory(p.join(tempDir.path, 'pkg'));
          await pkgDir.create(recursive: true);

          final packageJsonFile = File(p.join(pkgDir.path, 'package.json'));
          // Intentionally invalid JSON.
          await packageJsonFile.writeAsString('{ invalid json');

          final language = TypeScriptPackageLanguage();

          late String message;
          try {
            await language.loadManifest(pkgDir);
          } catch (e) {
            message = e.toString();
          }

          expect(message, contains('Error parsing package.json'));
        } finally {
          await tempDir.delete(recursive: true);
        }
      });

      test(
        'loadManifest throws when JSON top level is not an object',
        () async {
          final tempDir = await Directory.systemTemp.createTemp(
            'ts_pkg_language_test_',
          );
          try {
            final pkgDir = Directory(p.join(tempDir.path, 'pkg'));
            await pkgDir.create(recursive: true);

            final packageJsonFile = File(p.join(pkgDir.path, 'package.json'));
            // Top-level JSON is an array instead of an object.
            await packageJsonFile.writeAsString('["not", "an", "object"]');

            final language = TypeScriptPackageLanguage();

            late String message;
            try {
              await language.loadManifest(pkgDir);
            } catch (e) {
              message = e.toString();
            }

            expect(message, contains('Error parsing package.json'));
            expect(message, contains('Expected JSON object at top level.'));
          } finally {
            await tempDir.delete(recursive: true);
          }
        },
      );

      test(
        'loadManifest throws when name field is missing or invalid',
        () async {
          final tempDir = await Directory.systemTemp.createTemp(
            'ts_pkg_language_test_',
          );
          try {
            final pkgDir = Directory(p.join(tempDir.path, 'pkg'));
            await pkgDir.create(recursive: true);

            final packageJsonFile = File(p.join(pkgDir.path, 'package.json'));
            // Missing the required "name" field.
            await packageJsonFile.writeAsString('''
{
  "version": "1.0.0"
}
''');

            final language = TypeScriptPackageLanguage();

            late String message;
            try {
              await language.loadManifest(pkgDir);
            } catch (e) {
              message = e.toString();
            }

            expect(message, contains('Error parsing package.json'));
            expect(message, contains('Missing or invalid "name" field.'));
          } finally {
            await tempDir.delete(recursive: true);
          }
        },
      );
    });
  });
}
