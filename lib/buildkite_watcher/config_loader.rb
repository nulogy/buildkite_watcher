# frozen_string_literal: true

require "tty-config"
require "tty-prompt"
require "buildkite_watcher/config"

module BuildkiteWatcher
  module ConfigLoader
    CONFIG_FILE_NAME = ".buildkite_watcher"
    SECRETS_FILE_NAME = ".buildkite_watcher_secrets"
    EXTENSION = ".yml"

    def self.load(config = TTY::Config.new, secrets = TTY::Config.new, prompt = TTY::Prompt.new)
      config.filename = CONFIG_FILE_NAME
      config.extname = EXTENSION
      config.append_path Dir.pwd
      config.exist? ? config.read : generate_config_file(config, prompt)

      secrets.filename = SECRETS_FILE_NAME
      config.extname = EXTENSION
      secrets.append_path Dir.pwd
      secrets.append_path Dir.home

      secrets.exist? ? secrets.read : generate_secrets_file(secrets, prompt)

      Config.new(config, secrets)
    end

    def self.generate_config_file(config, prompt)
      prompt.ok("Welcome to Buildkite Watcher!")
      prompt.say("I can't find the configuration file, so I'll generate one for you now.")
      pipeline_slug = prompt.ask(<<~MSG)
        What's the pipeline slug of the pipeline you want to watch?
        You can find the pipeline slug on the URL of any of your builds, and it has the form of 'org-name/pipeline-name'.
      MSG
      config.set(:pipeline_slug, value: pipeline_slug)
      config.write(create: true)
    end

    def self.generate_secrets_file(secrets, prompt)
      buildkite_token = prompt.ask("Your buildkite token?")
      secrets.set(:buildkite_token, value: buildkite_token)
      secrets.write(create: true)
    end
  end
end
