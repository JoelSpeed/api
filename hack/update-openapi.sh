#!/bin/bash

source "$(dirname "${BASH_SOURCE}")/lib/init.sh"

CODEGEN_PKG=${CODEGEN_PKG:-$(cd ${SCRIPT_ROOT}; ls -d -1 ./vendor/k8s.io/code-generator 2>/dev/null || echo ../../../k8s.io/code-generator)}

verify="${VERIFY:-}"
output_package="${OUTPUT_PKG:-github.com/openshift/api/openapi}"

# API_GROUP_VERSIONS is a string of <group>/<version>.
# The compatibility gen needs a comma separated list of Go packages, so prefix each entry with a comma and the
# PACKAGE_NAME, then trim the leading comma.
inputArg="$(printf ",${PACKAGE_NAME}/%s" ${API_GROUP_VERSIONS})"
inputArg="${inputArg:1}"

function codegen::join() { local IFS="$1"; shift; echo "$*"; }

echo Generating OpenAPI definitions for ${API_GROUP_VERSIONS} at ${output_package}

go install ./${CODEGEN_PKG}/cmd/openapi-gen
declare -a OPENAPI_EXTRA_PACKAGES
${GOPATH}/bin/openapi-gen \
         --input-dirs "$(codegen::join , "${inputArg[@]}" "${OPENAPI_EXTRA_PACKAGES[@]+"${OPENAPI_EXTRA_PACKAGES[@]}"}")" \
         --input-dirs "k8s.io/apimachinery/pkg/apis/meta/v1,k8s.io/apimachinery/pkg/runtime,k8s.io/apimachinery/pkg/version" \
         --output-package "${output_package}/generated_openapi" \
         -O zz_generated.openapi \
         --go-header-file ${SCRIPT_ROOT}/hack/empty.txt \
         ${verify}

go build github.com/openshift/api/openapi/cmd/models-schema

./models-schema  | jq '.' > ../../../${output_package}/openapi.json
