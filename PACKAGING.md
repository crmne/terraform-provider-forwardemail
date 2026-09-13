# Release packaging

GoReleaser 2.18.1 builds the existing CGO-disabled platform matrix on macOS,
with serialized build hooks so Apple signing submissions run one at a time.
`scripts/notarize_darwin.rb` runs only for Darwin binaries, after compilation
and before ZIP creation. Published native-packages 0.5.1 signs and notarizes
an owned copy; the hook verifies Apple's acceptance with
`codesign --verify --strict -R=notarized --check-notarization` and imports the
signed bytes back into GoReleaser's build output. Other platforms are untouched.

GoReleaser then generates the existing Terraform ZIP names, includes the
versioned registry manifest in `SHA256SUMS`, signs that final checksum manifest
with GPG, and uploads the normal provider artifacts. Apple code signatures do
not replace Terraform's GPG checksum signature. Bare provider executables use
Apple's online notarization lookup; they cannot carry stapled tickets.

Production uses the existing `release.published` trigger and GPG inputs:
`GPG_PRIVATE_KEY` and `GPG_PASS`. Apple signing additionally needs the six
repository secrets `APPLE_CERTIFICATE_P12`, `APPLE_CERTIFICATE_PASSWORD`,
`APPLE_SIGNING_IDENTITY`, `APPLE_ID`, `APPLE_TEAM_ID`, and `APPLE_APP_PASSWORD`.
The certificate format and disposable keychain behavior are described in the
[shared signing guide](https://github.com/crmne/native-packages/blob/v0.5.1/docs/apple-notarization.md).
Missing or incomplete signing credentials fail production packaging.

A manual **Terraform Provider Release** workflow run is a non-publishing
snapshot test. It uses the Apple secrets and an ephemeral GPG test key, verifies
all final archive/registry-manifest hashes and the detached GPG signature,
extracts both Darwin ZIPs and verifies their notarization. It uploads review
artifacts for three days and deletes its owned GPG test home. It neither creates
a GitHub release nor publishes a Terraform provider.

Local GoReleaser builds without Apple credentials remain unsigned. CI sets
`REQUIRE_APPLE_NOTARIZATION=1` to disallow that fallback. No provider source,
Terraform resource behavior, registry schema or production GPG key is changed
by this integration.
