# Design

## Decisions

- **The github backend of mise.** pv-migrate has no short name in the mise registry. The github backend reads the release assets, as for gh-dash, tuicr and weaver, and `mise lock` records the URL, the checksum and the provenance of each platform.

## Rejected alternatives

- **The aqua backend (`aqua:utkuozdemir/pv-migrate`).** The aqua registry has the package, but `mise.toml` names each other tool with no registry short name by the github backend (`mise.toml:6`: "A tool that has no short name in the mise registry uses the github backend").
- **The krew plugin `kubectl pv-migrate`.** The image has no krew, and dan-petty/devops-cli starts the command `pv-migrate`.
- **An apt package.** Debian has no pv-migrate package.
