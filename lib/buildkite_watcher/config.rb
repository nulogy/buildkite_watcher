# frozen_string_literal: true

module BuildkiteWatcher
  class Config
    attr_reader :pipeline, :buildkite_token

    def initialize(config, secrets)
      @pipeline = config.fetch(:pipeline)
      @buildkite_token = secrets.fetch(:buildkite_token)
    end
  end
end
