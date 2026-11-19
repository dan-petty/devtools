# syntax=docker/dockerfile:1.29.0@sha256:572cebbc2b15e6f84c077742952674889cb63cd5e9b80abdffcbe587b6f19183
# check=error=true

# A consumer image copies one command of the devtools image. The build shows that the command is a
# real file that runs on Debian trixie. The CI sets DEVTOOLS to the image that it built, and on main
# to the digest that it pushed. The default is scratch, not an image: scratch has no gh, so the
# build fails when DEVTOOLS is not set, and Renovate does not pin the image under test.
ARG DEVTOOLS=scratch
FROM ${DEVTOOLS} AS devtools

FROM python:3.14-slim-trixie@sha256:9aaa474097d094040649f2162a627c0049b408f52138d980916788d80f04802f
COPY --from=devtools /usr/local/bin/gh /usr/local/bin/gh
RUN ["gh", "--version"]
