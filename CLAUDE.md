# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Dart CLI + library that scans a folder containing sibling packages, builds a local dependency graph between them, and exposes it either as a tree or as a flat processing order. Supports Dart (`pubspec.yaml`) and TypeScript/JavaScript (`package.json`) packages side-by-side.

## Commands

Dart SDK `>=3.8.1 <4.0.0`.

- Install deps: `dart pub get`
- Analyze: `dart analyze`
- Format: `dart format .`
- Run all tests: `dart test`
- Run one test file: `dart test test/commands/graph_test.dart`
- Run a single test by name: `dart test -N "<substring of test name>"`
- Coverage: `dart test --coverage=coverage`
- Run the CLI locally: `dart run bin/gg_local_package_dependencies.dart <subcommand> -i <dir>`
  - Subcommands: `graph`, `processingList`, `sortedProcessingList`

`check.yaml` declares which gates run under the repo's `gg` tooling (`analyze`, `format`, `tests` enabled; `pana` disabled).

## Architecture

Entry point `bin/gg_local_package_dependencies.dart` wires `GgCommandRunner` (from `gg_args`) to the root `GgLocalPackageDependencies` command, which registers three subcommands: `Graph`, `ProcessingList`, `SortedProcessingList`. Each extends `DirCommand<T>` from `gg_args`, so every subcommand takes `-i <input-directory>` and is invoked via `exec({directory, ggLog})`.

Graph construction (`lib/src/commands/graph.dart`) is the core:

1. Enumerate immediate subdirectories of the input folder.
2. For each dir, ask every registered `PackageLanguage` whether it owns the dir (`isPackageDirectory`); first match wins. This is the extension point for new languages.
3. Load a `PackageManifest` (name + local deps + dev deps). Duplicate package names are reported and skipped.
4. Cross-link nodes: for each declared dep/dev-dep, if the name matches another discovered node, wire it into both `Node.dependencies` and the counterpart's `Node.dependents`.
5. Return the map of **root** nodes (nodes with no dependents). `_printNode` recursively prints the tree; circular dependencies are detected and raised as errors.

`ProcessingList` and `SortedProcessingList` consume the same graph to produce flat build orders (dependencies before dependents).

The language abstraction lives in `lib/src/tools/package_manifest.dart`:

- `PackageLanguage` — detects + loads a manifest for a directory.
- `PackageManifest` — language-agnostic view exposing `name`, `dependencies`, `devDependencies`.
- Concrete implementations: `DartPackageLanguage` / `DartPackageManifest` (uses `pubspec_parse`), `TypeScriptPackageLanguage` / `TypeScriptPackageManifest` (decodes `package.json`).

To add a new language: implement both interfaces and register it by passing a `languages:` list to `Graph()` (the default list in the constructor defines priority order).

The public library surface is `lib/gg_local_package_dependencies.dart`, which re-exports the root command, the three subcommands, `Node`, and `PackageManifest`. Consumers use it programmatically in addition to the CLI.

## Tests

Fixture-based. `test/sample_folder/` (Dart) and `test/sample_folder_ts/` (TypeScript) each contain `plain/`, `hierarchical/`, `dev/`, `duplicates/`, and `circular/` subtrees that graph/processing tests run against. When touching graph logic, add or adjust a fixture under the relevant scenario folder rather than inventing ad-hoc test dirs.
