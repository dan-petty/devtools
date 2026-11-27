# Proposal

## Why

The package page of ghcr.io/dan-petty/devtools shows no description after the publish of 20261120.41, although the manifest list carries `org.opencontainers.image.description`. The page marks the referrers index of the attestation as the newest package version, and that index carries no annotation. #29 asks where GHCR reads the description of a multi-arch package that has an attestation in the registry, that the page show it, and that the attestation stay in the registry.

## What Changes

- Add a step to the publish job of `.github/workflows/image.yml`, after the tags move, that copies the attestation referrers tag with `docker buildx imagetools create --tag` and the `--annotation` values of `steps.meta.outputs.annotations`, so the newest package version carries the description.
- Fail that step when the copy changes any field of a descriptor in the `manifests` array of the referrers index, or gives it another `org.opencontainers.image.description` than the manifest list.
- Record in `README.md` that the package page shows the newest package version as Latest, that the attestation pushes the referrers index after the manifest list, and that the new step annotates it.
- Keep the manifest list, its digest, the tags X.Y, X and `latest`, and the build provenance attestation unchanged.
- Document the new publish step and the check of the package page after a publish on `main` in `README.md`.
- Carry no spec delta: every changed path is a workflow and a document, which changes no behavior a consumer observes, and `actionlint` and `zizmor --offline` prove the workflow.
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

- Live evidence of 2026-11-27 confirms the cause that the issue named as unproven. The public package page of `ghcr.io/dan-petty/devtools` shows the version `sha256-2a2454c2e7868de348b54b04ffbbcc3cc00dfcc8fdddf35f2185224ebcc5d299` as Latest, gives the install command `docker pull ghcr.io/dan-petty/devtools:sha256-2a2454c2…`, and shows no description. That tag is the referrers fallback index of the manifest list `sha256:2a2454c2e7868de348b54b04ffbbcc3cc00dfcc8fdddf35f2185224ebcc5d299`, which the page lists second with the tags `latest`, `1.3.1`, `1.3` and `1`. Both were published in the same run, the referrers index last. So the page shows the newest version, and the newest version is the referrers index with no annotation.
- The GitHub documentation of the Container registry names the `org.opencontainers.image.description` annotation of the index as the description of a multi-arch image, which the manifest list already has; the documentation does not say which version the page shows, so the live page is the evidence.

- Tool calls of this run: `read_file .github/workflows/image.yml` lines 430-553 showed the publish job with its metadata step, its manifest list step, its attest step and its tag step; `search_code referrers` answered `No match.`, so no step of the repository names or annotates the referrers tag yet.
- `read_issue 19` showed the closed issue that added the annotations to the manifest list, closed by the merged pull request #27, and `read_issue 22` showed the closed issue that moved the attestation to `actions/attest`; `find_issues GHCR description referrers attestation` listed only `#29 open fix(ci): show the package description on the GHCR page`, so no other open item changes the publish job.
- `read_file README.md` lines 28-48 and 140-175 showed the attestation check and the list of publish steps; `read_file .devops/project.toml` and `read_file openspec/config.yaml` showed that this repository plans each item as an OpenSpec change and that a change of a workflow carries no spec delta.
- The probes answered, word for word: The path `.github/workflows/image.yml` is a file of the staging commit. The path `README.md` is a file of the staging commit. The path `org.opencontainers.image.description` is no file of the staging commit. No commit in the history deleted or renamed it. The path `steps.meta.outputs.annotations` is no file of the staging commit. No commit in the history deleted or renamed it. Not probed, the bound of 10 commands is reached: `latest`, `main`, `test`, `partly`, `annotations`
- The premise holds at the staged commit: the publish job gives the manifest list the annotations of metadata-action at .github/workflows/image.yml:511: `ANNOTATIONS: ${{ steps.meta.outputs.annotations }}` and then pushes the build provenance attestation to GHCR with .github/workflows/image.yml:523: `uses: actions/attest@1e69f48acb82d1966a394da916b4c1698aa569d6` and .github/workflows/image.yml:527: `push-to-registry: true`, and no step annotates the referrers tag that the attestation pushes.
- The issue recorded the cause as unproven; the live evidence above proves it, so group 1 changes the workflow and group 2 records the facts, and the page check after the next publish is the proof of the display.
- A copy of an index with one source and no annotation keeps its digest, as the staged comment records at .github/workflows/image.yml:529: `A copy of a manifest list with one source and no annotation keeps the digest.`, and the tag step checks the digest after its copy at .github/workflows/image.yml:539: `docker buildx imagetools create --metadata-file "$RUNNER_TEMP/tags.json" "${tags[@]}" "$IMAGE@$DIGEST"`, so the copy of the referrers index keeps each attestation manifest and the new step compares the manifest digests before and after.
- The staged constants that the plan relies on: `actions/attest` at `1e69f48acb82d1966a394da916b4c1698aa569d6` (.github/workflows/image.yml:523: `uses: actions/attest@1e69f48acb82d1966a394da916b4c1698aa569d6`), `docker/metadata-action` at `dc802804100637a589fabce1cb79ff13a1411302` (.github/workflows/image.yml:493: `uses: docker/metadata-action@dc802804100637a589fabce1cb79ff13a1411302`) and the annotation level at .github/workflows/image.yml:492: `DOCKER_METADATA_ANNOTATIONS_LEVELS: index`.
- No function of the repository is called. The step of group 2 calls `docker buildx imagetools inspect --raw` and `docker buildx imagetools create --tag`, with the preconditions of a client of the registry and a network to ghcr.io; the manual checks call `gh attestation verify` (README.md:39: `gh attestation verify oci://ghcr.io/dan-petty/devtools:latest --owner dan-petty`), with the preconditions of a client of GitHub and a network, and open the package page, with the precondition of a network.
- Runner capability of the group verify: `actionlint` and `zizmor --offline` are in the runner image, with failure class `lint`, no network and no pod capability; `docker` is NOT_IN_RUNNER, so the new step runs only in the publish job on a GitHub-hosted runner and no group runs it.
- First checks against the real system after the merge: the next publish on `main` runs the new step, which fails unless the referrers index lists the same manifest digests and the same description as the manifest list; then `gh attestation verify oci://ghcr.io/dan-petty/devtools:latest --owner dan-petty` must exit 0; then the package page must show the description.
- The change carries no spec delta, because every path it changes is a workflow and a document and no consumer-observed behavior changes; the repository records the rule that group 1 checks against the GitHub documentation at README.md:163: `GHCR shows the description of a multi-arch image from these annotations.`
- The two change items of the issue map to the groups: the first item (find where GHCR reads the description, show it, keep the attestation in the registry) is delivered by the live evidence above and the step of group 1; the second item, the page check after a publish on `main`, is the Workflow follow-up for a person and the check that group 2 documents. The issue body holds no list of acceptance criteria that a person wrote outside the refine block, so `criteria` is empty.

## Existing Tool Considered

docker/buildx, Apache-2.0 and maintained (last activity 2026-11-23), copies an OCI index to a tag with `--annotation` and already runs in the publish job; the change builds no code of its own and adds no dependency. The GitHub documentation of the Container registry is the source of the answer for where GHCR reads the description.

## Dependencies

None.
