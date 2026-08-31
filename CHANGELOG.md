# Changelog

## Unreleased

### Fixed

- Fix Windows-specific test failures that blocked the review

## 4.1.1 - 2026-08-26

### Changed

- Use ggwsm in pipelines
- Resolve dependency cycles that close over a dev dependency

## 4.1.0 - 2026-08-13

### Changed

- Rework copyright headers

### Fixed

- Cleanup copy right headers. Update to dart 3.13. Auto fixes.
- Cleanup copy right headers. Update to dart 3.13. Auto fixes. Setup quick-check pipeline.

## 4.0.0 - 2026-08-13

## 3.0.1 - 2026-08-11

### Changed

- Provide gg via npm
- Fix shell changes

## 3.0.0 - 2026-08-08

### Changed

- \#gg: changed references to pub.dev
- Allow to pass custom options to exec of dir commands.

## 2.1.0 - 2026-08-01

### Added

- `Graph.get`, `ProcessingList.get` and `SortedProcessingList.get` accept an
optional `packageDirs` list to graph an explicit set of package folders
instead of the ones discovered below the input directory. This makes it
possible to build one graph across several roots.

## 2.0.0 - 2026-07-31

### Changed

- Gg Multi: changed references to pub.dev

## 1.4.0 - 2026-06-19

### Changed

- Build dependency graph across Dart and TypeScript bridge repos

### Fixed

- Fix non-destructive sorted processing order (no longer mutates live Node.dependencies); make do/publish dependency refresh treat bridges as TypeScript via checkProjectType, symmetric with do/review and do/cancel_review
- Review fixes: keep full npm-scoped names in the dependency graph so different scopes stay distinct (no false duplicate-drop / misrouted edges); surface bridges in gg ls (dart+nodejs label, list package.json deps as typescript)

## 1.3.0 - 2026-04-23

### Changed

- kidney: changed references to path
- kidney: changed references to git
- kidney: changed references to local

## 1.2.1 - 2026-04-18

### Changed

- commit

## 1.2.0 - 2026-03-17

### Added

- Add test for getNodesBetween
- Add typescript support
- Add test for default logger behavior in Graph constructor

### Changed

- prepare for publishing 1.1.3

### Removed

- Remove unused import and outdated tests from dependencies test

## 1.1.3 - 2025-08-08

### Added

- Add sorted processing list

## 1.1.2 - 2024-08-30

### Changed

- Execute tests after changes on windows

## 1.1.1 - 2024-04-13

### Removed

- dependency to gg_install_gg, remove ./check script
- dependency pana

## 1.1.0 - 2024-04-12

### Added

- support dev dependencies

## 1.0.4 - 2024-04-11

### Fixed

- detect and complain about circular dependencies

## 1.0.3 - 2024-04-10

### Added

- additional test cases

## 1.0.2 - 2024-04-10

### Added

- Mocks for Graph and ProcessingList

## 1.0.1 - 2024-04-10

### Added

- ProcessingList to get an order of nodes to be processed

## 1.0.0 - 2024-04-10

### Add

- Initial boilerplate

### Added

- initial
