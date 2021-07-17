# frozen_string_literal: true

require "tty-config"
require "tty-link"
require "tty-prompt"
require "buildkite_watcher/config"

module BuildkiteWatcher
  class ConfigLoader
    CONFIG_FILE_NAME = ".buildkite_watcher"
    SECRETS_FILE_NAME = ".buildkite_watcher_secrets"
    EXTENSION = ".yml"

    def self.load(config = TTY::Config.new, secrets = TTY::Config.new, prompt = TTY::Prompt.new)
      new(config, secrets, prompt).load
    end

    def load
      config.filename = CONFIG_FILE_NAME
      config.extname = EXTENSION
      config.append_path Dir.pwd
      config.exist? ? config.read : generate_config_file

      secrets.filename = SECRETS_FILE_NAME
      config.extname = EXTENSION
      secrets.append_path Dir.home

      secrets.exist? ? secrets.read : generate_secrets_file

      Config.new(config, secrets)
    end

    private

    attr_reader :config, :secrets, :prompt

    def initialize(config, secrets, prompt)
      @config = config
      @secrets = secrets
      @prompt = prompt
    end

    def generate_config_file
      prompt.ok("Welcome to Buildkite Watcher!")
      prompt.say("I can't find the configuration file, so I'll generate one for you now.")
      link_to_instructions =
        TTY::Link.link_to("instructions", "https://github.com/nulogy/buildkite_watcher/blob/main/docs/pipeline_slug.md")
      pipeline_slug = prompt.ask(<<~MSG)
        What's the pipeline slug of the pipeline you want to watch? See #{link_to_instructions} if you don't know how to find the pipeline slug.
      MSG
      config.set(:pipeline_slug, value: pipeline_slug)
      config.write(create: true)
    end

    def generate_secrets_file
      link_to_instructions =
        TTY::Link.link_to("here", "https://github.com/nulogy/buildkite_watcher/blob/main/docs/buildkite_token.md")
      link_to_new_token =
        TTY::Link.link_to("New API Access token in Buildkite", "https://buildkite.com/user/api-access-tokens/new")

      # We use #chop as a work around for a defect in TTY::Prompt that reprints prompt on every character
      # entered
      buildkite_token = prompt.mask(<<~MSG.chop)
        Create a #{link_to_new_token}.
        Make sure it has Organization and GraphQL API Access (more detailed instructions #{link_to_instructions}), and paste the token here:
      MSG
      secrets.set(:buildkite_token, value: buildkite_token)
      secrets.write(create: true)
    end
  end
end
