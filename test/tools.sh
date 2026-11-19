#!/usr/bin/env bash
# Runs each tool of the image once and prints its version. A tool that is missing, that does not
# start or that runs for more than 60 s fails the test with its name. test/tools.Dockerfile runs
# this script in the image with no network.
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
run mtr --version
run node --version
run npm --version
run passt --version
run ping -V
run podman --version
run python --version
run python3.14 --version
run shellcheck --version
run skopeo --version
run socat -V
run sudo --version
run tcpdump --version
run tracepath -V
run traceroute --version
run unzip -v
run zsh --version
# These commands have no version option.
command -v dbus-launch nc newgidmap newuidmap

# mise
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
run tflint --version
run tofu --version
run trivy --version
run tuicr --version
run vale --version

# uv and the Python tools
run uv --version
run uvx --version
run pre-commit --version
# With no network, the version check of semgrep waits 98 s for its timeout.
run semgrep --disable-version-check --version

# npm
run claude --version
run copilot --version
run devcontainer --version
run openspec --version
run style-dictionary --version
