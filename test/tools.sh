#!/usr/bin/env bash
# Runs each tool of the image once and prints its version. A tool that is missing or that does not
# start fails the test. The CI runs it in the image with no network:
#   docker run --rm --network none -v "$PWD/test:/test:ro" devtools:test bash /test/tools.sh
set -euo pipefail
set -x

# apt
ansible --version
ansible-runner --version
bandit --version
buildah --version
bwrap --version
crun --version
curl --version
fuse-overlayfs --version
git --version
gnome-keyring-daemon --version
jq --version
mtr --version
node --version
npm --version
passt --version
ping -V
podman --version
python --version
python3.14 --version
shellcheck --version
skopeo --version
socat -V
sudo --version
tcpdump --version
tracepath -V
traceroute --version
unzip -v
zsh --version
# These commands have no version option.
command -v dbus-launch nc newgidmap newuidmap

# mise
actionlint --version
argo version --short
argocd version --client --short
cloudflared --version
gh --version
gh-dash --version
gitleaks version
golangci-lint --version
hadolint --version
helm version
k9s version --short
kube-linter version
kubeconform -v
kubectl version --client
kubectl-argo-rollouts version --short
kustomize version
minikube version
osv-scanner --version
pluto version
popeye version
promtool --version
tflint --version
tofu --version
trivy --version
tuicr --version
vale --version

# uv and the Python tools
uv --version
uvx --version
pre-commit --version
semgrep --version

# npm
claude --version
copilot --version
devcontainer --version
openspec --version
style-dictionary --version
