# Proposal

## Why

The Renovate copier update of the infra template fails in this repository with merge conflicts, so `renovate/artifacts` fails and no update merges (#114). Two owners write one template file: Renovate moves the infra pin of the workflow callers, and the repository changed template files by hand. dan-petty/infra#225 gives each template file one owner, in the infra release v0.25.3.

## What Changes

- Run `copier recopy --skip-answered --defaults --overwrite --vcs-ref v0.25.3` with the answers `scopes`, `scope_descriptions` and `required_checks` of this repository. `.copier-answers.yml` names `_commit: v0.25.3`.
- The template writes `.github/labels.yml`, `.github/CODEOWNERS`, `github/repository.yaml`, `.github/workflows/pr-title.yml`, `.github/workflows/release.yml` and `release-please-config.json` from the answers.
- `.github/workflows/pr-title.yml` and `.github/workflows/release.yml` become the standard callers of the reusable workflows of infra, which hold the same steps. The title check reports as `PR title / Semantic PR title`.
- `release-please-config.json` gets `initial-version: 0.1.0` of the template. It has no effect: `.release-please-manifest.json` holds 1.4.0.
- Copier keeps `.github/renovate.json`, `.pre-commit-config.yaml`, `.devops/project.toml`, `version.txt` and `.release-please-manifest.json` of the repository (`_skip_if_exists`).
- The change alters no behavior that a consumer observes: it changes label data, repository settings and CI workflow callers. It sets `skip_specs: true`.
- The change fits one pull request.

## Feasibility

- `copier recopy` of Copier 9.19.1 at the tag v0.25.3 changes only the files above. A run with the same answers against the branch of dan-petty/infra#225 gave the same diff.
- The reusable workflows of infra at v0.25.3 hold the steps of the two workflows that the callers replace: `.github/workflows/pr-title.yml` runs amannn/action-semantic-pull-request with `validateSingleCommit: true` and `subjectPattern: ^.{1,60}$`, and `.github/workflows/release.yml` checks the credentials of the release App, mints its token in the environment `release`, runs release-please and turns on auto-merge of the release pull request.
- The ruleset `main` of this repository requires no title check (`GET /repos/dan-petty/devtools/rulesets/27755504`, 2026-11-27). The caller reports the title check as `PR title / Semantic PR title`, the name in `github/repository.yaml`.

## Existing Tool Considered

Copier (MIT, maintained) renders and updates the template, and its `_skip_if_exists` keeps the files of the repository. Renovate (AGPL-3.0, maintained) proposes the next copier update. The change deletes the steps of `.github/workflows/pr-title.yml` and `.github/workflows/release.yml`: the reusable workflows of infra run them.
