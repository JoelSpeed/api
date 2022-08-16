#!/bin/bash

source "$(dirname "${BASH_SOURCE}")/lib/init.sh"

# Linux vs OSX have different versions of mktemp which have different requirements.
# This attempts the Linux version first and then, should that fail, attempts the OSX version.
# Xref: https://unix.stackexchange.com/questions/30091/fix-or-alternative-for-mktemp-in-os-x
TMP_ROOT=$(mktemp --directory 2>/dev/null || mktemp -d -t 'api-compatibility')

cleanup() {
  rm -rf "${TMP_ROOT}"
}
trap "cleanup" EXIT SIGINT

V_ROOT="${TMP_ROOT}/src/github.com/openshift/api"
mkdir -p "$V_ROOT"
cp -a "$SCRIPT_ROOT"/* "$V_ROOT"
(
  cd "$V_ROOT" || exit
  export GOPATH="$TMP_ROOT"
  rm -Rf _output
  ./hack/update-compatibility.sh > /dev/null
)

# The compatibility script only generates based on the contents of API_GROUP_VERSIONS.
# We can limit our comparisons to these folders.
for apiVersion in ${API_GROUP_VERSIONS}; do
  GENERATED=$(find "${SCRIPT_ROOT}/${apiVersion}" -name "*.go" | sed "s|^${SCRIPT_ROOT}/||" | sort)

  for g in ${GENERATED}; do
    if ! diff --unified --text "$SCRIPT_ROOT/$g" "$V_ROOT/$g" ; then
      printf "\nopenshift_compatibility is out of date for ${apiVersion}. Please run hack/update-compatibility.sh\n"
      exit 1
    fi
  done
done
