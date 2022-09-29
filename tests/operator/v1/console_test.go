package v1

import (
  "fmt"
  "encoding/json"

	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"

	apiextensionsv1 "k8s.io/apiextensions-apiserver/pkg/apis/apiextensions/v1"
	"sigs.k8s.io/controller-runtime/pkg/envtest"
	"sigs.k8s.io/controller-runtime/pkg/envtest/komega"

  metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
  operatorv1 "github.com/openshift/api/operator/v1"
)

var _ = Describe("Console", func() {
	var crdOptions envtest.CRDInstallOptions
	var crd *apiextensionsv1.CustomResourceDefinition

	BeforeEach(func() {
		Expect(k8sClient).ToNot(BeNil(), "Kuberentes client is not initialised")

		crdOptions = envtest.CRDInstallOptions{
			Paths: []string{
				"../../vendor/github.com/openshift/api/operator/v1/0000_70_console-operator.crd.yaml",
			},
			ErrorIfPathMissing: true,
		}

		crds, err := envtest.InstallCRDs(cfg, crdOptions)
		Expect(err).ToNot(HaveOccurred())

		Expect(crds).To(HaveLen(1), "Only one CRD should have been installed")
		crd = crds[0]

		Expect(envtest.WaitForCRDs(cfg, crds, crdOptions)).To(Succeed())
	})

	AfterEach(func() {
		// Remove the CRD and wait for it to be removed from the API.
		// If we don't wait then subsequent tests may fail.
		Expect(envtest.UninstallCRDs(cfg, crdOptions)).ToNot(HaveOccurred())
		Eventually(komega.Get(crd)).Should(Not(Succeed()))
	})

  It("Can create a minimal Console", func() {
    console := &operatorv1.Console{
      ObjectMeta: metav1.ObjectMeta{
        Name: "cluster",
      },
      Spec: operatorv1.ConsoleSpec{
        OperatorSpec: operatorv1.OperatorSpec{
          ManagementState: operatorv1.Managed,
        },
      },
    }

    data, err := json.Marshal(console)
    Expect(err).ToNot(HaveOccurred())

    fmt.Printf("Console: %s", string(data))

    Expect(k8sClient.Create(ctx, console)).To(Succeed())

    Expect(console.Spec.Customization.DeveloperCatalog.Types.State).To(BeEquivalentTo("Enabled"))
  })

})
