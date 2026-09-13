#!/usr/bin/env ruby
require 'fileutils'
require 'tmpdir'

module NotarizeDarwin
  APPLE_KEYS = %w[APPLE_CERTIFICATE_P12 APPLE_CERTIFICATE_PASSWORD
    APPLE_SIGNING_IDENTITY APPLE_ID APPLE_TEAM_ID APPLE_APP_PASSWORD].freeze
  module_function

  def run(os, binary, environment: ENV)
    return unless os == 'darwin'
    missing = APPLE_KEYS.select { |key| environment[key].to_s.empty? }
    return if missing.length == APPLE_KEYS.length && environment['REQUIRE_APPLE_NOTARIZATION'] != '1'
    raise "Missing Apple credentials: #{missing.join(', ')}" unless missing.empty?
    raise 'Notarization requires a native Mac' unless RUBY_PLATFORM.include?('darwin')
    Dir.mktmpdir('forwardemail-notarization-') do |directory|
      input = File.join(directory, 'input')
      output = File.join(directory, 'signed')
      FileUtils.mkdir_p(input)
      FileUtils.cp(binary, File.join(input, File.basename(binary)), preserve: true)
      cli = 'gem "native-packages", "0.5.1"; load Gem.bin_path("native-packages", "native-packages", "0.5.1")'
      raise 'Provider notarization failed' unless system(Gem.ruby, '-e', cli, 'notarize-macos', input, '--output', output)
      signed = File.join(output, File.basename(binary))
      raise 'Notarized provider verification failed' unless system('codesign', '--verify', '--strict', '-R=notarized', '--check-notarization', signed)
      FileUtils.cp(signed, binary, preserve: true)
    end
  end
end

if $PROGRAM_NAME == __FILE__
  begin
    raise 'Usage: notarize_darwin.rb OS BINARY' unless ARGV.length == 2
    NotarizeDarwin.run(*ARGV)
  rescue StandardError => error
    warn error.message
    exit 1
  end
end
