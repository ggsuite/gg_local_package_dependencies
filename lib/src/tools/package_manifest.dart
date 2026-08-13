// @license
// Copyright (c) ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:convert';
import 'dart:io';

import 'package:gg_console_colors/gg_console_colors.dart';
import 'package:pubspec_parse/pubspec_parse.dart';

/// Language-agnostic description of a package manifest.
abstract class PackageManifest {
  /// Name of the package.
  String get name;

  /// Names of local dependencies.
  Iterable<String> get dependencies;

  /// Names of local dev dependencies.
  Iterable<String> get devDependencies;

  /// The repository the package declares for itself, or null when it names
  /// none.
  ///
  /// It is what tells a checkout that sits in the folder its repository is
  /// named after from one that is a leftover of a rename: the platform keeps
  /// redirecting the old name, so cloning it succeeds and leaves a second
  /// folder holding the very same package.
  String? get repositoryUrl;
}

/// Describes how to detect and load package manifests for a given language.
abstract class PackageLanguage {
  /// Short identifier of the language, e.g. `dart` or `typescript`.
  String get id;

  /// Human readable description.
  String get description;

  /// Returns true if [dir] looks like a package of this language.
  bool isPackageDirectory(Directory dir);

  /// Loads and parses the manifest of a package in [dir].
  Future<PackageManifest> loadManifest(Directory dir);
}

/// Manifest wrapper for Dart `pubspec.yaml` based packages.
class DartPackageManifest implements PackageManifest {
  /// Creates a manifest from the parsed [pubspec].
  DartPackageManifest({required this.pubspec});

  /// The underlying parsed `Pubspec`.
  final Pubspec pubspec;

  @override
  String get name => pubspec.name;

  @override
  Iterable<String> get dependencies => pubspec.dependencies.keys;

  @override
  Iterable<String> get devDependencies => pubspec.devDependencies.keys;

  @override
  String? get repositoryUrl =>
      pubspec.repository?.toString() ?? pubspec.homepage;
}

/// Package language implementation for Dart.
class DartPackageLanguage implements PackageLanguage {
  @override
  String get id => 'dart';

  @override
  String get description => 'Dart packages using pubspec.yaml manifests.';

  @override
  bool isPackageDirectory(Directory dir) {
    final pubspecFile = File('${dir.path}/pubspec.yaml');
    return pubspecFile.existsSync();
  }

  @override
  Future<PackageManifest> loadManifest(Directory dir) async {
    final pubspecFile = File('${dir.path}/pubspec.yaml');
    final content = await pubspecFile.readAsString();

    try {
      final pubspec = Pubspec.parse(content);
      return DartPackageManifest(pubspec: pubspec);
    } catch (e) {
      throw Exception(red('Error parsing pubspec.yaml:') + e.toString());
    }
  }
}

/// Manifest wrapper for TypeScript / JavaScript `package.json` based packages.
class TypeScriptPackageManifest implements PackageManifest {
  /// Creates a manifest from the decoded JSON [rawJson].
  TypeScriptPackageManifest({
    required this.name,
    required this.dependencies,
    required this.devDependencies,
    required this.rawJson,
  });

  @override
  final String name;

  @override
  final Iterable<String> dependencies;

  @override
  final Iterable<String> devDependencies;

  /// Raw decoded `package.json` contents.
  final Map<String, dynamic> rawJson;

  /// npm writes `repository` either as a plain string or as an object
  /// carrying the url — both forms are read here, `homepage` serves as
  /// fallback.
  @override
  String? get repositoryUrl {
    final dynamic repository = rawJson['repository'];
    if (repository is String && repository.isNotEmpty) {
      return repository;
    }
    if (repository is Map<String, dynamic>) {
      final dynamic url = repository['url'];
      if (url is String && url.isNotEmpty) {
        return url;
      }
    }
    final dynamic homepage = rawJson['homepage'];
    return homepage is String && homepage.isNotEmpty ? homepage : null;
  }
}

/// Package language implementation for TypeScript / JavaScript.
class TypeScriptPackageLanguage implements PackageLanguage {
  @override
  String get id => 'typescript';

  @override
  String get description =>
      'TypeScript / JavaScript packages using package.json manifests.';

  @override
  bool isPackageDirectory(Directory dir) {
    final packageJsonFile = File('${dir.path}/package.json');
    return packageJsonFile.existsSync();
  }

  @override
  Future<PackageManifest> loadManifest(Directory dir) async {
    final packageJsonFile = File('${dir.path}/package.json');

    try {
      final content = await packageJsonFile.readAsString();
      final dynamic decoded = jsonDecode(content);

      if (decoded is! Map<String, dynamic>) {
        throw Exception('Expected JSON object at top level.');
      }

      final map = decoded;

      final nameValue = map['name'];
      if (nameValue is! String || nameValue.isEmpty) {
        throw Exception('Missing or invalid "name" field.');
      }

      // Keep the full, possibly npm-scoped names (e.g. `@scope/pkg`). Scoped
      // names are distinct identities — collapsing `@a/pkg` and `@b/pkg` to a
      // bare `pkg` would merge unrelated packages and misroute dependency
      // edges. Cross-language matching against a bare name still works via the
      // directory-name alias added in the graph builder.
      Iterable<String> extractDependencies(String key) {
        final dynamic section = map[key];
        if (section is Map<String, dynamic>) {
          return section.keys;
        }
        return const <String>[];
      }

      final dependencies = extractDependencies('dependencies');
      final devDependencies = extractDependencies('devDependencies');

      return TypeScriptPackageManifest(
        name: nameValue,
        dependencies: dependencies,
        devDependencies: devDependencies,
        rawJson: map,
      );
    } catch (e) {
      throw Exception(red('Error parsing package.json:') + e.toString());
    }
  }
}
