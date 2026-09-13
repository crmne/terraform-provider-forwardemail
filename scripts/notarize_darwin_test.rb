require 'minitest/autorun'
require_relative 'notarize_darwin'

class NotarizeDarwinTest < Minitest::Test
  def test_non_darwin_outputs_are_untouched_with_release_signing_required
    Dir.mktmpdir do |directory|
      binary = File.join(directory, 'provider')
      File.binwrite(binary, "unchanged\x00payload")
      %w[linux windows freebsd].each do |os|
        NotarizeDarwin.run(os, binary, environment: { 'REQUIRE_APPLE_NOTARIZATION' => '1' })
      end
      assert_equal "unchanged\x00payload", File.binread(binary)
    end
  end

  def test_required_signing_rejects_missing_credentials_before_touching_input
    assert_raises(RuntimeError) do
      NotarizeDarwin.run('darwin', '/missing/input', environment: { 'REQUIRE_APPLE_NOTARIZATION' => '1' })
    end
  end

  def test_partial_credentials_cannot_silently_skip_signing
    assert_raises(RuntimeError) do
      NotarizeDarwin.run('darwin', '/missing/input', environment: { 'APPLE_ID' => 'fixture@example.invalid' })
    end
  end
end
