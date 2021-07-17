# frozen_string_literal: true

module BuildkiteWatcher
  RSpec.describe ConfigLoader do
    let(:tmp_dir) { Dir.mktmpdir(SecureRandom.uuid) }
    let(:config_file_name) { File.join(tmp_dir, "#{ConfigLoader::CONFIG_FILE_NAME}#{ConfigLoader::EXTENSION}") }
    let(:secrets_file_name) { File.join(tmp_dir, "#{ConfigLoader::SECRETS_FILE_NAME}#{ConfigLoader::EXTENSION}") }
    let(:config) { create_tty_config }
    let(:secrets) { create_tty_config }
    let(:prompt) { instance_double(TTY::Prompt, say: nil, ok: nil, ask: "my-response", mask: "secret") }

    before do
      stub_const("BuildkiteWatcher::ConfigLoader::CONFIG_FILE_NAME", "buildkite_watcher_test")
      stub_const("BuildkiteWatcher::ConfigLoader::SECRETS_FILE_NAME", "buildkite_watcher_secrets_test")
    end

    it "loads pipeline_slug from config file if it exists" do
      create_config_file(pipeline_slug: "my-org/my-pipeline")

      result = load

      expect(result.pipeline_slug).to eq("my-org/my-pipeline")
    end

    it "prompts the user if config file is missing" do
      allow(prompt).to receive(:ask).and_return("my-org/my-prompted-pipeline")

      result = load

      expect(result.pipeline_slug).to eq("my-org/my-prompted-pipeline")
    end

    it "generates config file with user value" do
      allow(prompt).to receive(:ask).and_return("my-org/my-prompted-pipeline")

      load

      expect(File.exist?(config_file_name)).to eq(true), "Expected to create file, but it was not created"
      expect(File.read(config_file_name)).to include("pipeline_slug: my-org/my-prompted-pipeline")
    end

    it "loads buildkite_token from secrets file if it it exists" do
      create_secrets_file(buildkite_token: "my-super-secret-token")

      result = load

      expect(result.buildkite_token).to eq("my-super-secret-token")
    end

    it "prompts the user if secrets file is missing" do
      allow(prompt).to receive(:mask).and_return("my-secret-token")

      result = load

      expect(result.buildkite_token).to eq("my-secret-token")
    end

    it "prompts the user if secrets file is missing" do
      allow(prompt).to receive(:mask).and_return("my-secret-token")

      load

      expect(File.exist?(secrets_file_name)).to eq(true), "Expected to create file, but it was not created"
      expect(File.read(secrets_file_name)).to include("buildkite_token: my-secret-token")
    end

    def load
      ConfigLoader.load(config, secrets, prompt)
    end

    def create_tty_config
      config = TTY::Config.new
      config.append_path(tmp_dir)
      config
    end

    def create_config_file(pipeline_slug:)
      File.write(config_file_name, <<~YML)
        pipeline_slug: #{pipeline_slug}
      YML
    end

    def create_secrets_file(buildkite_token:)
      File.write(secrets_file_name, <<~YML)
        buildkite_token: #{buildkite_token}
      YML
    end
  end
end
