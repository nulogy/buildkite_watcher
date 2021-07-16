# frozen_string_literal: true

require "tty-config"
require "buildkite_watcher/config"

module BuildkiteWatcher
  module ConfigLoader
    CONFIG_FILE_NAME = ".buildkite_watcher.yml"
    SECRETS_FILE_NAME = ".buildkite_watcher_secrets.yml"

    def self.load
      config = TTY::Config.new
      config.filename = CONFIG_FILE_NAME
      config.append_path Dir.pwd
      config.read

      secrets = TTY::Config.new
      secrets.filename = SECRETS_FILE_NAME
      secrets.append_path Dir.pwd
      secrets.append_path Dir.home
      secrets.read

      Config.new(config, secrets)
    end
  end
end
