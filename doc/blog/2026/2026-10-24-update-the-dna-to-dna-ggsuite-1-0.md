<!--
@license
Copyright (c) ggsuite

Use of this source code is governed by terms that can be
found in the LICENSE file in the root of this package.
-->

# Update the DNA to dna_ggsuite 1.0

## Motivation

- gg_local_package_dependencies reads the packages of a local folder and
  builds their dependency graph
- Its guides, skills, Claude hooks and the managed block of `CLAUDE.md`
  are not written by hand: the DNA generates them from `dna_ggsuite`
- With `dna_ggsuite` 0.4.0, an AI working here followed an older workflow:
  no review step, no rules for repos of a ticket that depend on each other
- The change is small: no code, test or API changes, only the generated
  files and three dependency constraints

## Strategy

- Raise `dna_ggsuite` to ^1.0.0 and `helix` to ^1.13.0
- Raise `pubspec_parse` to ^1.7.0, the release now in use
- Rebuild the DNA and commit the generated files as they come
- Leave `lib/` and `test/` untouched

## Implementation 1: A review step in the workflow

- The new skill `/gg-review` checks the diff against the scope of the repo,
  writes the blog post, updates README.md and `index.jsonc`, then opens the
  pull requests and runs `/review-light`
- `/gg`, `CLAUDE.md` and the develop guide list it between `/gg-push` and
  `/gg-publish`; `/gg-publish` sends back to it when a post is missing
- The AI dev guide moves blog post, README.md and `index.jsonc` from the
  publish to the review, so they are reviewed together with the code

## Implementation 2: Rules for repos that depend on each other

- Describe every repo in its own terms: messages, blog posts and code
  comments of a dependency never name the repos that use it
- `/gg-commit` proposes one message per repo and commits each repo on its
  own when repos of the ticket depend on each other
- Keep every repo in its scope: when code does not fit, propose a split, a
  new repo, another repo or a move, and let the user decide when
- Keep `index.jsonc` current: `summary`, `domain` and `interfaces` follow
  the code; a repo without one gets it with its first change

## Implementation 3: Docs and tooling

- Blog posts go to `doc/blog/<yyyy>`, describe this repo only and have a
  "Dependency updates" section
- README guide and template are rewritten: motivation, usage, limitations,
  license, English and German; `scripts/check-readme.js` checks the result
- The code guides no longer ask for the package prefix in type names
- Hooks in `.claude/settings.json` keep the prompts in the project
  management repo; `pm-prompts.json` names none, so they stay idle here

## Dependency updates

- `dna_ggsuite` 1.0.0 pulls in `dna_gg` 1.0.0, `dna_blog` 0.3.0 and
  `dna_translate` 0.3.0, the sources of the files above
- `helix` 1.13.0 joins the `CLAUDE.md` parts of all DNA layers instead of
  letting the last layer win
- `pubspec_parse` 1.7.0, which reads every local `pubspec.yaml` here,
  also understands the `tag_pattern` key of git dependencies (Dart 3.9)

## Result

- The checks for commit and push pass on Windows; `.gg/gg.json` records
  them

## Open Points

- The repo has no `index.jsonc` yet, which the new guide asks of every
  repo of a ticket
- README.md does not follow the new README guide: `check-readme.js` misses
  Motivation, Installation, Usage, License and `README.de.md`
