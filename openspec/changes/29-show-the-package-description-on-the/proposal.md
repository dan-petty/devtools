# Proposal

## Why

The package page of ghcr.io/dan-petty/devtools shows no description after the publish of 20261120.41, although the manifest list carries `org.opencontainers.image.description`. The page marks the referrers index of the attestation as the newest package version, and that index carries no annotation. #29 asks where GHCR reads the description of a multi-arch package that has an attestation in the registry, that the page show it, and that the attestation stay in the registry.

## What Changes

- Record in `README.md` where GHCR reads the description of a multi-arch package that has an in-registry attestation, with the GitHub documentation of the Container registry as the source.
- Add a step to the publish job of `.github/workflows/image.yml` that copies the attestation referrers tag with `docker buildx imagetools create --tag` and the `--annotation` values of `steps.meta.outputs.annotations`, so the newer package version carries the description.
- Fail that step when the copy drops a manifest digest of the referrers index or gives it another `org.opencontainers.image.description` than the manifest list.
- Keep the manifest list, its digest, the tags X.Y, X and `latest`, and the build provenance attestation unchanged.
- Document the new publish step and the check of the package page after a publish on `main` in `README.md`.
- Carry no spec delta: every changed path is a workflow and a document, which changes no behavior a consumer observes, and `uv run devops ci --check --only actionlint,zizmor` proves the workflow.
- The change fits one pull request.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None.

## Impact

- Code: `.github/workflows/image.yml`
- Documents: `README.md`

## Feasibility

- Tool calls of this run: `read_file .github/workflows/image.yml` lines 430-553 showed the publish job with its metadata step, its manifest list step, its attest step and its tag step; `search_code referrers` answered `No match.`, so no step of the repository names or annotates the referrers tag yet.
- `read_issue 19` showed the closed issue that added the annotations to the manifest list, closed by the merged pull request #27, and `read_issue 22` showed the closed issue that moved the attestation to `actions/attest`; `find_issues GHCR description referrers attestation` listed only `#29 open fix(ci): show the package description on the GHCR page`, so no other open item changes the publish job.
- `read_file README.md` lines 28-48 and 140-175 showed the attestation check and the list of publish steps; `read_file .devops/project.toml` and `read_file openspec/config.yaml` showed that this repository plans each item as an OpenSpec change and that a change of a workflow carries no spec delta.
- The probes answered, word for word: The path `.github/workflows/image.yml` is a file of the staging commit. The path `README.md` is a file of the staging commit. The path `org.opencontainers.image.description` is no file of the staging commit. No commit in the history deleted or renamed it. The path `steps.meta.outputs.annotations` is no file of the staging commit. No commit in the history deleted or renamed it. Not probed, the bound of 10 commands is reached: `latest`, `main`, `test`, `partly`, `annotations`
- The premise holds at the staged commit: the publish job gives the manifest list the annotations of metadata-action at .github/workflows/image.yml:511: `ANNOTATIONS: ${{ steps.meta.outputs.annotations }}` and then pushes the build provenance attestation to GHCR with .github/workflows/image.yml:523: `uses: actions/attest@1e69f48acb82d1966a394da916b4c1698aa569d6` and .github/workflows/image.yml:527: `push-to-registry: true`, and no step annotates the referrers tag that the attestation pushes.
- The issue records the cause as unproven, word for word: `A possible cause: GHCR takes the description from the newest version. This is not proven.` The plan therefore claims nowhere that the page shows the description: group 1 records where GHCR reads it, group 2 gives the description to both package versions, and the page check of group 3 is the only proof of the display.
- `research_lookup` for where GHCR reads the description answered `The page fetch failed: ConfigurationError.`, so that answer is not checked in this run: group 1 reads the GitHub documentation page `Working with the Container registry` and records what it says, and the two raw-index commands of its process check it against the real package.
- A copy of an index with one source and no annotation keeps its digest, as the staged comment records at .github/workflows/image.yml:529: `A copy of a manifest list with one source and no annotation keeps the digest.`, and the tag step checks the digest after its copy at .github/workflows/image.yml:539: `docker buildx imagetools create --metadata-file "$RUNNER_TEMP/tags.json" "${tags[@]}" "$IMAGE@$DIGEST"`, so the copy of the referrers index keeps each attestation manifest and the new step compares the manifest digests before and after.
- The staged constants that the plan relies on: `actions/attest` at `1e69f48acb82d1966a394da916b4c1698aa569d6` (.github/workflows/image.yml:523: `uses: actions/attest@1e69f48acb82d1966a394da916b4c1698aa569d6`), `docker/metadata-action` at `dc802804100637a589fabce1cb79ff13a1411302` (.github/workflows/image.yml:493: `uses: docker/metadata-action@dc802804100637a589fabce1cb79ff13a1411302`) and the annotation level at .github/workflows/image.yml:492: `DOCKER_METADATA_ANNOTATIONS_LEVELS: index`.
- No function of the repository is called. The step of group 2 calls `docker buildx imagetools inspect --raw` and `docker buildx imagetools create --tag`, with the preconditions of a client of the registry and a network to ghcr.io; the manual checks call `gh attestation verify` (README.md:39: `gh attestation verify oci://ghcr.io/dan-petty/devtools:latest --owner dan-petty`), with the preconditions of a client of GitHub and a network, and open the package page, with the precondition of a network.
- Runner capability of the group verify: `uv run devops ci --check --only actionlint,zizmor` runs `actionlint` and `zizmor`, both in the runner image, with failure class `lint`, no network and no pod capability; `docker` is NOT_IN_RUNNER, so the new step runs only in the publish job on a GitHub-hosted runner and no group runs it.
- First checks against the real system after the merge: the next publish on `main` runs the new step, which fails unless the referrers index lists the same manifest digests and the same description as the manifest list; then `gh attestation verify oci://ghcr.io/dan-petty/devtools:latest --owner dan-petty` must exit 0; then the package page must show the description.
- The change carries no spec delta, because every path it changes is a workflow and a document and no consumer-observed behavior changes; the repository records the rule that group 1 checks against the GitHub documentation at README.md:163: `GHCR shows the description of a multi-arch image from these annotations.`
- The two change items of the issue map to the groups: the first item, which finds where GHCR reads the description and makes the page show it while the attestation stays in the registry, is delivered by the process of group 1 and the step of group 2; the second item, the page check after a publish on `main`, is delivered by the process of group 3. The issue body holds no list of acceptance criteria that a person wrote outside the refine block, so `criteria` is empty.

## Existing Tool Considered

docker/buildx, Apache-2.0 and maintained (last activity 2026-11-23), copies an OCI index to a tag with `--annotation` and already runs in the publish job; the change builds no code of its own and adds no dependency. The GitHub documentation of the Container registry is the source of the answer for where GHCR reads the description.

## Dependencies

None.
