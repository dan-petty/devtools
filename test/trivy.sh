#!/usr/bin/env bash
# Scans a devtools image with the Trivy of the same image, report-only: findings do not change the
# exit status. Usage: test/trivy.sh IMAGE, with IMAGE in the image store of Docker. The scan writes
# trivy.json and trivy.sarif to the current folder. Trivy runs as the user of the runner, so that
# the cache step can read the databases in $RUNNER_TEMP/trivy. The job summary gets the detected
# OS and the finding counts of each package type.
set -euo pipefail

image=$1
cache="$RUNNER_TEMP/trivy"
mkdir -p "$cache"

trivy() {
  docker run --rm --user "$(id -u):$(id -g)" --group-add "$(stat -c %g /var/run/docker.sock)" \
    -e TRIVY_CACHE_DIR=/cache \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v "$cache:/cache" \
    -v "$PWD:/src" -w /src \
    "$image" trivy "$@"
}

trivy image --scanners vuln --format json --output trivy.json "$image"
trivy convert --format sarif --output trivy.sarif trivy.json
jq -r '
  "Detected OS: \(.Metadata.OS.Family // "none") \(.Metadata.OS.Name // "")",
  "OS package findings: \([.Results[] | select(.Class == "os-pkgs") | (.Vulnerabilities // [])[]] | length)",
  "",
  "| Type | Findings | By severity | HIGH or CRITICAL with a fix |",
  "| --- | ---: | --- | ---: |",
  ([.Results[] | .Type as $type | (.Vulnerabilities // [])[] | {$type, severity: .Severity, fixed: ((.FixedVersion // "") != "")}]
    | group_by(.type)[]
    | "| \(.[0].type) | \(length) | \([group_by(.severity)[] | "\(.[0].severity) \(length)"] | join(", ")) | \([.[] | select(.fixed and (.severity == "HIGH" or .severity == "CRITICAL"))] | length) |")
' trivy.json | tee -a "$GITHUB_STEP_SUMMARY"
