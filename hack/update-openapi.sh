#!/bin/bash

source "$(dirname "${BASH_SOURCE}")/lib/init.sh"

verify="${VERIFY:-}"
output_package="${OUTPUT_PKG:-github.com/openshift/api/openapi}"

# API_GROUP_VERSIONS is a string of <group>/<version>.
# The compatibility gen needs a comma separated list of Go packages, so prefix each entry with a comma and the
# PACKAGE_NAME, then trim the leading comma.
inputArg="$(printf ",${PACKAGE_NAME}/%s" ${API_GROUP_VERSIONS})"
inputArg="${inputArg:1}"

function codegen::join() { local IFS="$1"; shift; echo "$*"; }

echo Generating OpenAPI definitions for ${API_GROUP_VERSIONS} at ${output_package}

declare -a OPENAPI_EXTRA_PACKAGES
${OPENAPI_GEN} \
         --input-dirs "$(codegen::join , "${inputArg[@]}" "${OPENAPI_EXTRA_PACKAGES[@]+"${OPENAPI_EXTRA_PACKAGES[@]}"}")" \
         --input-dirs "k8s.io/apimachinery/pkg/apis/meta/v1,k8s.io/apimachinery/pkg/runtime,k8s.io/apimachinery/pkg/version" \
         --output-package "${SCRIPT_ROOT}/tools/openapi/generated_openapi" \
         -O zz_generated.openapi \
         --go-header-file ${SCRIPT_ROOT}/hack/empty.txt \
         ${verify}

${MODELS_SCHEMA} | jq '.' > ../../../${output_package}/openapi.json
