# Design

## Decisions

- **Take the live package page as the evidence of where the description comes from.**: The page shows the referrers index `sha256-<digest>` as Latest and shows no description, while the tagged manifest list carries the annotation; the documentation names the index annotation but not the version that the page shows.
- **Copy the attestation referrers index with docker buildx imagetools create and its `--annotation` flags.**: The referrers index is the package version that the page marks as the newest, so the copy gives that version the description while the attested manifest list digest stays unchanged; buildx already runs in the publish job.
- **Reuse the annotation values of the metadata-action annotations output for both indexes.**: One source of values: the description of the referrers index matches the manifest list by construction and no literal is duplicated.
- **Place the new step after the tag step and before `Show the manifest list`.**: The referrers tag exists only after the attestation pushes it, and a failure of the new step must not stop the tags X.Y, X and `latest` from moving to the attested manifest list.
- **Dry-run the copy, compare the whole `manifests` array and the description, and push only on a match.**: `docker buildx imagetools create` builds a new index from the descriptors of its source, so a later buildx that dropped an `artifactType` or an annotation of a descriptor would hide the attestation from `gh attestation verify --bundle-from-oci`, which filters the referrers by artifact type. A check after the push would leave the broken index on the tag; the dry run prints the new index and pushes nothing.
- **Check the registry attestation with `gh attestation verify --bundle-from-oci`.**: Without the flag, the command reads the attestation from the GitHub API, so it would pass even when the copy broke the referrers index.
- **Check the package page after the next publish on `main`, and record that check in `README.md`.**: The display on the real page is the proof that the issue asks for; the check needs no extra repository, token or permission.

## Rejected alternatives

- **Re-push the manifest list with the annotation.**: Annotations are part of the manifest, so a re-push gets a new digest, and the attestation names the old digest at .github/workflows/image.yml:526: `subject-digest: ${{ steps.index.outputs.digest }}`.
- **Set the description with the GitHub Packages REST API.**: The job writes with the workflow token at .github/workflows/image.yml:483: `password: ${{ github.token }}`, which cannot administer a user package, so the call would need a user token with admin on the package.
- **Add the annotation to each platform image manifest.**: The platform digests change, and the manifest list names them as its sources at .github/workflows/image.yml:516: `for digest in *; do sources+=("$IMAGE@sha256:$digest"); done`.
- **Stop pushing the attestation to the registry.**: The issue requires the in-registry attestation, .github/workflows/image.yml:527: `push-to-registry: true` is the step that puts it there, and README.md:39: `gh attestation verify oci://ghcr.io/dan-petty/devtools:latest --owner dan-petty` documents the check.
- **Add only the description annotation to the referrers index.**: The index annotations come from one output at .github/workflows/image.yml:511: `ANNOTATIONS: ${{ steps.meta.outputs.annotations }}`, so a second source for the description drifts from the manifest list.
- **Hard-code the description in the step.**: The values come from metadata-action, as README.md:163: `GHCR shows the description of a multi-arch image from these annotations.` records; a literal in the workflow is a second source of truth.
- **Publish a test package in a scratch repository to find where GHCR reads the description.**: The publish job names one image at .github/workflows/image.yml:525: `subject-name: ${{ env.IMAGE }}`, so a scratch package needs a second repository and its own package permissions, and its page can behave differently from the page of this package.
- **Take the GitHub documentation as the proof that the page shows the description, with no check of the page.**: The manifest list already carries the annotation that the documentation names, and the page shows no description, so the documentation alone proves nothing about this package.
