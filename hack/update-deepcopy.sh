#!/bin/bash

source "$(dirname "${BASH_SOURCE}")/lib/init.sh"

# API_GROUP_VERSION_PACKAGES is a string of <group>/<version>.
# The deepcopy gen needs a comma-separated list of ./<group>/<version> so print in that format and remove the leading comma.
inputArg="$(printf ",./%s" ${API_GROUP_VERSIONS})"
inputArg="${inputArg:1}"

verify="${VERIFY:-}"

# If we aren't in the GO path, clear the GOPATH variable when executing the deepcopy.
goPath="${GOPATH}"
if [[ ${SCRIPT_ROOT} != "${GOPATH}"* ]]; then
  goPath=""
fi

echo Generating Deepcopy for ${API_GROUP_VERSIONS}

GOPATH=${goPath} ${DEEPCOPY_GEN} \
  -O zz_generated.deepcopy \
  --trim-path-prefix "${SCRIPT_ROOT}" \
  --output-package "${PACKAGE_NAME}" \
  --go-header-file "${SCRIPT_ROOT}/hack/empty.txt" \
  --input-dirs "${inputArg}" \
  ${verify}
