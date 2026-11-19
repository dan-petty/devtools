# syntax=docker/dockerfile:1.29.0@sha256:572cebbc2b15e6f84c077742952674889cb63cd5e9b80abdffcbe587b6f19183
# check=error=true

# The devtools image: Debian sid with the development tools of devops-cli. Each tool comes from one
# source, and README.md names it: apt for a tool that sid has at a current version, mise.lock for
# each other binary tool, the hashed requirement files of python/ for the Python tools, and
# npm/package-lock.json for the Node tools. The image is for linux/amd64 and linux/arm64, and the
# Dockerfile has no code for one platform. A tool with no build for the platform stops the build.
# The image has no login user: each consumer adds its own user.

FROM debian:sid@sha256:e276677157e13bc51ea5b8651f54ad28883f503cc37b3e3af2c4b6cc2f4efe7b AS sid
FROM jdxcode/mise:2026.11.10@sha256:80aa2afb17ba760cabe74ac90771ca2d1470773d514cc2bb79c69c8d3f92f150 AS mise
FROM ghcr.io/astral-sh/uv:0.13.9@sha256:d3b601f0c7b118bc1753febf7c41cc80981df678445e0254284eecf84db79a7d AS uv

# The binary tools of mise.toml. `mise install --locked` downloads each tool from the URL in
# mise.lock and checks its checksum, with the retries of the mise `http_retries` setting. The step
# copies each command as a real file to /out/bin, so that a consumer can `COPY --from` one command.
# An archive can hold more than its command (prometheus beside promtool), so the step copies the
# commands by name. GITHUB_TOKEN is optional; it raises the GitHub API rate limit of mise.
FROM sid AS mise-tools
COPY --from=mise /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
WORKDIR /src
RUN --mount=type=bind,from=mise,source=/usr/local/bin/mise,target=/usr/local/bin/mise \
    --mount=type=bind,source=mise.toml,target=/src/mise.toml \
    --mount=type=bind,source=mise.lock,target=/src/mise.lock \
    --mount=type=secret,id=github_token,env=GITHUB_TOKEN \
    export MISE_DATA_DIR=/tmp/mise MISE_CACHE_DIR=/tmp/mise/cache MISE_YES=1 \
    && mise install --locked \
    && mkdir -p /out/bin \
    && for command in actionlint argo argocd cloudflared gh gh-dash gitleaks golangci-lint \
         hadolint helm k9s kube-linter kubeconform kubectl kubectl-argo-rollouts kustomize \
         minikube osv-scanner pluto popeye promtool tflint tofu trivy tuicr vale weaver; do \
         install -m 0755 "$(mise which "$command")" "/out/bin/$command" || exit 1; \
       done \
    && rm -rf /tmp/mise

# The apt packages. Each one floats with sid, and the scheduled rebuild takes their updates:
# `apt-get upgrade` also updates the packages of the base image. The packages have no version pins
# (hadolint DL3008). The step uses the apt cache pattern of the Docker documentation: the cache
# mounts keep the package lists and the downloaded packages out of the image. Podman takes the
# place of Docker, so the image has no Docker engine. dbus-x11 gives gnome-keyring its session bus.
FROM sid AS base
ARG DEBIAN_FRONTEND=noninteractive
RUN rm -f /etc/apt/apt.conf.d/docker-clean \
    && echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache
# hadolint ignore=DL3008
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
       ansible-core \
       bandit \
       bubblewrap \
       buildah \
       ca-certificates \
       containers-storage \
       crun \
       curl \
       dbus-x11 \
       fuse-overlayfs \
       git \
       gnome-keyring \
       iputils-ping \
       iputils-tracepath \
       jq \
       mtr-tiny \
       netcat-openbsd \
       nodejs \
       npm \
       passt \
       podman \
       python-is-python3 \
       python3-ansible-runner \
       python3.14 \
       shellcheck \
       skopeo \
       socat \
       sudo \
       tcpdump \
       traceroute \
       uidmap \
       unzip \
       zsh

# The Python tools, each in a virtual environment of its own. `--require-hashes` refuses a
# distribution that the requirement file does not name with its hash. `UV_NO_BUILD` refuses to
# build a distribution from source, so a package with no wheel for the platform fails the build.
FROM base AS python-tools
RUN --mount=type=bind,from=uv,source=/uv,target=/usr/local/bin/uv \
    --mount=type=bind,source=python,target=/tmp/python \
    --mount=type=cache,target=/root/.cache/uv \
    export UV_PYTHON_DOWNLOADS=never UV_LINK_MODE=copy UV_COMPILE_BYTECODE=1 UV_NO_BUILD=1 \
    && for tool in pre-commit semgrep; do \
         uv venv --python /usr/bin/python3.14 "/usr/local/lib/devtools/$tool" \
         && uv pip sync --require-hashes --python "/usr/local/lib/devtools/$tool/bin/python" \
              "/tmp/python/$tool.txt" \
         || exit 1; \
       done

# The Node tools. `npm ci` installs the lockfile, and npm checks the sha512 of each package.
# `--ignore-scripts` runs no install script. From the optional dependencies of a package, npm
# installs only the native package of the build platform. Then `npm rebuild` runs one install
# script, that of Claude Code, which `allowScripts` of package.json approves: the script links the
# native binary of the platform in place of the bin/claude.exe placeholder. The script does not
# fail when the native package is missing, so `claude --version` fails the build.
FROM base AS npm-tools
WORKDIR /usr/local/lib/devtools/npm
COPY npm/package.json npm/package-lock.json ./
RUN --mount=type=cache,target=/root/.npm \
    npm ci --ignore-scripts --no-audit --no-fund \
    && npm rebuild @anthropic-ai/claude-code \
    && node_modules/.bin/claude --version

FROM base AS devtools
COPY --from=uv /uv /uvx /usr/local/bin/
COPY --from=mise-tools /out/bin/ /usr/local/bin/
COPY --from=python-tools /usr/local/lib/devtools/ /usr/local/lib/devtools/
COPY --from=npm-tools /usr/local/lib/devtools/npm/ /usr/local/lib/devtools/npm/
# The commands of the Python and Node tools go on PATH.
RUN ln -s ../lib/devtools/pre-commit/bin/pre-commit \
          ../lib/devtools/semgrep/bin/semgrep \
          ../lib/devtools/semgrep/bin/pysemgrep \
          ../lib/devtools/npm/node_modules/.bin/claude \
          ../lib/devtools/npm/node_modules/.bin/copilot \
          ../lib/devtools/npm/node_modules/.bin/devcontainer \
          ../lib/devtools/npm/node_modules/.bin/openspec \
          ../lib/devtools/npm/node_modules/.bin/style-dictionary \
          /usr/local/bin/ \
    && rm /etc/apt/apt.conf.d/keep-cache
# A consumer image runs apt with the configuration of the Debian image.
COPY --from=sid /etc/apt/apt.conf.d/docker-clean /etc/apt/apt.conf.d/docker-clean
