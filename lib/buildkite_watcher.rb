# frozen_string_literal: true

require_relative "buildkite_watcher/version"

module BuildkiteWatcher
  BUILDKITE_TOKEN_PATH = Pathname.new(ENV["HOME"]).join(".buildkite_token").to_s

  class Error < StandardError
  end

  def self.run
    token = File.read(BUILDKITE_TOKEN_PATH).chomp

    runner = ProgressBarRunner.new(ProgressBar.new)
    result = BuildkiteBuildChecker.check("main", runner, token: token)

    result.on_success { print_success("CI passed.") }.on_failure do |errors|
      errors ? print_errors_and_exit(*errors) : print_errors_and_exit("Build failed!")
    end
  end
end
