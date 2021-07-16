# frozen_string_literal: true

require_relative "lib/buildkite_watcher/version"

Gem::Specification.new do |spec|
  spec.name = "buildkite_watcher"
  spec.version = BuildkiteWatcher::VERSION
  spec.authors = ["Arturo Pie"]
  spec.email = ["arturop@nulogy.com"]

  spec.summary = "CLI utility that watches buildkite and notify on build status changes"
  spec.description = <<~MSG
    Command line utility that continuously watches for the buildkite job running current git HEAD and
    notifies on build status changes.
  MSG

  spec.required_ruby_version = ">= 2.7", "< 3.1"

  spec.metadata["source_code_uri"] = "https://github.com/nulogy/buildkite_watcher"
  spec.metadata["changelog_uri"] = "https://github.com/nulogy/buildkite_watcher/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files =
    Dir.chdir(File.expand_path(__dir__)) do
      `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
    end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "rest-client", "~> 2.0"
end
