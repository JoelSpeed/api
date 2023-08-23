package main

import (
	"flag"
	"fmt"
	"os"

	"github.com/openshift/api/payload-command/render"
)

func main() {
	o := &render.RenderOpts{}
	o.AddFlags(flag.CommandLine)
	flag.Parse()

	if err := o.Run(); err != nil {
		fmt.Fprintf(os.Stderr, "error: %v\n", err)
		os.Exit(2)
	}
}
