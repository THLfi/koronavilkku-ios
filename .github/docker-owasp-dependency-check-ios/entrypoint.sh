#!/bin/dash

set -e

sh -c "dependency-check.sh --enableExperimental --project '$GITHUB_REPOSITORY' --scan '$PWD/$INPUT_DERIVED_DATA_PATH'"
