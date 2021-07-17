# frozen_string_literal: true

module BuildkiteWatcher
  class Config
    attr_reader :pipeline_slug, :buildkite_token

    def initialize(config, secrets)
      @pipeline_slug = config.fetch(:pipeline_slug)
      @buildkite_token = secrets.fetch(:buildkite_token)
    end
  end
end
