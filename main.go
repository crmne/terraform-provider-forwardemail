package main

import (
	"flag"

	"github.com/forwardemail/terraform-provider-forwardemail/forwardemail"
	"github.com/hashicorp/terraform-plugin-sdk/v2/plugin"
)

func main() {
	var debug bool

	flag.BoolVar(&debug, "debug", false, "set to true to run the provider with support for debuggers like delve")
	flag.Parse()

	opts := &plugin.ServeOpts{
		Debug:        debug,
		ProviderAddr: "search.opentofu.org/provider/forwardemail/forwardemail",
		ProviderFunc: forwardemail.Provider,
	}

	plugin.Serve(opts)
}
