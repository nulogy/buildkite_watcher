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
      config.exist? ? config.read : generate_config(config, prompt)

      secrets.filename = SECRETS_FILE_NAME
      config.extname = EXTENSION
      secrets.append_path Dir.pwd
      secrets.append_path Dir.home

      secrets.read if secrets.exist?

      Config.new(config, secrets)
    end

    def self.generate_config(config, prompt)
      prompt.ok("Welcome to Buildkite Watcher!")
      prompt.say("I can't find my configuration file, so I'll generate one for you now.")
      pipeline_slug = prompt.ask("What's the pipeline slug of the pipeline you want to watch?")
      config.set(:pipeline_slug, value: pipeline_slug)
      config.write(create: true)
    end
  end
end
