require "graphql/client"
require "graphql/client/http"
require "buildkite_watcher/result"
require "buildkite_watcher/buildkite_api"

module BuildkiteWatcher
  class BuildkiteBuildChecker
    POLLING_FREQUENCY = 5
    ERRORS_TILL_FAILURE = 3

    def self.check(branch, progress_bar, token:)
      new(branch, progress_bar, buildkite_api: BuildkiteWatcher::BuildkiteAPI.new(token)).run
    end

    def initialize(branch, progress_bar, buildkite_api:)
      @branch = branch
      @progress_bar = progress_bar
      @buildkite_api = buildkite_api
      @error_count = 0
    end

    def run
      initial_status = buildkite_api.build_status(@branch)

      if initial_status.error?
        @error_count += 1
        @progress_bar.update(0)
      elsif initial_status.done?
        @progress_bar.stop
        return Results::Result.new(initial_status.success?, nil)
      else
        @progress_bar.update(initial_status.percent)
      end

      @progress_bar.start

      loop do
        sleep POLLING_FREQUENCY

        status = buildkite_api.build_status(@branch)

        if status.error?
          @error_count += 1

          if too_many_errors?
            @progress_bar.stop
            return Results::Result.failure(status.errors)
          end

          redo
        end

        @progress_bar.update(status.percent)

        next unless status.done?

        @progress_bar.stop

        return Results::Result.new(status.success?, nil)
      end
    end

    private

    attr_reader :buildkite_api

    def too_many_errors?
      @error_count >= ERRORS_TILL_FAILURE
    end
  end
end
