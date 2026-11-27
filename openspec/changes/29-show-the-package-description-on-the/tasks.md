# Tasks

## 1. Record where GHCR reads the package description

Kind: other. Reads: `.github/workflows/image.yml`, `README.md`. Changes: `README.md`.

- [ ] 1.1 Read the GitHub documentation page `Working with the Container registry` and its rules for the description of a package version, then correct the sentence of `README.md` that says GHCR shows the description of a multi-arch image from the annotations of the manifest list, so that it names the package version that GHCR reads the description from and names the documentation as the source. The step reads the staged publish job at `.github/workflows/image.yml` to name the two package versions that a publish pushes, and run this check by hand: 1. Open the GitHub documentation page `Working with the Container registry` on docs.github.com and read how GHCR chooses the description of a package version. 2. On a host with a GHCR login, run `docker buildx imagetools inspect --raw ghcr.io/dan-petty/devtools:1.0.0` and `docker buildx imagetools inspect --raw ghcr.io/dan-petty/devtools:sha256-` followed by the digest of the manifest list without its `sha256:` prefix, and note which index carries `org.opencontainers.image.description`. 3. Confirm that the corrected sentence of `README.md` matches what the documentation says.
- [ ] 1.2 Edit `README.md` so that its CI section states where GHCR reads the description of a multi-arch package that has an in-registry attestation, with the GitHub documentation page as the source
  - Verification: `$ uv run devops ci docs` passes

## 2. Annotate the attestation referrers index

Kind: other. Reads: `.github/workflows/image.yml`, `README.md`. Changes: `.github/workflows/image.yml`, `README.md`.

- [ ] 2.1 Add a step named Annotate the attestation referrers index to the publish job of `.github/workflows/image.yml`, after the step `Attest the build provenance` and before the step `Tag the attested manifest list X.Y, X and latest`. The step takes `DIGEST: ${{ steps.index.outputs.digest }}` and `ANNOTATIONS: ${{ steps.meta.outputs.annotations }}` from its env, builds the tag `$IMAGE:sha256-` followed by the digest without its `sha256:` prefix, saves the manifest digests of the raw referrers index with `docker buildx imagetools inspect --raw` and `jq`, copies that tag with `docker buildx imagetools create --tag` and one `--annotation` flag for each line of the annotations, then reads the raw index again and exits 1 when a manifest digest differs or the description differs from the manifest list. Then add the new step to the publish list of `README.md`
  - Verification: `$ uv run devops ci --check --only actionlint,zizmor` passes
- [ ] 2.2 Edit `README.md` so that the list of publish steps names the copy of the attestation referrers index and the annotations of both package versions
  - Verification: `$ uv run devops ci docs` passes

## 3. Check the package page after the next publish

Kind: other. Reads: `README.md`, `.github/workflows/image.yml`. Changes: `README.md`.

- [ ] 3.1 Add to the CI section of `README.md` the check that proves the description on the package page of the publish job of `.github/workflows/image.yml`, and state that the check runs after a publish on `main`, and run this check by hand: 1. Wait for the next publish job on `main` to finish. 2. Run `gh attestation verify oci://ghcr.io/dan-petty/devtools:latest --owner dan-petty` and confirm that it exits 0. 3. Run `docker buildx imagetools inspect --raw ghcr.io/dan-petty/devtools:latest` and confirm that the description equals the one of the manifest list. 4. Open the package page of `ghcr.io/dan-petty/devtools` on github.com and confirm that it shows the description.
- [ ] 3.2 Edit `README.md` so that the CI section names the package page check after a publish on `main` as the proof of the description
  - Verification: `$ uv run devops ci docs` passes
