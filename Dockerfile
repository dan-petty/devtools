# syntax=docker/dockerfile:1.29.0@sha256:572cebbc2b15e6f84c077742952674889cb63cd5e9b80abdffcbe587b6f19183
# check=error=true

# The devtools image: Debian sid with the development tools of devops-cli. Each tool comes from one
# source, and README.md names it: apt for a tool that sid has at a current version, the mise image
# for mise, the uv image for uv and uvx, mise.lock for each other binary tool, the hashed
# requirement files of python/ for the Python tools, and npm/package-lock.json for the Node tools.
# The image is for linux/amd64 and linux/arm64, and the Dockerfile has no code for one platform. A
# tool with no build for the platform stops the build.
# The image has no login user: each consumer adds its own user.

FROM debian:sid@sha256:06889db0e48042b40d026b4505858812e4cb29f5cf7822189bb5be6522b4bee0 AS sid
FROM jdxcode/mise:2026.11.14@sha256:7178a0bc7eb30d5090f81237fc0a7830f57e52126b9d8df656e24547437a1e53 AS mise
FROM ghcr.io/astral-sh/uv:0.13.10@sha256:a3ea1357342c1a4bf9a0c53a3deb1b55379aefa037338d8113d5771efa01774f AS uv

# The binary tools of mise.toml. `mise install --locked` downloads each tool from the URL in
# mise.lock and checks its checksum, with the retries of the mise `http_retries` setting. The step
# copies each command as a real file to /out/bin, so that a consumer can `COPY --from` one command.
# An archive can hold more than its command (prometheus beside promtool), so the step copies the
# commands by name, and test/manifests.sh checks that the loop names each tool of mise.toml.
# The step makes no GitHub API request, so it gets no credential. The step mounts mise from the
# mise image.
FROM sid AS mise-tools
COPY --from=mise /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
WORKDIR /src
# mise sends a request to mise-versions.jdx.dev for each tool that it installs. DO_NOT_TRACK does
# not stop these requests; MISE_USE_VERSIONS_HOST_TRACK=0 stops them.
ENV MISE_USE_VERSIONS_HOST_TRACK=0
RUN --mount=type=bind,from=mise,source=/usr/local/bin/mise,target=/usr/local/bin/mise \
    --mount=type=bind,source=mise.toml,target=/src/mise.toml \
    --mount=type=bind,source=mise.lock,target=/src/mise.lock \
    export MISE_DATA_DIR=/tmp/mise MISE_CACHE_DIR=/tmp/mise/cache MISE_YES=1 \
    && mise install --locked \
    && mkdir -p /out/bin \
    && for command in actionlint argo argocd cloudflared gh gh-dash gitleaks golangci-lint \
         hadolint helm k9s kube-linter kubeconform kubectl kubectl-argo-rollouts kustomize \
         minikube osv-scanner pluto popeye promtool pv-migrate tflint tofu trivy tuicr vale \
         weaver; do \
         install -m 0755 "$(mise which "$command")" "/out/bin/$command" || exit 1; \
       done \
    && rm -rf /tmp/mise

# The apt packages. Each one floats with sid, and the scheduled rebuild takes their updates:
# `apt-get upgrade` also updates the packages of the base image. The packages have no version pins
# (hadolint DL3008). The step removes the package lists in its layer, and the docker-clean
# configuration of the Debian image removes the downloaded packages. The step has no cache mount: a
# cache mount on /var/lib/apt keeps /var/lib/apt/extended_states out of the layer, and apt then
# marks each package as manual. The CI keeps no build cache, so a cache mount makes no build faster.
# Podman takes the place of Docker, so the image has no Docker engine. dbus-x11 gives gnome-keyring
# its session bus.
FROM sid AS base
ARG DEBIAN_FRONTEND=noninteractive
# hadolint ignore=DL3008
RUN apt-get update \
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
       make \
       mtr-tiny \
       netcat-openbsd \
       nodejs \
       npm \
       passt \
       podman \
       python-is-python3 \
       python3-ansible-runner \
       python3.14 \
       python3.15 \
       shellcheck \
       skopeo \
       socat \
       sudo \
       tcpdump \
       traceroute \
       uidmap \
       unzip \
       zsh \
    && rm -rf /var/lib/apt/lists/*

# The Python tools, each in a virtual environment of its own. `--require-hashes` refuses a
# distribution that the requirement file does not name with its hash. `UV_NO_BUILD` refuses to
# build a distribution from source, so a package with no wheel for the platform fails the build.
# uv makes a .lock file in each environment that all users can write. The image does not use the
# lock files after the sync, so the step removes them.
FROM base AS python-tools
RUN --mount=type=bind,from=uv,source=/uv,target=/usr/local/bin/uv \
    --mount=type=bind,source=python,target=/tmp/python \
    --mount=type=cache,target=/root/.cache/uv \
    export UV_PYTHON_DOWNLOADS=never UV_LINK_MODE=copy UV_COMPILE_BYTECODE=1 UV_NO_BUILD=1 \
    && for tool in ansible-lint copier pre-commit semgrep; do \
         uv venv --python /usr/bin/python3.14 "/usr/local/lib/devtools/$tool" \
         && uv pip sync --require-hashes --python "/usr/local/lib/devtools/$tool/bin/python" \
              "/tmp/python/$tool.txt" \
         || exit 1; \
       done \
    && rm -f /usr/local/lib/devtools/*/.lock

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
# The settings of the tools for each consumer image: no telemetry, no update notice and no
# self-update. A tool of the image gets a new version only with a new image. DO_NOT_TRACK does not
# stop the install report of mise; MISE_USE_VERSIONS_HOST_TRACK=0 stops it.
ENV DO_NOT_TRACK=1 \
    OPENSPEC_TELEMETRY=0 \
    OPENSPEC_NO_UPDATE_CHECK=1 \
    GH_NO_UPDATE_NOTIFIER=1 \
    npm_config_update_notifier=false \
    COPILOT_AUTO_UPDATE=false \
    DISABLE_AUTOUPDATER=1 \
    MISE_USE_VERSIONS_HOST_TRACK=0 \
    MISE_DISABLE_UPDATE_WARNING=1 \
    SEMGREP_SEND_METRICS=off \
    SEMGREP_ENABLE_VERSION_CHECK=0
COPY --from=uv /uv /uvx /usr/local/bin/
# mise is the tool installer of the repositories that pin their tools in a mise.toml. It is a
# static binary. mise reads the instructions file below from the lib folder of its prefix: the
# file turns off `mise self-update` for each user, and mise prints its message in place of the
# update.
COPY --from=mise /usr/local/bin/mise /usr/local/bin/mise
RUN mkdir /usr/local/lib/mise \
    && printf 'message = "The devtools image installs mise. To get a newer mise, use a newer image."\n' \
       > /usr/local/lib/mise/mise-self-update-instructions.toml
COPY --from=mise-tools /out/bin/ /usr/local/bin/
COPY --from=python-tools /usr/local/lib/devtools/ /usr/local/lib/devtools/
COPY --from=npm-tools /usr/local/lib/devtools/npm/ /usr/local/lib/devtools/npm/
# The commands of the Python and Node tools go on PATH.
RUN ln -s ../lib/devtools/ansible-lint/bin/ansible-lint \
          ../lib/devtools/copier/bin/copier \
          ../lib/devtools/pre-commit/bin/pre-commit \
          ../lib/devtools/semgrep/bin/semgrep \
          ../lib/devtools/semgrep/bin/pysemgrep \
          ../lib/devtools/npm/node_modules/.bin/claude \
          ../lib/devtools/npm/node_modules/.bin/copilot \
          ../lib/devtools/npm/node_modules/.bin/devcontainer \
          ../lib/devtools/npm/node_modules/.bin/openspec \
          ../lib/devtools/npm/node_modules/.bin/style-dictionary \
          /usr/local/bin/
