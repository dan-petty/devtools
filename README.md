# devtools

Debian sid container image with the development tools of devops-cli: the tools of its devcontainer and of the Service Jobs that change git.

```text
ghcr.io/dan-petty/devtools
```

The image is for `linux/amd64` and `linux/arm64`: one manifest list holds the two platforms, and Docker pulls the image of your platform. It has no login user.

## Use the image

Use the image as a base. Pin a release tag and its digest, and add your own user:

```dockerfile
FROM ghcr.io/dan-petty/devtools:1.0.0@sha256:<digest>
RUN useradd --create-home --uid 1000 --shell /bin/zsh dev
```

Or copy one command into a different image. Each command that mise installs is a real file in `/usr/local/bin`:

```dockerfile
COPY --from=ghcr.io/dan-petty/devtools:1.0.0@sha256:<digest> /usr/local/bin/gh /usr/local/bin/gh
```

The digest is the digest of the manifest list. The line `Digest:` of this command shows it:

```sh
docker buildx imagetools inspect ghcr.io/dan-petty/devtools:1.0.0
```

Renovate keeps the pin current: it updates the digest after each daily rebuild, and the tag after each release (see [Versions](#versions)).

The image sets environment variables that stop the telemetry, the update notices and the self-update of its tools: `DO_NOT_TRACK`, and the variables of OpenSpec, gh, npm, Copilot, Claude Code, mise and Semgrep. A tool of the image gets a new version only with a new image. The `ENV` block of the last stage of the `Dockerfile` sets them, and a consumer image gets them from the base image. `MISE_USE_VERSIONS_HOST_TRACK=0` stops the install report that mise sends for each tool that it installs, in the build and for each user of the image. `mise self-update` is off: the file `/usr/local/lib/mise/mise-self-update-instructions.toml` tells mise that the image installs it. Copilot downloads no newer version by itself. It still writes one copy of its package for each version to `~/.cache/copilot/pkg`, when that version starts for the first time.

Each published image has a build provenance attestation. To verify it:

```sh
gh attestation verify oci://ghcr.io/dan-petty/devtools:latest --owner dan-petty
```

## Versions

Each release has a semantic version `X.Y.Z` and the git tag `vX.Y.Z` (see [Releases](#releases)). The image of a release has 4 tags:

| Tag | Example | Names |
| --- | --- | --- |
| `X.Y.Z` | `1.0.0` | the release |
| `X.Y` | `1.0` | the newest release of version `X.Y` |
| `X` | `1` | the newest release of version `X` |
| `latest` | `latest` | the newest release |

The label `org.opencontainers.image.version` of each platform image is `X.Y.Z`, and so is the annotation of the same name on the manifest list.

The daily rebuild builds the newest release again with the current sid packages, and moves its 4 tags to the new digest. When a newer release comes, the tags that only the older release has do not move again. So a tag names a release, and a digest names one build of it: pin the two. Renovate gives a pin a digest update after each daily rebuild, and a version update after each release.

The tags `YYYYMMDD.<run>` of the images before release `1.0.0` stay in the registry. No new image gets such a tag.

## Platforms

Each platform builds natively on a GitHub-hosted runner of its own architecture (`ubuntu-24.04` and `ubuntu-24.04-arm`), with no emulation. The `Dockerfile` has no code for one platform.

Tools with no `linux/arm64` build: none (2026-11-19). If a tool has no build for a platform, write its name here. The build of that platform then fails, because the image never skips a tool:

- `mise install --locked` refuses a tool that has no URL for the platform in `mise.lock`.
- `uv pip sync` with `UV_NO_BUILD=1` refuses to build a Python package from source when it has no wheel for the platform.
- The build runs `claude --version`, because the install script of Claude Code does not fail when the native package is missing.
- The tool test runs each tool once on each platform.

## Tool sources

Each tool comes from one source. No version of a tool is copied into code: a version is only in the standard file of its source, and Renovate updates that file with a built-in manager.

The rule for apt: **use apt only where sid is current.** If sid does not have a tool, or has an old version of it, a different source of the table below installs the tool: mise for a binary tool, the hashed lock of `python/` for a Python tool, and npm for a Node tool. On 2026-11-19, sid had gh 2.46.0 (upstream 2.105.0), kubectl 1.36.4 (1.37.2), promtool 3.5.3 (3.16.0), kustomize 5.8.1 (5.8.3) and gitleaks 8.26.0 (8.30.1). On 2026-11-22, sid had no copier package (upstream 9.19.1).

The manifests are the lists of the tools. This README does not copy them:

| Source | Manifest | Update |
| --- | --- | --- |
| apt (Debian sid) | the apt step of the `Dockerfile`; the packages float with sid | the daily rebuild |
| mise | `mise.toml`, `mise.lock` | Renovate `mise` |
| mise image | the `FROM` line of the mise image in the `Dockerfile` | Renovate `dockerfile` |
| uv image | the `FROM` line of the uv image in the `Dockerfile` | Renovate `dockerfile` |
| uv, hashed lock | `python/<tool>.in`, `python/<tool>.txt` | Renovate `pip-compile` |
| npm | `npm/package.json`, `npm/package-lock.json` | Renovate `npm` |

`test/tools.sh` runs each command of the image. Podman takes the place of Docker. The image has no Docker engine.

`mise.lock` holds the download URL and the sha256 checksum of each mise tool for `linux-x64` and `linux-arm64`. The build runs `mise install --locked`, which refuses a tool that has no locked URL. The copy loop of the `Dockerfile` copies each command of a mise tool, and `test/manifests.sh` fails when the loop does not name a tool of `mise.toml`. mise, uv and uvx come from their official images at a pinned digest: the last stage copies them into `/usr/local/bin` with `COPY --from`. The build uses that mise, and the image has it for the repositories that pin their tools in a `mise.toml` of their own: `mise install --locked` and `mise exec` of such a repository need only the `mise` command from the image. The image does not activate mise in a shell, so mise changes no `PATH`.

The image has two Python versions from apt. `python3.14` is the `python3` of sid, and the tool environments use it. `python3.15` is for the projects that require Python 3.15: uv uses it and downloads no Python for them.

Each Python tool has a virtual environment of its own in `/usr/local/lib/devtools`. `uv pip sync --require-hashes` refuses a distribution that the lock file does not name with its hash. The lock files of `python/` are universal: they hold the hash of the wheel of each platform.

The Node tools are in `/usr/local/lib/devtools/npm`. `npm ci --ignore-scripts` checks the sha512 of each package and runs no install script. npm installs only the native package of the build platform from the optional dependencies of a package. Then `npm rebuild` runs one install script, that of Claude Code, which `allowScripts` in `npm/package.json` approves. The script links the native binary of the platform in place of the placeholder of the `claude` command.

## Change a tool

- **apt**: add the package to the apt step of the `Dockerfile` only if sid has a current version.
- **mise**: run `mise use <tool>@<version>`, then `mise lock --platform linux-x64,linux-arm64`. Add the command name to the copy loop of the `Dockerfile`. If the command name is not the tool name of `mise.toml`, add the two names to `test/manifests.sh`.
- **Python**: write `python/<tool>.in` with `<tool>==<version>`. In `python/`, run `uv pip compile --universal --generate-hashes --python-version=3.14 <tool>.in --output-file=<tool>.txt`. Add the tool to the loop of the `python-tools` stage and its command to the links of the last stage.
- **npm**: in `npm/`, run `npm install --package-lock-only --ignore-scripts <package>@<version>` with `HOME` set to an empty folder, so that your `~/.npmrc` cannot change the registry URLs of the lock file. Add the command to the links of the last stage.

Then add `run <command> --version` to `test/tools.sh`.

## Build and test

The build makes the image of the platform of your host:

```sh
bash test/manifests.sh
docker buildx build --tag devtools:test --load .
docker buildx build --builder default --no-cache --output type=cacheonly --build-arg DEVTOOLS=devtools:test --file test/tools.Dockerfile test
docker buildx build --builder default --build-arg DEVTOOLS=devtools:test --file test/copy-probe.Dockerfile test
```

The lint steps of the CI use the tools of the image:

```sh
docker run --rm -v "$PWD:/src:ro" -w /src devtools:test hadolint Dockerfile test/*.Dockerfile
docker run --rm -v "$PWD:/src:ro" -w /src devtools:test actionlint
docker run --rm -v "$PWD:/src:ro" -w /src devtools:test shellcheck test/*.sh
```

`test/manifests.sh` checks that the copy loop of the `Dockerfile` and `mise.toml` name the same commands. `test/tools.Dockerfile` runs `test/tools.sh` in the image with no network. Each tool prints its version once, and each command has a timeout of 60 s. Then the script checks the state of the image: apt marks the dependencies as automatic, mise cannot update itself and sends no install report, and no lock file of `/usr/local/lib/devtools` is writable by all users.

## CI

The workflow [`image.yml`](.github/workflows/image.yml) runs for each pull request, for each push to `main`, for each release tag `vX.Y.Z`, each day at 04:17 UTC, and on demand. Its first job finds the release that the run publishes:

- A release tag publishes the image of its commit.
- The daily run and a manual run on `main` are the daily rebuild: they build the commit of the newest release again. Before the first release, they test `main` and publish nothing.
- A pull request, a push to `main` and a manual run on a different branch test their commit and publish nothing.

Each later job checks out the commit of the release, or the commit of the event when the run publishes nothing.

The test job runs for each event, once for each platform, on a runner of that architecture. Its token cannot write packages.

1. Run `test/manifests.sh`, which fails when the copy loop of the `Dockerfile` does not name a tool of `mise.toml`.
2. On `linux/amd64` only: lint the workflows with zizmor, offline. zizmor comes from its official image at a pinned digest, because the image has no zizmor. A finding fails the job.
3. Build the image with the docker driver of the default builder. The image goes into the image store of Docker with no export. The daily rebuild uses `--pull --no-cache`.
4. On `linux/amd64` only: lint each Dockerfile with hadolint, the workflows with actionlint (which also runs shellcheck on each `run` script), and `test/*.sh` with shellcheck. The three tools come from the image that the job built, so a pull request that updates one of them lints with the new version. A finding fails the job.
5. Build `test/tools.Dockerfile`, which starts each tool once with no network and checks the state of the image.
6. Build `test/copy-probe.Dockerfile`, which copies `gh` into `python:3.14-slim-trixie` and runs it.
7. Scan the npm and Python lock files with osv-scanner. A finding fails the job.
8. Scan the image with Trivy (`test/trivy.sh`), report-only. The SARIF goes to code scanning in the category `trivy-image-amd64` or `trivy-image-arm64`, and the job summary names the image size, the detected OS and the finding counts. The Trivy databases come from the cache that the newest run on `main` saved.

For a release, when the two test jobs pass, the push job runs once for each platform, on a runner of that architecture. It builds the image again with the docker-container driver, and pushes it by digest with SBOM and provenance attestations. The label `org.opencontainers.image.version` of each platform image is the version `X.Y.Z` of the release, and the label `org.opencontainers.image.revision` is the commit of the release.

Then the verify job runs once for each platform, on a runner of that architecture. It runs the image checks of the test job again on the pushed digest, because the publish job tags these bytes:

1. Pull the pushed image into the image store of Docker.
2. Build `test/tools.Dockerfile` and `test/copy-probe.Dockerfile` on the pushed image.
3. Scan the pushed image with Trivy, report-only. The SARIF goes to code scanning in the category `trivy-pushed-amd64` or `trivy-pushed-arm64`.

Then the publish job:

1. Stops if the release is not the newest release, for example when a newer release came during a daily rebuild. Then no tag moves.
2. Makes one manifest list of the two digests with `docker buildx imagetools create`, and tags it `X.Y.Z`.
3. Attests the build provenance of the manifest list.
4. Moves `X.Y`, `X` and `latest` to the attested manifest list, and stops if a tag gets a different digest.
5. Copies the referrers index `sha256-<digest>` that the attestation pushed, with `docker buildx imagetools create --annotation` and the annotations of the manifest list, so that both package versions carry the description. A dry run comes first: the job stops before the push when the copy would change a field of a descriptor of the referrers index or would not carry the description.

The manifest list has the OCI annotations of `docker/metadata-action`, such as `org.opencontainers.image.description`, `source` and `licenses`. The package page of `ghcr.io/dan-petty/devtools` shows the newest package version as Latest, with its description. `actions/attest` with `push-to-registry` pushes the referrers index `sha256-<digest>` of the attestation after the manifest list, so that index is the newest version, and step 5 copies it with the annotations of the manifest list. The page still marks the referrers index as Latest, so its install command names the `sha256-` tag: pull `latest` or a version tag.

After a publish on `main`, check that the copy kept the attestation in the registry and that the page shows the description:

```sh
gh attestation verify oci://ghcr.io/dan-petty/devtools:latest --owner dan-petty --bundle-from-oci
```

The command exits 0, which proves that the attestation in the registry still reads after the copy, and the package page shows the description.

The gate is on the lock files: osv-scanner fails the job on a finding in the npm and Python locks. The Trivy scan of the image is report-only (owner decision of 2026-11-19 in #1), because the Go binaries of upstream tools at their newest release hold HIGH and CRITICAL findings that no change here can fix. The daily rebuild and the Renovate updates close the alerts in code scanning. Trivy finds no OS package findings on Debian sid, because sid has no security tracker data. The owner approved this gap on 2026-11-19.

An ignore of a finding that has no released fix has a reason, a tracking issue and an end date. `python/osv-scanner.toml` holds the ignores of the Python lock files.

## Releases

[release-please](https://github.com/googleapis/release-please) makes each release from the Conventional Commit titles of the commits on `main`. The workflow [`release.yml`](.github/workflows/release.yml) runs it on each push to `main`:

1. release-please keeps one release pull request open. The pull request holds the next version in `version.txt` and `.release-please-manifest.json`, and the new entry of `CHANGELOG.md`.
2. The release workflow turns on auto-merge and requests review from `dan-petty`, and GitHub merges the pull request when its required checks pass. The next run creates the tag `vX.Y.Z` and its GitHub release.
3. The tag starts `image.yml`, which publishes the image of the release (see [CI](#ci)).

`release-please-config.json` holds the release type `simple`, the tag form `vX.Y.Z` and the first version, `1.0.0`. The next version comes from the commit types since the last release: `fix` gives a patch release, `feat` a minor release, and `!` or a `BREAKING CHANGE` footer a major release. A type such as `chore`, `ci`, `docs` or `test` gives no release.

Renovate writes `fix(deps):` for an update of a tool or of a base image of the image (`Dockerfile`, `mise.toml`, `npm/`, `python/`), so the update gets a release. An update of a GitHub action or of a test image keeps the `chore(deps):` of the shared preset, because it does not change the image.

The workflow [`pr-title.yml`](.github/workflows/pr-title.yml) checks that the title of each pull request is a Conventional Commit with a summary of at most 60 characters. The scope is optional: one of the `scope/*` labels of `.github/labels.yml`, or `main` for the release pull request. A squash merge of a pull request with one commit takes the subject of the commit, not the title of the pull request, so for such a pull request the workflow also checks the subject of the commit.

The release workflow uses a token of the release App from the environment `release`: the variable `RELEASE_APP_CLIENT_ID` and the secret `RELEASE_APP_PRIVATE_KEY`. A pull request or a tag that `GITHUB_TOKEN` creates starts no workflow, but the ruleset of `main` requires the checks of `image.yml` on the release pull request, and the tag must start `image.yml`. Only `main` deploys to the environment. If a credential is missing, the first step of the job names it and stops.

## License

[MIT](LICENSE)
