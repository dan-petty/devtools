# Proposal

## Why

The image has no ansible-lint. The `ansible` preset of dan-petty/devops-cli#4648 runs `ansible-lint`, and the runner image of that repository builds FROM this image. #97 adds `ansible-lint` to the image, with a version check in the image test. A release of the image then lets devops-cli add its `RUNNER_TOOLS` row. On 2026-11-27 the owner decided that the image gets no Rust toolchain, so #97 adds only ansible-lint.

## What Changes

- Install `ansible-lint` as the fourth Python tool of the `python-tools` stage, from the hashed requirement file `python/ansible-lint.txt`, and link its command in the last stage.
- Print the version of `ansible-lint` in `test/tools.sh`, beside the other Python tools.
- Scan `python/ansible-lint.txt` in the `osv-scanner` step of the Image workflow, so that a finding in the new lock file fails the gate.
- In `README.md`, tell the reader to add the lock file of a new Python tool to the `osv-scanner` step, and add the sid version of ansible-lint to the apt rule.
- Add no Rust toolchain, no C compiler and no `rust` entry of `mise.toml`: the owner decided this on 2026-11-27.
- Carry no spec delta: the repository holds no `src/` package and no living spec, so no requirement can name code that a behavior test changes.
- The change fits one pull request.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None.

## Impact

- Code: `Dockerfile`, `python/ansible-lint.in`, `python/ansible-lint.txt`, `test/tools.sh`, `.github/workflows/image.yml`, and `python/osv-scanner.toml` only for a finding that no release fixes
- Documents: `README.md`
- Size: the image grows by 60,214,668 bytes on linux/amd64, the size of the environment of ansible-lint. The devops-cli runner image, which builds FROM this image, is 6,296,100,499 bytes at its release v0.224.2. With ansible-lint it is about 6,356,000,000 bytes, which is 643 MB below its bound of 7,000,000,000 bytes.

## Feasibility

- The update line of #97 (2026-11-27) gives the decision of the owner: "no Rust toolchain in the image. This item adds ansible-lint only."
- The probe lines confirm the premise: "The path `test/tools.sh` is a file of the staging commit.", "The path `test/tools.Dockerfile` is a file of the staging commit." and "The path `test/trivy.sh` is a file of the staging commit."
- Debian sid is not current for ansible-lint (qa.debian.org madison, 2026-11-27): sid has 26.4.0-2, and PyPI has 26.11.1 (GPL-3.0-or-later). So the apt rule of `README.md:74` sends the tool to the hashed lock of `python/`.
- `uv pip compile --universal --generate-hashes --python-version=3.14` (uv 0.13.10) compiles `ansible-lint==26.11.1` to a lock of 714 lines and 29 packages. `uv pip install --dry-run --no-build --require-hashes` for `aarch64-manylinux_2_28` and for `x86_64-manylinux_2_28` printed "Would install 29 packages", so each package has a wheel for each platform.
- In a container of the devtools image, `uv pip sync --require-hashes` with the settings of `Dockerfile:102` (`UV_LINK_MODE=copy UV_COMPILE_BYTECODE=1 UV_NO_BUILD=1`) made an environment of 60,214,668 bytes. With no network, `ansible-lint --version` through a link in `/usr/local/bin` exited 0 in 0.9 s and printed "ansible-lint 26.11.1 using ansible-core:2.22.0 ansible-compat:26.11.1 ruamel-yaml:0.19.1".
- The same command prints "WARNING: PATH altered to include /usr/local/lib/devtools/ansible-lint/bin": `path_inject` of ansible-lint puts the bin folder of its own environment first, so that the linter runs the `ansible` commands of that environment. It sends no version request: `get_version_warning` returns no text when the INSTALLER of the distribution is not pip, and the INSTALLER file holds `uv`.
- `osv-scanner scan source --lockfile requirements.txt:ansible-lint.txt` (osv-scanner 2.7.1, with `python/osv-scanner.toml`) printed "No issues found" on 2026-11-27.
- The devops-cli runner image v0.224.2 (FROM devtools 1.3.2, the layers checked) is 6,296,100,499 bytes (`podman image inspect`, linux/amd64). The runner smoke step of devops-cli refuses an image of more than 7,000,000,000 bytes.
- The Python tools come from hashed requirement files, one environment each: `Dockerfile:103:for tool in copier pre-commit semgrep; do`, `Dockerfile:105:uv pip sync --require-hashes` and `Dockerfile:153:ln -s ../lib/devtools/copier/bin/copier`. `README.md:93` states the layout, and `README.md:101` gives the steps to add a Python tool.
- The osv-scanner step is the gate of the lock files (`.github/workflows/image.yml:176` and `.github/workflows/image.yml:184:--lockfile requirements.txt:python/copier.txt`), and the Trivy step is report-only (`.github/workflows/image.yml:206`). The header of `python/osv-scanner.toml` gives the rule for an advisory that no released version fixes.
- The ignores of `python/osv-scanner.toml` for the lock of semgrep end at `effectiveUntil = 2026-11-30T00:00:00Z` (commit cfb7748). osv-scanner applies an ignore only before that time.
- The pip-compile manager of Renovate reads each file that matches `^python/[^/]+\.txt$` (`.github/renovate.json:7`), so it moves the new lock.
- release-please opens the release pull request, the release workflow turns on auto-merge, and the tag starts `image.yml`, which publishes the image (`README.md:180` to `README.md:183`). So the release needs no code here.
- dan-petty/devops-cli#4648 waits on this item: its Proposed design says "The Rust and Ansible presets wait on dan-petty/devtools#97". This item feeds it.
- The commands `uv pip compile` and `osv-scanner scan source` need a network. The script `test/tools.sh` runs only inside the built image with no network (`test/tools.Dockerfile:11:RUN --network=none`).
- The program `docker` is NOT_IN_RUNNER for the step: the image holds no Docker engine, and a Job pod has no capability and a read-only root, so the build, the image test and the scans run on the `ubuntu-24.04` and `ubuntu-24.04-arm` runners of the Image workflow.
- The command `ansible-lint` exists only in the image that the plan builds; the failure class of a missing command is exit 127, which `run` of `test/tools.sh` reports with the name of the command and which fails the image test.

## Existing Tool Considered

ansible-lint (GPL-3.0-or-later, maintained by the Ansible project) is the upstream linter from PyPI. The image installs it with uv from a hashed requirement file, as it installs copier, pre-commit and semgrep. The lint workflow of dan-petty/homelab already runs ansible-lint. The image already holds GPL tools: the Debian copyright files give GPL-3+ for `ansible-core`, `bash`, `make` and `shellcheck`, and GPL-2 for `git`. The change builds no code of its own and deletes no code.

## Dependencies

None. Issue #2 also concerns the `osv-scanner` step: the ignores of `python/osv-scanner.toml` for the lock of semgrep end on 2026-11-30, and from that date each Image run fails at that step until a renewal of the ignores or the fix of #2 merges. That failure comes from `python/semgrep.txt` and not from `python/ansible-lint.txt`, and this item does not wait for #2.
