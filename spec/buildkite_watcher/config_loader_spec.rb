# frozen_string_literal: true

module BuildkiteWatcher
  RSpec.describe ConfigLoader do
    let(:tmp_dir) { Dir.mktmpdir }
    let(:config) { create_tty_config }
    let(:secrets) { create_tty_config }
    let(:prompt) { instance_double(TTY::Prompt, say: nil, ok: nil, ask: nil) }

    it "loads pipeline_slug from config file if it exists" do
      create_config_file(pipeline_slug: "my-org/my-pipeline")

      result = load

      expect(result.pipeline_slug).to eq("my-org/my-pipeline")
    end

    it "loads buildkite_token from secrets file if it it exists" do
      create_secrets_file(buildkite_token: "my-super-secret-token")

      result = load

      expect(result.buildkite_token).to eq("my-super-secret-token")
    end

    it "prompts the user if config file is missing" do
      allow(prompt).to receive(:ask).and_return("my-org/my-prompted-pipeline")

      load

      expect(prompt).to have_received(:say)
      expect(prompt).to have_received(:ask).with(/What's the pipeline slug of the pipeline you want to watch/)
    end

    it "prompts the user if secrets file is missing"

    def load
      ConfigLoader.load(config, secrets, prompt)
    end

    def create_tty_config
      config = TTY::Config.new
      config.append_path(tmp_dir)
      config
    end

    def create_config_file(pipeline_slug:)
      File.write(File.join(tmp_dir, ConfigLoader::CONFIG_FILE_NAME), <<~YML)
        pipeline_slug: #{pipeline_slug}
      YML
    end

    def create_secrets_file(buildkite_token:)
      File.write(File.join(tmp_dir, ConfigLoader::SECRETS_FILE_NAME), <<~YML)
        buildkite_token: #{buildkite_token}
      YML
    end

    def tty_config_double
      double(TTY::Config, :filename= => nil, :append_path => nil, :exist? => true, :read => nil, :fetch => nil)
    end
  end
end
