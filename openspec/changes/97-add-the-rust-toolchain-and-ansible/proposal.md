# Proposal

## Why

The image has no Rust toolchain and no ansible-lint. The `rust-cargo` and `ansible` presets of dan-petty/devops-cli#4648 run `cargo build`, `cargo test`, `cargo clippy`, `cargo fmt --check` and `ansible-lint`, and the runner image of that repository builds FROM this image. #97 adds `cargo`, `rustc`, `rustdoc`, `rustfmt`, `cargo clippy`, `cargo fmt`, the C linker that `rustc` calls, and `ansible-lint` to the image, each with a check in the image test. A release of the image then lets devops-cli add its `RUNNER_TOOLS` rows.

## What Changes

- Pin the `rust` tool in `mise.toml` at one stable release with the `minimal` profile and the components `clippy` and `rustfmt`, and lock it with `mise lock --platform linux-x64,linux-arm64`. The `tools.rust` entry of `mise.lock` holds the version and the options, and no URL: mise installs Rust through rustup.
- In the `mise-tools` stage, copy the toolchain folder that `mise exec -- rustc --print sysroot` prints to `/out/rust`. The last stage copies it to `/usr/local/lib/devtools/rust` and links `cargo`, `cargo-clippy`, `cargo-fmt`, `rustc`, `rustdoc` and `rustfmt` into `/usr/local/bin`.
- Add the apt packages `gcc` and `libc6-dev`, because `rustc` links each program with `cc`.
- Teach `test/manifests.sh` that the `rust` key provides six commands, which come from the links of the last stage and not from the copy loop. Add no second `for command in` loop to the `Dockerfile`.
- Install `ansible-lint` as the fourth Python tool from the hashed requirement file `python/ansible-lint.txt`.
- Print the version of each new command in `test/tools.sh`, in the block of its installer, and build and test a new crate offline in the same script.
- Scan `python/ansible-lint.txt` in the `osv-scanner` step of the Image workflow, so that a finding in the new lock file fails the gate.
- Document in `README.md` the Rust folder and its links, the `rust` entry of `mise.lock` with no URL, the C linker, and the mise tool that provides several commands from one folder.
- Carry no spec delta: the repository holds no `src/` package and no living spec, so no requirement can name code that a behavior test changes.
- The change fits one pull request.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None.

## Impact

- Code: `mise.toml`, `mise.lock`, `Dockerfile`, `test/manifests.sh`, `python/ansible-lint.in`, `python/ansible-lint.txt`, `test/tools.sh`, `.github/workflows/image.yml`
- Documents: `README.md`
- Size: the image grows by about 0.93 GB on linux-x64: 623 MB of toolchain, 244 MB of `gcc` and `libc6-dev`, and 58 MB of ansible-lint.

## Feasibility

- The probe lines confirm the premise word for word: "The path `mise.toml` is a file of the staging commit.", "The path `test/tools.sh` is a file of the staging commit.", "The path `mise.lock` is a file of the staging commit.", "The path `test/tools.Dockerfile` is a file of the staging commit." and "The path `test/trivy.sh` is a file of the staging commit."
- The probe shows that the image holds no Rust command: "`cargo` has no definition at the staging commit. No commit in the history added or removed its text." The devcontainer, which builds FROM this image, has no `cc`, `gcc` or `ld` (`command -v` found none on 2026-11-27).
- The mise registry holds the tool: `mise registry rust` with mise 2026.11.14, the version of `Dockerfile:13`, prints `core:rust asdf:code-lever/asdf-rust`, and `mise ls-remote rust` lists 1.100.0 as the newest stable release (read on 2026-11-27).
- `mise lock --platform linux-x64,linux-arm64` for `rust = "1.100.0"` writes only `version`, `backend = "core:rust"` and `specifiers`: no URL and no checksum for a platform. The rust plugin of the mise source at tag v2026.11.14 gives the reason: `supports_lockfile_url` returns false, with the comment "Rust uses rustup for installation, which handles its own downloads." `mise install --locked` accepts this entry: in a scratch home it installed rust 1.100.0 in 18 s and exited 0. So `README.md:65` and `README.md:89` ("refuses a tool that has no locked URL") are not true for `rust`.
- mise installs Rust through rustup. The mise page of Rust says: "The toolchains live in `RUSTUP_HOME`, not in mise's installs directory; mise keeps a link there to track the version." In the scratch home, `mise which cargo` printed `~/.cargo/bin/cargo`, a link to `rustup`. `~/.cargo` held 21 MB of rustup proxies, and the toolchain was `~/.rustup/toolchains/1.100.0-x86_64-unknown-linux-gnu`. A copy of `~/.cargo` with linked commands failed for a different home: `cargo --version` printed "error: rustup could not choose a version of cargo to run, because one wasn't specified explicitly, and no default is configured." and exited 1.
- `mise exec -- rustc --print sysroot` printed the toolchain folder. A read-only copy of that folder with linked commands ran `cargo --version`, `rustc --version`, `rustfmt --version`, `cargo clippy --version` and `cargo fmt --version` for a different home. With no `rustdoc` link, `cargo test --doc` failed with "could not execute process `rustdoc ...` (never executed)".
- With no C compiler, `cargo test` failed with "error: linker `cc` not found". The apt step (`Dockerfile:53` to `Dockerfile:91`) has no `gcc`. In a container of the devtools image, `apt-get install --no-install-recommends gcc libc6-dev` added 32 packages and 244 MB. With the toolchain folder mounted read-only and the six commands linked, a user that is not root then ran `cargo new --lib`, `cargo test --offline`, `cargo clippy --offline` and `cargo fmt --check`, and each exited 0. The slim image of the official Rust images (rust-lang/docker-rust, stable, trixie) installs the same two packages and uses the `minimal` profile.
- The size of the toolchain folder with the `minimal` profile and the components `clippy` and `rustfmt` is 623 MB on linux-x64. When `mise.toml` names no profile, mise uses the profile of rustup, which is `default`, and `default` adds `rust-docs`: the folder became 1.3 GB and 66,000 files. The devops-cli runner image, which builds FROM this image, was 6.05 GB, and its smoke step refuses an image of more than 7,000,000,000 bytes.
- The Build step of the Image workflow took 1 min 42 s on the plan commit, in a job of 3.5 min with a limit of 30 min. The scratch install of rust took 18 s.
- Debian sid is not current for the two tools (qa.debian.org madison, 2026-11-27): rustc and cargo 1.99.1 (upstream 1.100.0) and ansible-lint 26.4.0 (upstream 26.11.1). So the apt rule of `README.md:74` sends them to mise and to the hashed lock of `python/`.
- ansible-lint 26.11.1 (GPL-3.0-or-later) compiles with `uv pip compile --universal --generate-hashes --python-version=3.14` to a lock of 714 lines and 29 packages. `uv pip sync --require-hashes` with `UV_NO_BUILD=1` into a python3.14 environment exited 0 (58 MB), and `uv pip install --dry-run --no-build --python-platform aarch64-manylinux_2_28` found a wheel for each package. `osv-scanner scan source --config python/osv-scanner.toml --lockfile requirements.txt:ansible-lint.txt` (osv-scanner 2.7.1) printed "No issues found".
- `ansible-lint --version` through a link exits 0 and prints "WARNING: PATH altered to include <environment>/bin" on stderr: `path_inject` of ansible-lint puts the bin folder of its own environment first, so that the linter runs the `ansible` commands of that environment. It sends no version request: `get_version_warning` returns no text when the INSTALLER of the distribution is not pip, and uv writes `uv` there.
- Renovate moves the new pins: its mise manager maps `rust` to the rust-version datasource and reads the `version` of a table value, and `MISE_SAFE=1 mise lock`, which Renovate runs, moved the `rust` entry from 1.100.0 to 1.99.1 in a scratch copy and kept its options. The pip-compile manager reads each file that matches `^python/[^/]+\.txt$` (`.github/renovate.json:7`).
- The image installs each binary tool from the lock file and copies one command per file: `Dockerfile:33:mise install --locked` and `Dockerfile:38:install -m 0755 "$(mise which "$command")" "/out/bin/$command"`.
- The last stage shows the pattern of a copied tool folder with linked commands: `Dockerfile:150:COPY --from=python-tools /usr/local/lib/devtools/ /usr/local/lib/devtools/` and `Dockerfile:153:ln -s ../lib/devtools/copier/bin/copier`, whose target folder `Dockerfile:162:/usr/local/bin/` is the last word of the same `ln -s` command.
- `test/manifests.sh` cuts the joined `Dockerfile` at the last loop (`test/manifests.sh:27` and `test/manifests.sh:28:s/.*for command in//`) and prints one line per tool key (`test/manifests.sh:22:echo "$command"`). So the `rust` arm prints its six names one per line, and the six names of the copied set come from the `rust/bin` targets of the `ln -s` list. The two sides then hold 33 names each.
- The Python tools come from hashed requirement files, one environment each: `Dockerfile:103:for tool in copier pre-commit semgrep; do` and `Dockerfile:105:uv pip sync --require-hashes`; `README.md:93` states the layout.
- The osv-scanner step is the gate of the lock files (`.github/workflows/image.yml:176` and `.github/workflows/image.yml:184:--lockfile requirements.txt:python/copier.txt`), and the Trivy step is report-only (`.github/workflows/image.yml:206`). The header of `python/osv-scanner.toml` gives the rule for an advisory that no released version fixes. Its ignores now end on 2026-11-30 (commit cfb7748).
- release-please opens the release pull request, the release workflow turns on auto-merge, and the tag starts `image.yml`, which publishes the image (`README.md:173` to `README.md:175`). So the release needs no code here.
- dan-petty/devops-cli#4648 waits on this item: its Proposed design says "The Rust and Ansible presets wait on dan-petty/devtools#97". This item feeds it, and depends on no open item.
- The commands `mise lock`, `mise install --locked`, `uv pip compile`, `uv pip sync` and `osv-scanner scan source` need a network. `mise exec -- rustc --print sysroot` needs the toolchain that `mise install --locked` installed in the same `RUN` step, so it runs inside the `mise-tools` stage.
- The script `test/manifests.sh` needs a checkout of the repository and the programs `bash`, `python3`, `sed`, `tr`, `sort` and `comm`. The script `test/tools.sh` runs only inside the built image with no network (`test/tools.Dockerfile:11:RUN --network=none`).
- The program `docker` is NOT_IN_RUNNER for the step: the image holds no Docker engine, and a Job pod has no capability and a read-only root, so the build, the image test and the scans run on the `ubuntu-24.04` and `ubuntu-24.04-arm` runners of the Image workflow.
- The commands `cargo`, `rustc`, `rustdoc`, `rustfmt`, `cargo-clippy`, `cargo-fmt`, `gcc` and `ansible-lint` exist only in the image that the plan builds; the failure class of a missing command is exit 127, which `run` of `test/tools.sh` reports with the name of the command and which fails the image test.

## Existing Tool Considered

The Rust toolchain comes from jdx/mise (MIT, maintained), which pins one toolchain in `mise.toml` and installs it through rustup, the upstream installer of Rust. The C linker is the `gcc` of Debian sid, as in the official Rust images. ansible-lint (GPL-3.0-or-later, maintained by the Ansible project) is the upstream linter from PyPI, installed with uv from a hashed requirement file of the image. The change builds no code of its own and deletes no code.

## Dependencies

None.
