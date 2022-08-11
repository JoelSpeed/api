#!/bin/bash

source "$(dirname "${BASH_SOURCE}")/lib/init.sh"

for groupVersion in ${API_GROUP_VERSIONS}; do
  # For each API group, generate the schema patch.
  echo "Generating API schema for ${groupVersion}"
  $(cd ${SCRIPT_ROOT}/tools && ${CONTROLLER_GEN} schemapatch:manifests="../${groupVersion}" paths="../${groupVersion}" output:dir="../${groupVersion}")

  # Then, if there are any YAML patch files to apply, apply those as well.
  for yamlPatch in ${SCRIPT_ROOT}/${groupVersion}/*.crd.yaml-patch; do
    if [ ! -f "$yamlPatch" ]; then
      # If the bash expansion of the wildcard doesn't match anything, it still returns one entry with a * in it.
      continue
    fi

    # Base CRD file should have the same name minus the trailing -patch.
    crdFile=$(echo "${yamlPatch}" | sed "s|-patch||")
    echo "Patching CRD ${crdFile} with patch ${yamlPatch}"

    $(cd ${SCRIPT_ROOT}/tools && ${YAML_PATCH} -o "${yamlPatch}" < "${crdFile}" > "${crdFile}.patched" && mv "${crdFile}.patched" "${crdFile}")
  done
done
