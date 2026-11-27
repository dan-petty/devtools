# Proposal

## Why

The package page of ghcr.io/dan-petty/devtools shows no description after the publish of 20261120.41, although the manifest list carries `org.opencontainers.image.description`. The page marks the referrers index of the attestation as the newest package version, and that index carries no annotation. #29 asks where GHCR reads the description of a multi-arch package that has an attestation in the registry, that the page show it, and that the attestation stay in the registry.

## What Changes

- Add a step to the publish job of `.github/workflows/image.yml`, after the tags move, that copies the attestation referrers tag with `docker buildx imagetools create --tag` and the `--annotation` values of `steps.meta.outputs.annotations`, so the newest package version carries the description.
- Run the copy first with `--dry-run`, and push it only when the printed index keeps every field of each descriptor in the `manifests` array of the referrers index and carries the `org.opencontainers.image.description` of the manifest list; keep the raw original index in `$RUNNER_TEMP`.
- Record in `README.md` that the package page shows the newest package version as Latest, that the attestation pushes the referrers index after the manifest list, that the new step annotates it, and the check of the package page after a publish on `main`.
- Keep the manifest list, its digest, the tags X.Y, X and `latest`, and the build provenance attestation unchanged.
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
- Other packages show the same pattern (read on 2026-11-27): the pages of `j178/prek`, `grafana/docker-otel-lgtm` and `maplibre/martin` mark a `sha256-` referrers version as Latest and show no description, although their `latest` index has the description annotation; the page of `zizmorcore/zizmor`, whose Latest is the annotated index `1.33.1`, shows its description. That GHCR reads the description of an index whose children are artifact manifests with no platform stays unproven until the page check after the next publish.
- The premise holds at the staged commit: the publish job gives the manifest list the annotations of metadata-action at .github/workflows/image.yml:511: `ANNOTATIONS: ${{ steps.meta.outputs.annotations }}` and then pushes the build provenance attestation to GHCR with .github/workflows/image.yml:523: `uses: actions/attest@1e69f48acb82d1966a394da916b4c1698aa569d6` and .github/workflows/image.yml:527: `push-to-registry: true`, and no step annotates the referrers tag that the attestation pushes.
- The issue recorded the cause as unproven; the live evidence above proves it, so group 1 changes the workflow and group 2 records the facts, and the page check after the next publish is the proof of the display.
- `docker buildx imagetools create` with one index source and annotations keeps each descriptor: in docker/buildx v0.39.1, `util/imagetools/create.go` lines 150 to 160 read the source index into `ocispecs.Index` and add each whole `ocispecs.Descriptor` (with `ArtifactType`), and lines 179 to 191 write the new index from those descriptors, with the `index:` annotations on the index. Only an index-level `artifactType` or `subject` would be lost, and the referrers index has neither. A `--dry-run` of that copy on the live tag `sha256-2a2454c2…` printed an index whose `manifests` array equals the original, `artifactType` `application/vnd.dev.sigstore.bundle.v0.3+json` included.
- The staged constants that the plan relies on: `actions/attest` at `1e69f48acb82d1966a394da916b4c1698aa569d6` (.github/workflows/image.yml:523: `uses: actions/attest@1e69f48acb82d1966a394da916b4c1698aa569d6`), `docker/metadata-action` at `dc802804100637a589fabce1cb79ff13a1411302` (.github/workflows/image.yml:493: `uses: docker/metadata-action@dc802804100637a589fabce1cb79ff13a1411302`) and the annotation level at .github/workflows/image.yml:492: `DOCKER_METADATA_ANNOTATIONS_LEVELS: index`.
- No function of the repository is called. The step of group 1 calls `docker buildx imagetools inspect --raw` and `docker buildx imagetools create --tag`, with the preconditions of a client of the registry and a network to ghcr.io; the manual checks call `gh attestation verify` (README.md:39: `gh attestation verify oci://ghcr.io/dan-petty/devtools:latest --owner dan-petty`), with the preconditions of a client of GitHub and a network, and open the package page, with the precondition of a network.
- Runner capability of the group verify: `actionlint` and `zizmor --offline` are in the runner image, with failure class `lint`, no network and no pod capability; `docker` is NOT_IN_RUNNER, so the new step runs only in the publish job on a GitHub-hosted runner and no group runs it.
- First checks against the real system after the merge: the next publish on `main` runs the new step, which pushes the copy only when its dry run keeps the `manifests` array of the referrers index as before the copy and carries the description of the manifest list; then `gh attestation verify oci://ghcr.io/dan-petty/devtools:latest --owner dan-petty --bundle-from-oci` must exit 0 (`gh` filters the referrers by the artifact type prefix `application/vnd.dev.sigstore.bundle` and falls back to the `sha256-` tag, because GHCR answers 404 on the referrers API); then the package page must show the description.
- The change carries no spec delta, because every path it changes is a workflow and a document and no consumer-observed behavior changes; the repository records the rule that group 1 checks against the GitHub documentation at README.md:163: `GHCR shows the description of a multi-arch image from these annotations.`
- The issue maps to the groups: its first Change item (find where GHCR reads the description) is the live evidence above; its second Change item (show the description, keep the attestation in the registry) is the step of group 1 and the facts of group 2; its Proof (the package page after a publish on `main`) is the Workflow follow-up for a person. The issue body holds no list of acceptance criteria that a person wrote outside the refine block, so `criteria` is empty.

## Existing Tool Considered

docker/buildx, Apache-2.0 and maintained (last activity 2026-11-23), copies an OCI index to a tag with `--annotation` and already runs in the publish job; the change builds no code of its own and adds no dependency. The GitHub documentation of the Container registry is the source of the answer for where GHCR reads the description. The change deletes no internal code.

## Dependencies

None.
