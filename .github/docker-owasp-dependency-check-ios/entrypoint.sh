#!/bin/dash

set -e

ls -Rla /github/workspace/owasp

sh -c "dependency-check.sh --enableExperimental --project '$GITHUB_REPOSITORY' --scan '$PWD/$INPUT_DERIVED_DATA_PATH' --suppression '$PWD/owasp_suppressions.xml' --failOnCVSS 1"
