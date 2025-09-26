// Package sweep provides utility functions for configuring and running
// test sweepers for Forward Email resources in Terraform.
package sweep

import (
	"fmt"
	"log"
	"os"

	"github.com/forwardemail/forwardemail-api-go/forwardemail"
)

// ConfigureSweeperClient initializes a Forward Email client using environment variables
// It returns the client and an error if initialization fails.
func ConfigureSweeperClient(name string) (*forwardemail.Client, error) {
	apiKey := os.Getenv("FORWARDEMAIL_API_KEY")
	if apiKey == "" {
		log.Printf("[INFO] Skipping %s sweeper - FORWARDEMAIL_API_KEY not set", name)
		return nil, fmt.Errorf("failed to find FORWARDEMAIL_API_KEY")
	}

	// Initialize the client
	client := forwardemail.NewClient(
		forwardemail.ClientOptions{ApiKey: apiKey},
	)

	return client, nil
}
