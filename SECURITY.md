# Security Policy

## Report a vulnerability

Use [private vulnerability reporting](https://github.com/dan-petty/devtools/security/advisories/new) of this repository. Do not open a public issue, pull request or discussion.

Tell us:

- The image digest or tag, and the platform (`linux/amd64` or `linux/arm64`).
- The tool or the file of this repository that has the problem.
- How to reproduce it.

## Supported versions

Only the newest image gets fixes: the image that `latest` points to. The daily rebuild and the Renovate updates make a new image. An older tag or digest gets no fix.

## Scope

This repository owns the `Dockerfile`, the lock files of the tools, the workflows and the tests. A vulnerability in one of them is in scope.

A vulnerability in an upstream tool goes to the project of that tool. The image takes the fix when the tool releases it: a Renovate update for a tool of `mise.lock`, `npm/` or `python/`, or the daily rebuild for an apt package. If no release has the fix, the image keeps a time-limited ignore with a tracking issue (see the README).
