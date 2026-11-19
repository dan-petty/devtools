# devtools

Debian sid container image with the development tools of devops-cli: the tools of its devcontainer and of the Service Jobs that change git.

```text
ghcr.io/dan-petty/devtools
```

The image is for `linux/amd64` only. It has no login user.

## Use the image

Use the image as a base. Pin the digest, and add your own user:

```dockerfile
FROM ghcr.io/dan-petty/devtools:latest@sha256:<digest>
RUN useradd --create-home --uid 1000 --shell /bin/zsh dev
```

Or copy one command into a different image. Each command that mise installs is a real file in `/usr/local/bin`:

```dockerfile
COPY --from=ghcr.io/dan-petty/devtools:latest@sha256:<digest> /usr/local/bin/gh /usr/local/bin/gh
```

Each published image has a build provenance attestation. To verify it:

```sh
gh attestation verify oci://ghcr.io/dan-petty/devtools:latest --owner dan-petty
```

## Tool sources

Each tool comes from one source. No version of a tool is copied into code: a version is only in the standard file of its source, and Renovate updates that file with a built-in manager.

The rule for apt: **use apt only where sid is current.** If sid does not have a tool, or has an old version of it, mise installs the tool. On 2026-11-19, sid had gh 2.46.0 (upstream 2.105.0), kubectl 1.36.4 (1.37.2), promtool 3.5.3 (3.16.0), kustomize 5.8.1 (5.8.3) and gitleaks 8.26.0 (8.30.1).

| Source | Tools | Version file | Update |
| --- | --- | --- | --- |
| apt (Debian sid) | git, jq, shellcheck, curl, socat, bubblewrap, gnome-keyring, zsh, sudo, ping, tracepath, mtr, nc, tcpdump, traceroute, unzip, python3.14 (`python`), nodejs, npm, ansible-core, ansible-runner, bandit, podman, buildah, skopeo, crun, passt, uidmap, fuse-overlayfs, containers-storage | none: the packages float with sid | the daily rebuild |
| mise | gh, kubectl, kustomize, helm, minikube, argo, argocd, kubectl-argo-rollouts, cloudflared, trivy, tofu, promtool, kube-linter, popeye, pluto, kubeconform, tflint, k9s, gitleaks, osv-scanner, golangci-lint, vale, actionlint, hadolint, gh-dash, tuicr | `mise.toml`, `mise.lock` | Renovate `mise` |
| uv image | uv, uvx | `Dockerfile` | Renovate `dockerfile` |
| uv, hashed lock | semgrep, pre-commit | `python/<tool>.in`, `python/<tool>.txt` | Renovate `pip-compile` |
| npm | openspec, devcontainer, style-dictionary, copilot, claude | `npm/package.json`, `npm/package-lock.json` | Renovate `npm` |

Podman takes the place of Docker. The image has no Docker engine.

`mise.lock` holds the download URL and the sha256 checksum of each mise tool for `linux-x64`. The build runs `mise install --locked`, which refuses a tool that has no locked URL. The mise image and the uv image come into the build with `COPY --from` at a pinned digest. The build does not put mise in the image.

Each Python tool has a virtual environment of its own in `/usr/local/lib/devtools`. `uv pip sync --require-hashes` refuses a distribution that the lock file does not name with its hash. The Node tools are in `/usr/local/lib/devtools/npm`. `npm ci --ignore-scripts` checks the sha512 of each package and runs no install script. The `claude` command is the native binary of the Claude Code platform package, because the install script that copies it is not run.

## Change a tool

- **apt**: add the package to the apt step of the `Dockerfile` only if sid has a current version.
- **mise**: run `mise use <tool>@<version>`, then `mise lock --platform linux-x64`. Add the command name to the copy loop of the `Dockerfile`.
- **Python**: write `python/<tool>.in` with `<tool>==<version>`. In `python/`, run `uv pip compile --universal --generate-hashes --python-version=3.14 <tool>.in --output-file=<tool>.txt`. Add the tool to the loop of the `python-tools` stage and its command to the links of the last stage.
- **npm**: in `npm/`, run `npm install --package-lock-only --ignore-scripts <package>@<version>` with `HOME` set to an empty folder, so that your `~/.npmrc` cannot change the registry URLs of the lock file. Add the command to the links of the last stage.

Then add the command to `test/tools.sh`.

## Build and test

```sh
docker buildx build --platform linux/amd64 --tag devtools:test --load .
docker run --rm --network none -v "$PWD/test:/test:ro" devtools:test bash /test/tools.sh
docker buildx build --builder default --build-arg DEVTOOLS=devtools:test --file test/copy-probe.Dockerfile test
```

mise reads the GitHub API. To raise its rate limit, give the build a token: `--secret id=github_token,env=GITHUB_TOKEN`.

## CI

The workflow [`image.yml`](.github/workflows/image.yml) runs for each pull request, for each push to `main`, each day at 04:17 UTC, and on demand.

1. Build the image and load it into Docker. The daily build uses `--pull --no-cache`.
2. Run `test/tools.sh`, which starts each tool once with no network.
3. Build `test/copy-probe.Dockerfile`, which copies `gh` into `python:3.14-slim-trixie` and runs it.
4. Scan the image with Trivy. The SARIF goes to code scanning, and the job summary names the detected OS and the finding counts. A HIGH or CRITICAL finding that has a fix fails the job.
5. Scan the npm and Python lock files with osv-scanner.
6. On `main` only: push the image by digest with SBOM and provenance attestations, attest the build provenance, then tag the digest `latest` and `YYYYMMDD`.

Trivy finds no OS package findings on Debian sid, because sid has no security tracker data. The gate covers the binaries and the language packages. The owner approved this gap on 2026-11-19.

An ignore of a finding that has no released fix has a reason, a tracking issue and an end date. `python/osv-scanner.toml` holds the ignores of the Python lock files.

## License

[MIT](LICENSE)
