all: build
.PHONY: all

.PHONT: update-codegen-crds
update: update-codegen-crds

# Ensure update-scripts are run before crd-gen so updates to Godoc are included in CRDs.
update-codegen-crds: update-codegen-TechPreviewNoUpgrade-crds update-codegen-Default-crds update-scripts
	hack/update-codegen-crds.sh

RUNTIME ?= podman
RUNTIME_IMAGE_NAME ?= registry.ci.openshift.org/openshift/release:rhel-8-release-golang-1.18-openshift-4.12

verify-scripts:
	bash -x hack/verify-deepcopy.sh
	bash -x hack/verify-openapi.sh
	bash -x hack/verify-protobuf.sh
	bash -x hack/verify-swagger-docs.sh
	hack/verify-crds.sh
	bash -x hack/verify-types.sh
	bash -x hack/verify-compatibility.sh

.PHONY: verify-scripts
verify: verify-scripts verify-codegen-crds verify-codegen-TechPreviewNoUpgrade-crds verify-codegen-Default-crds

################################################################################################
#
# BEGIN: Update scripts. Defaults to generating updates for all API packages.
#        Set API_GROUP_VERSIONS to a space separated list of <group>/<version> to limit
#        the scope of the updates. Eg API_GROUP_VERSIONS="apps/v1 build/v1" make update-scripts.
#        Note: Protobuf generation is handled separately, see hack/lib/init.sh.
#
################################################################################################

.PHONY: update-scripts
update-scripts: update-compatibility update-openapi update-deepcopy update-protobuf update-swagger-docs tests-vendor

.PHONY: update-compatibility
update-compatibility:
	hack/update-compatibility.sh

.PHONY: update-openapi
update-openapi:
	hack/update-openapi.sh

.PHONY: update-deepcopy
update-deepcopy:
	hack/update-deepcopy.sh

.PHONY: update-protobuf
update-protobuf:
	hack/update-protobuf.sh

.PHONY: update-swagger-docs
update-swagger-docs:
	hack/update-swagger-docs.sh

#####################
#
# END: Update scripts
#
#####################

verify-with-container:
	$(RUNTIME) run -ti --rm -v $(PWD):/go/src/github.com/openshift/api:z -w /go/src/github.com/openshift/api $(RUNTIME_IMAGE_NAME) make verify

generate-with-container:
	$(RUNTIME) run -ti --rm -v $(PWD):/go/src/github.com/openshift/api:z -w /go/src/github.com/openshift/api $(RUNTIME_IMAGE_NAME) make update

.PHONY: integration
integration:
	make -C tests integration

tests-vendor:
	make -C tests vendor
