package forwardemail

import (
	"os"
	"strings"
	"testing"

	"github.com/forwardemail/forwardemail-api-go/forwardemail"
	"github.com/hashicorp/terraform-plugin-sdk/v2/helper/schema"
	"github.com/hashicorp/terraform-plugin-testing/helper/resource"
)

// testAccProviderFactories returns factories for the SDKv2 provider to be used
// with terraform-plugin-testing.
func testAccProviderFactories() map[string]func() (*schema.Provider, error) {
	return map[string]func() (*schema.Provider, error){
		"forwardemail": func() (*schema.Provider, error) { return Provider(), nil },
	}
}

func TestProvider(t *testing.T) {
	if err := Provider().InternalValidate(); err != nil {
		t.Fatalf("err: %s", err)
	}
}

func TestProvider_impl(t *testing.T) {
	var _ *schema.Provider = Provider()
}

func testAccPreCheck(t *testing.T) {
	t.Helper()
	// Require TF_ACC for acceptance tests to run.
	if v := testAccGetEnv("TF_ACC"); v == "" || v == "0" {
		t.Skip("Acceptance tests skipped unless env 'TF_ACC' set")
	}
	// Ensure the API key is provided for acceptance tests.
	apiKey := testAccGetEnv("FORWARDEMAIL_API_KEY")
	if apiKey == "" {
		t.Skip("FORWARDEMAIL_API_KEY must be set for acceptance tests")
	}
	// Probe account to detect plan restrictions early and skip gracefully.
	client := forwardemail.NewClient(forwardemail.ClientOptions{ApiKey: apiKey})
	if _, err := client.GetAccount(); err != nil {
		if strings.Contains(err.Error(), "status: 402") || strings.Contains(err.Error(), "Payment Required") {
			t.Skip("Acceptance tests skipped: Forward Email plan does not permit this operation (402 Payment Required)")
		}
		t.Fatalf("precheck failed getting account: %v", err)
	}
}

func TestAccTests(t *testing.T) {
	for name, c := range TestCases {
		t.Helper()
		t.Run(name, func(t *testing.T) {
			resource.Test(t, c(t))
		})
	}
}

var TestCases = map[string]func(*testing.T) resource.TestCase{
	"account_data": testAccDataSourceForwardemailAccount,
}

// testAccGetEnv is a small indirection to allow tests to stub environment access if needed.
func testAccGetEnv(key string) string {
	return os.Getenv(key)
}
