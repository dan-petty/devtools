# syntax=docker/dockerfile:1.29.0@sha256:572cebbc2b15e6f84c077742952674889cb63cd5e9b80abdffcbe587b6f19183
# check=error=true

# Runs test/tools.sh in the devtools image with no network: each tool prints its version once. The
# CI sets DEVTOOLS to the image that it built, and on main to the digest that it pushed.
ARG DEVTOOLS=ghcr.io/dan-petty/devtools:latest
FROM ${DEVTOOLS}
RUN --network=none --mount=type=bind,source=tools.sh,target=/test/tools.sh bash /test/tools.sh
