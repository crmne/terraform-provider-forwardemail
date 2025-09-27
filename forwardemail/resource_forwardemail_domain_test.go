package forwardemail

import (
	"testing"

	"github.com/hashicorp/terraform-plugin-testing/helper/resource"
)

func TestAccResourceForwardemailDomain(t *testing.T) {
	resource.Test(t, resource.TestCase{
		PreCheck:          func() { testAccPreCheck(t) },
		ProviderFactories: testAccProviderFactories(),
		Steps: []resource.TestStep{
			{
				Config: testAccDomainResourceConfig(),
				Check: resource.ComposeTestCheckFunc(
					resource.TestCheckResourceAttr("forwardemail_domain.test", "name", "example.com"),
				),
			},
		},
	})
}

func testAccDomainResourceConfig() string {
	return `
resource "forwardemail_domain" "test" {
  name = "example.com"
}
`
}
