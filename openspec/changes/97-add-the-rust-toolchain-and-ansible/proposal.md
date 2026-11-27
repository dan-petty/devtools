# Proposal

## Why

The runner image has no Rust toolchain and no ansible-lint, so the implement job of dan-petty/devops-cli#4648 cannot run its presets for Rust and Ansible repositories, and its runner image builds FROM this image. #97 adds cargo, rustc, rustfmt, clippy and ansible-lint to the image, each with a version check, so a release of the image lets that job add the RUNNER_TOOLS rows.

## What Changes

- Pin the `rust` tool in `mise.toml` and lock its entry for `linux-x64` and `linux-arm64` in `mise.lock`.
- Copy the toolchain folder of the cargo command into `/usr/local/lib/devtools/rust` and link `cargo`, `rustc`, `rustfmt`, `cargo-clippy` and `cargo-fmt` into `/usr/local/bin`, so that `rustc` finds `lib/rustlib` beside its binary.
- Teach `test/manifests.sh` that the `rust` key provides five commands, print one command name per line from each `case` arm, read the five names from the `rust/bin` targets of the `ln -s` list, and add no second `for command in` loop to the `Dockerfile`.
- Install `ansible-lint` as the fourth Python tool from the hashed requirement file `python/ansible-lint.txt`.
- Print the version of each new command in `test/tools.sh`, in the block of its installer.
- Scan `python/ansible-lint.txt` in the `osv-scanner` step of the Image workflow, so that a finding in the new lock file fails the gate.
- Document in `README.md` the mise tool that provides several commands from one folder.
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

## Feasibility

- The probe lines confirm the premise word for word: "The path `mise.toml` is a file of the staging commit.", "The path `test/tools.sh` is a file of the staging commit.", "The path `mise.lock` is a file of the staging commit.", "The path `test/tools.Dockerfile` is a file of the staging commit." and "The path `test/trivy.sh` is a file of the staging commit."
- The probe shows that the image holds no Rust command: "`cargo` has no definition at the staging commit. No commit in the history added or removed its text." The probe reached its bound of 10 commands before `rustc`, `clippy`, `rustfmt`, `ansible-lint` and `RUNNER_TOOLS`, so their absence is not checked by the probe.
- The run's `references` search for `ansible-lint` answered "No line of the commit holds 'ansible-lint'.", so no file of the commit names the new Python tool, and the `RUNNER_TOOLS` rows belong to the other repository.
- The run's `read_file` of `mise.toml` lists 27 tool keys, from `mise.toml:7:argo = "4.1.7"` to `mise.toml:36:vale = "3.29.0"`, and the run's `read_file` of `Dockerfile` lists 27 command names in the copy loop at `Dockerfile:35:for command in`; group 1 adds the `rust` key and group 2 adds its five command names, so the check compares 32 names on each side.
- The review finding is right about the script as it stands: `test/manifests.sh:22:echo "$command"` prints one line per tool key, so a `case` arm for `rust` alone would give one line and `test/manifests.sh:31:missing=$(comm -23 <(echo "$expected") <(echo "$copied"))` would report the five Rust commands missing. Group 2 gives each `case` arm its own `echo` or `printf`, so the `rust` arm prints the five names one per line, and adds the five names of the `rust/bin` targets of the `ln -s` list to the copied set; the two sides then hold 32 names each, and group 2 stops when `bash test/manifests.sh` fails.
- The image installs each binary tool from the lock file and copies one command per file: `Dockerfile:33:mise install --locked` and `Dockerfile:38:install -m 0755 "$(mise which "$command")" "/out/bin/$command"`, so a toolchain that keeps `lib/rustlib` beside `bin/` needs its folder copied and its commands linked.
- The last stage shows the pattern of a copied tool folder with linked commands: `Dockerfile:149:COPY --from=mise-tools /out/bin/ /usr/local/bin/`, `Dockerfile:150:COPY --from=python-tools /usr/local/lib/devtools/ /usr/local/lib/devtools/` and `Dockerfile:153:ln -s ../lib/devtools/copier/bin/copier`, whose target folder `Dockerfile:162:/usr/local/bin/` is the last word of the same `ln -s` command.
- The copy loop is one `for command in` loop, and `test/manifests.sh` cuts the joined `Dockerfile` at the last loop: `test/manifests.sh:27:sed -n '/for command in/,/; do/p' Dockerfile` and `test/manifests.sh:28:s/.*for command in//`, so the plan adds no second loop and reads the five linked Rust names from the `ln -s` list.
- `test/manifests.sh` maps a tool key to a command with a case arm, as `test/manifests.sh:19:argo-rollouts) command=kubectl-argo-rollouts ;;` shows, and it reads the keys of `mise.toml` with `test/manifests.sh:11:tomllib.load(open(sys.argv[1], "rb"))["tools"]`; the message that prints the count is `test/manifests.sh:42:tools of mise.toml.`, so group 2 counts the commands of the links as well as the tools of `mise.toml`.
- The Python tools come from hashed requirement files, one environment each: `Dockerfile:103:for tool in copier pre-commit semgrep; do`, `Dockerfile:105:uv pip sync --require-hashes` and `Dockerfile:153:ln -s ../lib/devtools/copier/bin/copier`; `README.md:93:Each Python tool has a virtual environment of its own` states the layout, so the image holds no uv tool environment.
- The build context holds the `python` folder: `Dockerfile:100:--mount=type=bind,source=python,target=/tmp/python`, and the README names the manager of a `python/<tool>.txt` file: `README.md:84:pip-compile`.
- The README procedure for a mise tool is `README.md:100:mise use <tool>@<version>`, a lock with `mise lock`, the command in the copy loop, and `README.md:104:Then add` for the version check; the plan adds the case of a tool that provides several commands from one folder.
- The Image workflow is the live check of the image: it runs `bash test/manifests.sh` (`.github/workflows/image.yml:109:run: bash test/manifests.sh`), builds the image (`.github/workflows/image.yml:167:docker buildx build --builder default --no-cache --output type=cacheonly`) and runs the image test, and it runs `test/trivy.sh` on the built image.
- The osv-scanner step is the gate of the new lock file: `.github/workflows/image.yml:176:The gate of the image` and `.github/workflows/image.yml:184:--lockfile requirements.txt:python/copier.txt`; `python/osv-scanner.toml` holds the ignores of that folder, and the run's `read_file` of it shows that each ignore names a finding of semgrep, so the new lock file needs no ignore before the scan runs.
- The Trivy step does not gate: `.github/workflows/image.yml:206:The scan is report-only` and `.github/workflows/image.yml:210:The gate stays on the lock files`, so the new lock file joins the osv-scanner step.
- The workflow publishes only a tag: `.github/workflows/image.yml:27:The release that the run publishes`, so a person publishes the release after the merge and the plan writes no code for it.
- `mise.lock` keeps its format: `mise.lock:3:lockfile_version = 4`, and the constant `lockfile_version` holds 4; no group renames that constant.
- The run's `list_files` of the top of the commit returned no `src/` folder and no `tests/` folder, and the run's `list_files` of `openspec` returned only `openspec/config.yaml`, so the repository holds no Python package under `src/` and no living spec; a behavior group MUST change a `.py` file under `src/`, so no added scenario can have a behavior task and the live image build, `test/manifests.sh` and `test/tools.sh` in the built image are the proofs of this change.
- The run's `find_issues` for `rust ansible-lint image mise` listed only #97, and the run's `read_issue` of 4648 answered "GitHub holds no issue or pull request #4648.", so `dan-petty/devops-cli#4648` is a reference to the other repository and the plan depends on no open item of this one.
- Not checked: whether the mise registry holds a `rust` tool, what layout the folder of the cargo command has, whether `mise lock` writes a URL and a sha256 checksum for that tool on both platforms, and whether the image test of `test/tools.sh` passes with the new commands; the run ran no command, built no image and fetched no mise registry page.
- The estimate of `python/ansible-lint.txt` is 1000 lines from the run's `references` search for `--hash=sha256`, which counted 1463 lines in the 3 lock files of `python/`, 939 of them in the longest.
- The first checks against the real system are these, in order: `mise use rust@<newest stable release>` in a scratch folder, which shows whether the registry holds a `rust` tool; `mise lock --platform linux-x64,linux-arm64` and a check of the `tools.rust` entry of `mise.lock` for a URL and a sha256 checksum on both platforms; `bash test/manifests.sh`, which fails until the `Dockerfile` links the five Rust commands; `uv pip compile --universal --generate-hashes --python-version=3.14 ansible-lint.in --output-file=ansible-lint.txt` in `python/`; `docker buildx build --tag devtools:test --load .` with `docker run --rm devtools:test cargo --version`, `docker run --rm devtools:test rustc --version`, `docker run --rm devtools:test cargo clippy --version`, `docker run --rm devtools:test cargo fmt --version` and `docker run --rm devtools:test ansible-lint --version`; and `docker buildx build --builder default --no-cache --output type=cacheonly --build-arg DEVTOOLS=devtools:test --file test/tools.Dockerfile test`.
- The command `mise lock --platform linux-x64,linux-arm64` needs a network: it resolves the Rust release and writes the entry of each platform.
- The command `mise install --locked` of the image build needs a network: it downloads each tool from the URL in `mise.lock`.
- The command `mise which cargo` needs the toolchain that `mise install --locked` installed in the same `RUN` step, so it runs inside the `mise-tools` stage and not in a step.
- The command `uv pip compile --universal --generate-hashes --python-version=3.14` needs a network: it resolves each distribution and its hashes from PyPI.
- The command `uv pip sync --require-hashes` of the `python-tools` stage needs a network: it downloads each wheel from PyPI.
- The command `osv-scanner scan source` needs a network: it downloads the OSV database.
- The script `test/manifests.sh` needs a checkout of the repository: it reads `mise.toml` and the command lists of the `Dockerfile`.
- The command `docker buildx build` needs a client of a Docker daemon: it builds and loads the image on the host.
- The script `test/trivy.sh` needs a client of a Docker daemon and a network: it runs the Trivy of the image and downloads its databases.
- The script `test/tools.sh` runs only inside the built image with no network, as `test/tools.Dockerfile:11:RUN --network=none` shows, and it needs `bash` and the commands of the image.
- The program `bash` and the programs `python3`, `sed`, `tr`, `sort` and `comm` that `test/manifests.sh` needs come from the runner image; the failure class of a missing one is exit 127, which stops the step, and the step needs a checkout of the repository.
- The program `docker` is NOT_IN_RUNNER for the step: the image holds no Docker engine, and a Job pod has no capability and a read-only root, so the build, the image test and the scan run on the `ubuntu-24.04` and `ubuntu-24.04-arm` runners of the Image workflow.
- The program `mise` is NOT_IN_RUNNER for the step: the runner tool list holds no `mise`, and the image gets it from the mise image at `Dockerfile:13:FROM jdxcode/mise:2026.11.14@sha256:7178a0bc7eb30d5090f81237fc0a7830f57e52126b9d8df656e24547437a1e53 AS mise`, so `mise lock` and `mise install --locked` run on a workstation or in the Image workflow.
- The commands `cargo`, `rustc`, `cargo-clippy`, `cargo-fmt` and `ansible-lint` exist only in the image that the plan builds; the failure class of a missing command is exit 127, which `run` of `test/tools.sh` reports with the name of the command and which fails the image test.

## Existing Tool Considered

The Rust toolchain comes from jdx/mise (MIT, maintained), which pins one toolchain in `mise.toml` and locks its entry in `mise.lock`, and the alternatives block of the issue records that mise supplies cargo, rustc, rustfmt and clippy. ansible-lint is the upstream linter from PyPI, installed with uv from a hashed requirement file of the image. The change builds no code of its own.

## Dependencies

None.
