# frozen_string_literal: true

require "tty-config"
require "tty-prompt"
require "buildkite_watcher/config"

module BuildkiteWatcher
  module ConfigLoader
    CONFIG_FILE_NAME = ".buildkite_watcher.yml"
    SECRETS_FILE_NAME = ".buildkite_watcher_secrets.yml"

    def self.load(config = TTY::Config.new, secrets = TTY::Config.new, prompt = TTY::Prompt.new)
      config.filename = CONFIG_FILE_NAME
      config.append_path Dir.pwd
      config.exist? ? config.read : generate_config(prompt)

      secrets.filename = SECRETS_FILE_NAME
      secrets.append_path Dir.pwd
      secrets.append_path Dir.home

      secrets.read if secrets.exist?

      Config.new(config, secrets)
    end

    def self.generate_config(prompt)
      prompt.ok("Welcome to Buildkite Watcher!")
      prompt.say("I can't find my configuration file, so I'll generate one for you now.")
      prompt.ask("What's the pipeline slug of the pipeline you want to watch?")
    end
  end
end
