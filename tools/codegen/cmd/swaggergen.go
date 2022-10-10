package main

import (
	"fmt"

	"github.com/openshift/api/tools/codegen/pkg/generation"
	"github.com/openshift/api/tools/codegen/pkg/swaggergen"
	"github.com/spf13/cobra"
)

// swaggergenCmd represents the swaggergen command
var swaggergenCmd = &cobra.Command{
	Use:   "swaggergen",
	Short: "swagger generates swagger documentation from API definitions",
	RunE: func(cmd *cobra.Command, args []string) error {
		genCtx, err := generation.NewContext(generation.Options{
			BaseDir:          baseDir,
			APIGroupVersions: apiGroupVersions,
		})
		if err != nil {
			return fmt.Errorf("could not build generation context: %w", err)
		}

		gen := newSwaggerGenGenerator()

		return executeGenerators(genCtx, gen)
	},
}

func init() {
	rootCmd.AddCommand(swaggergenCmd)
}

// newSchemaPatchGenerator builds a new schemapatch generator.
func newSwaggerGenGenerator() generation.Generator {
	return swaggergen.NewGenerator(swaggergen.Options{})
}
