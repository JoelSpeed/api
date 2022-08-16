#!/bin/bash

source "$(dirname "${BASH_SOURCE}")/lib/init.sh"

FAILS=false

for f in $(find "${SCRIPT_ROOT}" -name "*.yaml" -type f); do
    grep -qre "kind:\(.*\)CustomResourceDefinition" $f || continue
    grep -qre "name:\(.*\).openshift.io" $f || continue

    if [[ $(cd ${SCRIPT_ROOT}/tools && ${YQ} '.apiVersion' $f) == "apiextensions.k8s.io/v1beta1" ]]; then
        if [[ $(cd ${SCRIPT_ROOT}/tools && ${YQ} '.spec.validation.openAPIV3Schema.properties.metadata.description' $f) != "null" ]]; then
            echo "Error: cannot have a metadata description in $f"
            FAILS=true
        fi

        if [[ $(cd ${SCRIPT_ROOT}/tools && ${YQ} '.spec.preserveUnknownFields' $f) != "false" ]]; then
            echo "Error: pruning not enabled (.spec.preserveUnknownFields != false) in $f"
            FAILS=true
        fi
    fi

    if [[ $(cd ${SCRIPT_ROOT}/tools && ${YQ} '.metadata.annotations["api-approved.openshift.io"]' $f) == "null" ]]; then
        echo "Error: missing 'api-approved.openshift.io' annotation pointing to openshift/api pull request in $f"
        FAILS=true
    fi
done

if [ "$FAILS" = true ] ; then
    exit 1
fi
