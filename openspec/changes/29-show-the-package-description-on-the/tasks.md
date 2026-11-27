# Tasks

## 1. Annotate the attestation referrers index after the tags move

Kind: other. Reads: `.github/workflows/image.yml`, `README.md`. Changes: `.github/workflows/image.yml`, `README.md`.

- [ ] 1.1 Add a step named Annotate the attestation referrers index to the publish job of `.github/workflows/image.yml`, after the step `Tag the attested manifest list X.Y, X and latest` and before the step `Show the manifest list`, so a failure of the new step leaves the release tags moved. The step takes `DIGEST: ${{ steps.index.outputs.digest }}` and `ANNOTATIONS: ${{ steps.meta.outputs.annotations }}` from its env, builds the tag `$IMAGE:sha256-` followed by the digest without its `sha256:` prefix, and saves the `manifests` array of the raw referrers index (`docker buildx imagetools inspect --raw` and `jq -S '.manifests'`). It copies that tag to itself with `docker buildx imagetools create --tag` and one `--annotation` flag for each line of the annotations, reads the raw index again, and exits 1 with an `::error::` line when the `manifests` array differs in any field (digest, mediaType, size, artifactType or annotations of a descriptor) or when the index annotation `org.opencontainers.image.description` differs from the one of the manifest list. Add the new step as step 5 to the publish list of `README.md`
  - Verification: `$ actionlint .github/workflows/image.yml` passes
  - Verification: `$ zizmor --offline .github/workflows/image.yml` passes

## 2. Record where the package page reads the description

Kind: other. Reads: `README.md`, `.github/workflows/image.yml`. Changes: `README.md`.

- [ ] 2.1 Replace the sentence `GHCR shows the description of a multi-arch image from these annotations.` of `README.md` with the facts of the package page: the page shows the newest package version as Latest, with its description; `actions/attest` with `push-to-registry` pushes the referrers index `sha256-<digest>` after the manifest list, so that index is the newest version; and step 5 gives it the annotations of the manifest list. Add to the CI section the check after a publish on `main`: `gh attestation verify oci://ghcr.io/dan-petty/devtools:latest --owner dan-petty --bundle-from-oci` exits 0, which proves that the attestation in the registry still reads after the copy, and the package page shows the description, and run this check by hand: 1. Read the publish list and the description sentence of `README.md`. 2. Compare them with the step names of the publish job of `.github/workflows/image.yml`: each step has its line, step 5 names the copy of the referrers index, and the check names `--bundle-from-oci`.

## Workflow follow-up

- Pending a person: after the next publish on `main`, run `gh attestation verify oci://ghcr.io/dan-petty/devtools:latest --owner dan-petty --bundle-from-oci` and see exit 0, run `docker buildx imagetools inspect --raw ghcr.io/dan-petty/devtools:sha256-<digest of latest>` and see the description annotation, and open the package page of `ghcr.io/dan-petty/devtools` and see the description.
