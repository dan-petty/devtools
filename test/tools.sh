#!/usr/bin/env bash
# Runs each tool of the image once and prints its version. A tool that is missing, that does not
# start or that runs for more than 60 s fails the test with its name. Then the script checks the
# state of the image. test/tools.Dockerfile runs this script in the image with no network.
set -euo pipefail

# The timeout of each command is shorter than the timeout of the CI step.
run() {
  echo "+ $*"
  local status=0
  timeout --kill-after=5s 60s "$@" || status=$?
  if [ "$status" -eq 124 ]; then
    echo "FAIL: $1 did not stop in 60 s" >&2
  elif [ "$status" -ne 0 ]; then
    echo "FAIL: $1 exited with status $status" >&2
  fi
  return "$status"
}

# apt
run ansible --version
run ansible-runner --version
run bandit --version
run buildah --version
run bwrap --version
run crun --version
run curl --version
run fuse-overlayfs --version
run git --version
run gnome-keyring-daemon --version
run jq --version
run make --version
run mtr --version
run node --version
run npm --version
run passt --version
run ping -V
run podman --version
run python --version
run python3.14 --version
run python3.15 --version
run shellcheck --version
run skopeo --version
run socat -V
run sudo --version
run tcpdump --version
run tracepath -V
run traceroute --version
run unzip -v
run zsh --version
# These commands have no version option. `containers-storage version` needs privileges that the
# build does not have, so the test checks only that the command is present.
for command in containers-storage dbus-launch nc newgidmap newuidmap; do
  echo "+ command -v $command"
  if ! command -v "$command"; then
    echo "FAIL: $command is missing" >&2
    exit 1
  fi
done

# The tools of mise.lock
run actionlint --version
run argo version --short
run argocd version --client --short
run cloudflared --version
run gh --version
run gh-dash --version
run gitleaks version
run golangci-lint --version
run hadolint --version
run helm version
run k9s version --short
run kube-linter version
run kubeconform -v
run kubectl version --client
run kubectl-argo-rollouts version --short
run kustomize version
run minikube version
run osv-scanner --version
run pluto version
run popeye version
run promtool --version
run pv-migrate --version
run tflint --version
run tofu --version
run trivy --version
run tuicr --version
run vale --version
run weaver --version

# mise, uv and uvx, each from its official image
run mise --version
run uv --version
run uvx --version
run ansible-lint --version
run copier --version
run pre-commit --version
# With no network, the version check of semgrep waits 98 s for its timeout.
run semgrep --disable-version-check --version

# npm
run claude --version
run copilot --version
run devcontainer --version
run openspec --version
run style-dictionary --version

# The state of the image. apt keeps the automatic mark of each dependency, so that
# `apt-get autoremove` can find the packages that no package needs. Most packages of the image are
# dependencies. When a cache mount hid /var/lib/apt/extended_states, apt marked only 77 of 764
# packages as automatic.
echo "+ apt-mark showauto | wc -l"
automatic=$(apt-mark showauto | wc -l)
echo "$automatic"
if [ "$automatic" -le 100 ]; then
  echo "FAIL: apt marks only $automatic packages as automatic" >&2
  exit 1
fi
run apt-get --simulate autoremove

# mise gets a new version only with a new image, and it sends no install report. `mise doctor`
# exits with a status that is not 0 when it has a warning, so the test reads only its report.
echo "+ mise doctor | grep self_update_available"
self_update=$(timeout --kill-after=5s 60s mise doctor 2>&1 | grep '^self_update_available:' || true)
echo "$self_update"
if [ "$self_update" != "self_update_available: no" ]; then
  echo "FAIL: mise can update itself in the image" >&2
  exit 1
fi
echo "+ mise settings get use_versions_host_track"
track=$(timeout --kill-after=5s 60s mise settings get use_versions_host_track)
echo "$track"
if [ "$track" != "false" ]; then
  echo "FAIL: mise sends an install report: MISE_USE_VERSIONS_HOST_TRACK is '${MISE_USE_VERSIONS_HOST_TRACK-}'" >&2
  exit 1
fi

# uv makes a lock file in each virtual environment that all users can write.
echo "+ find /usr/local/lib/devtools -name .lock -perm -002"
writable=$(find /usr/local/lib/devtools -name .lock -perm -002)
if [ -n "$writable" ]; then
  echo "FAIL: all users can write these lock files: $writable" >&2
  exit 1
fi
