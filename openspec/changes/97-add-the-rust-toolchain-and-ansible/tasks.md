# Tasks

## 1. Pin the Rust toolchain in mise.toml and mise.lock

Kind: other. Reads: `mise.toml`, `mise.lock`, `README.md`. Changes: `mise.toml`, `mise.lock`.

- [ ] 1.1 Add `rust = "<newest stable release>"` to the `[tools]` table of `mise.toml` between `promtool` and `tflint`, then run `mise lock --platform linux-x64,linux-arm64` and commit the `tools.rust` entry that it writes to `mise.lock`, which keeps `lockfile_version = 4`, and run this check by hand: Run `mise lock --platform linux-x64,linux-arm64` in a scratch copy of the repository and check the `tools.rust` entry of `mise.lock`: it MUST hold a URL and a sha256 checksum for `linux-x64` and for `linux-arm64`. Stop and comment the evidence on the issue when the entry is missing or holds no URL for a platform.

## 2. Copy the Rust toolchain into the image and teach test/manifests.sh

Kind: other. Reads: `Dockerfile`, `test/manifests.sh`, `mise.toml`. Changes: `Dockerfile`, `test/manifests.sh`.

- [ ] 2.1 In the `mise-tools` stage of the `Dockerfile`, after `mise install --locked` and before `rm -rf /tmp/mise`, copy the toolchain folder with `rust_dir=$(dirname "$(dirname "$(mise which cargo)")") && cp -a "$rust_dir" /out/rust`. In the last stage, copy that folder with `COPY --from=mise-tools /out/rust/ /usr/local/lib/devtools/rust/` and add `../lib/devtools/rust/bin/cargo`, `../lib/devtools/rust/bin/rustc`, `../lib/devtools/rust/bin/rustfmt`, `../lib/devtools/rust/bin/cargo-clippy` and `../lib/devtools/rust/bin/cargo-fmt` to the `ln -s` list, each on a line of its own. In `test/manifests.sh`, give each `case` arm its own `echo` or `printf` so that the `rust` arm prints the five command names one per line, read the five names from the `rust/bin` targets of the `ln -s` list into the copied set, and print the number of tool keys and the number of commands in the message. Add no second `for command in` loop to the `Dockerfile`, and run this check by hand: Run `bash test/manifests.sh`: it MUST exit 0 and report no missing and no extra command; stop and comment the evidence on the issue when it fails. Then run `docker buildx build --tag devtools:test --load .` and `docker run --rm devtools:test cargo --version`, `docker run --rm devtools:test rustc --version`, `docker run --rm devtools:test rustfmt --version`, `docker run --rm devtools:test cargo clippy --version` and `docker run --rm devtools:test cargo fmt --version`; stop when a command prints no version.

## 3. Install ansible-lint from a hashed requirement file

Kind: other. Reads: `Dockerfile`, `python/copier.in`, `python/osv-scanner.toml`. Changes: `python/ansible-lint.in` (new), `python/ansible-lint.txt` (new), `Dockerfile`.

- [ ] 3.1 Write `python/ansible-lint.in` with `ansible-lint==<newest stable release>` and, in `python/`, run `uv pip compile --universal --generate-hashes --python-version=3.14 ansible-lint.in --output-file=ansible-lint.txt`. Add `ansible-lint` to the tool loop of the `python-tools` stage of the `Dockerfile` and `../lib/devtools/ansible-lint/bin/ansible-lint` to the `ln -s` list of the last stage, and run this check by hand: In `python/`, run `uv pip compile --universal --generate-hashes --python-version=3.14 ansible-lint.in --output-file=ansible-lint.txt`, then `docker buildx build --tag devtools:test --load .` and `docker run --rm devtools:test ansible-lint --version`; stop when the command prints no version.

## 4. Check each new command in the image test

Kind: other. Reads: `test/tools.sh`, `mise.toml`. Changes: `test/tools.sh`.

- [ ] 4.1 Add `run cargo --version`, `run cargo clippy --version` and `run cargo fmt --version` after `run argocd version --client --short`, add `run rustc --version` and `run rustfmt --version` after `run promtool --version`, and add `run ansible-lint --version` before `run copier --version` in the block of the Python tools of `test/tools.sh`, and run this check by hand: Build the image test on the built image with `docker buildx build --builder default --no-cache --output type=cacheonly --build-arg DEVTOOLS=devtools:test --file test/tools.Dockerfile test` and check that it exits 0 with a version for `cargo`, `rustc`, `rustfmt`, `cargo clippy`, `cargo fmt` and `ansible-lint`.

## 5. Scan the ansible-lint lock file in the Image workflow

Kind: other. Reads: `.github/workflows/image.yml`, `python/osv-scanner.toml`. Changes: `.github/workflows/image.yml`.

- [ ] 5.1 Add `--lockfile requirements.txt:python/ansible-lint.txt` to the `osv-scanner scan source` step of `.github/workflows/image.yml`, beside the lock files of copier, pre-commit and semgrep
  - Verification: `$ uv run devops ci --check --only actionlint,zizmor` passes

## 6. Document the mise tool that provides several commands

Kind: other. Reads: `README.md`, `mise.toml`, `test/manifests.sh`. Changes: `README.md`.

- [ ] 6.1 State in the paragraph on `mise.lock` of `README.md` and in the mise bullet of the change-a-tool section that a tool whose commands come from one folder is copied with its folder and its commands are linked, and name the `rust` key with its five commands
  - Verification: `$ uv run devops ci docs` passes
- [ ] 6.2 Edit `README.md` in the `mise.lock` paragraph and in the mise bullet of the change-a-tool section for the tool that provides five commands from one folder
  - Verification: `$ uv run devops ci docs` passes
