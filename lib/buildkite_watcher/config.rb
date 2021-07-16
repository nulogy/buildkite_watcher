# frozen_string_literal: true

require "tty-config"

module BuildkiteWatcher
  module Config
    CONFIG_FILE_NAME = ".buildkite_watcher.yml"

    def self.load
      config = TTY::Config.new
      config.filename = CONFIG_FILE_NAME
      config.append_path Dir.pwd
      config.read

      config
    end
  end
end
