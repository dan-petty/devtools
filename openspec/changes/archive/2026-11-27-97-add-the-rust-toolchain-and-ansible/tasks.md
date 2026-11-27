# Tasks

## 1. Install ansible-lint from a hashed requirement file

Kind: other. Reads: `Dockerfile`, `python/copier.in`, `python/osv-scanner.toml`, `README.md`. Changes: `python/ansible-lint.in` (new), `python/ansible-lint.txt` (new), `Dockerfile`, `python/osv-scanner.toml` (only for a finding that no release fixes).

- [x] 1.1 Write `python/ansible-lint.in` with `ansible-lint==<newest release>` and, in `python/`, run `uv pip compile --universal --generate-hashes --python-version=3.14 ansible-lint.in --output-file=ansible-lint.txt`. In the `python-tools` stage of the `Dockerfile`, change the loop to `for tool in ansible-lint copier pre-commit semgrep; do`. Add `../lib/devtools/ansible-lint/bin/ansible-lint` as the first line of the `ln -s` list of the last stage, and run this check by hand: 1. Run `osv-scanner scan source --lockfile requirements.txt:python/ansible-lint.txt` (the devtools image has osv-scanner): it reads `python/osv-scanner.toml`. 2. For a finding with a released fix, raise the pin in `python/ansible-lint.in` or add the fixed version of the package to it, compile again and scan again. 3. For a finding that no released version fixes, add one narrow ignore to `python/osv-scanner.toml` by the rule of its header (reason, tracking issue, end date 3 days ahead) and file the tracking issue. The scan of step 1 MUST then exit 0. 4. Run `docker buildx build --tag devtools:test --load .` and `docker run --rm --network=none devtools:test ansible-lint --version`: it MUST print the version and exit 0. The warning "PATH altered to include" is expected. 5. Run `docker run --rm -v "$PWD:/src:ro" -w /src devtools:test hadolint Dockerfile test/*.Dockerfile`: it MUST exit 0. Stop and comment the evidence on the issue when a step fails.

## 2. Check ansible-lint in the image test

Kind: other. Reads: `test/tools.sh`, `test/tools.Dockerfile`. Changes: `test/tools.sh`.

- [x] 2.1 In `test/tools.sh`, add `run ansible-lint --version` before `run copier --version`, and run this check by hand: 1. Run the image test `docker buildx build --builder default --no-cache --output type=cacheonly --build-arg DEVTOOLS=devtools:test --file test/tools.Dockerfile test`: it MUST exit 0 and print the version of `ansible-lint`. 2. Run `docker run --rm -v "$PWD:/src:ro" -w /src devtools:test shellcheck test/*.sh`: it MUST exit 0.

## 3. Scan the ansible-lint lock file in the Image workflow

Kind: other. Reads: `.github/workflows/image.yml`, `python/osv-scanner.toml`. Changes: `.github/workflows/image.yml`.

- [x] 3.1 Add `--lockfile requirements.txt:python/ansible-lint.txt` to the `osv-scanner scan source` step of `.github/workflows/image.yml`, after the lock file of semgrep, and run this check by hand: 1. Run `docker run --rm -v "$PWD:/src:ro" -w /src devtools:test actionlint`: it MUST exit 0. 2. Run `docker run --rm -v "$PWD:/src:ro" -w /src ghcr.io/zizmorcore/zizmor:1.33.1 --offline .github/workflows`: it MUST exit 0. 3. Run the command of the step: `docker run --rm -v "$PWD:/src:ro" -w /src devtools:test osv-scanner scan source --lockfile npm/package-lock.json --lockfile requirements.txt:python/copier.txt --lockfile requirements.txt:python/pre-commit.txt --lockfile requirements.txt:python/semgrep.txt --lockfile requirements.txt:python/ansible-lint.txt`: it MUST exit 0. From 2026-11-30, the semgrep ignores of `python/osv-scanner.toml` have ended: when the step names only findings of `python/semgrep.txt`, that is the failure of Issue #2 and not of this item. Then add no ignore here, comment the evidence on the issue, and stop.

## 4. Document the scan of a new Python lock file and the sid version of ansible-lint

Kind: other. Reads: `README.md`, `.github/workflows/image.yml`. Changes: `README.md`.

- [x] 4.1 In the Python bullet of the "Change a tool" section of `README.md` (`README.md:101`), add the sentence "Add `--lockfile requirements.txt:python/<tool>.txt` to the `osv-scanner` step of `.github/workflows/image.yml`." after the sentence on the loop and the links. In the apt rule (`README.md:74`), add "On 2026-11-27, sid had ansible-lint 26.4.0 (upstream 26.11.1)." after the sentence of 2026-11-22, and run this check by hand: 1. Run `grep -n 'requirements.txt:python/<tool>.txt' README.md`: it MUST print a line. 2. Run `grep -n 'ansible-lint 26.4.0' README.md`: it MUST print a line.
