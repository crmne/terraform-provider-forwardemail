#!/usr/bin/env ruby
require 'digest'
require 'fileutils'
require 'tmpdir'

checksums = Dir['dist/*_SHA256SUMS']
abort 'Expected exactly one checksum manifest' unless checksums.length == 1
checksum = checksums.first
abort 'Checksum GPG signature is invalid' unless system('gpg', '--batch', '--verify', "#{checksum}.sig", checksum)
names = []
File.foreach(checksum) do |line|
  digest, name = line.split
  abort 'Invalid checksum entry' unless digest&.match?(/\A[0-9a-f]{64}\z/) && name && File.basename(name) == name
  abort 'Duplicate checksum entry' if names.include?(name)
  names << name
  path = name.end_with?('_manifest.json') ? 'terraform-registry-manifest.json' : File.join('dist', name)
  abort "Hash mismatch: #{name}" unless Digest::SHA256.file(path).hexdigest == digest
  FileUtils.cp(path, File.join('dist', name)) if name.end_with?('_manifest.json')
end
abort 'Registry manifest is missing from checksums' unless names.count { |name| name.end_with?('_manifest.json') } == 1
darwin = names.select { |name| name.match?(/_darwin_(amd64|arm64)\.zip\z/) }
abort 'Expected both Darwin ZIP archives' unless darwin.length == 2
darwin.each do |name|
  Dir.mktmpdir('forwardemail-archive-check-') do |directory|
    abort 'Cannot extract Darwin archive' unless system('unzip', '-q', File.join('dist', name), '-d', directory)
    binaries = Dir[File.join(directory, 'terraform-provider-forwardemail_v*')].select { |path| File.file?(path) }
    abort 'Expected one provider executable' unless binaries.length == 1
    abort "Notarization verification failed: #{name}" unless system('codesign', '--verify', '--strict', '-R=notarized', '--check-notarization', binaries.first)
  end
end
puts "Verified #{names.length} final archive/manifest hashes, GPG signature and both notarized Darwin ZIP payloads."
