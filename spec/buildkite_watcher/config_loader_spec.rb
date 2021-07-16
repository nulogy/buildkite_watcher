# frozen_string_literal: true

module BuildkiteWatcher
  RSpec.describe ConfigLoader do
    let(:config) { tty_config_double }
    let(:secrets) { tty_config_double }
    let(:prompt) { instance_double(TTY::Prompt, say: nil, ok: nil, ask: nil) }

    it "reads config file if it exists" do
      allow(config).to receive(:exist?).and_return(true)
      load
      expect(config).to have_received(:read)
    end

    it "does not read config file if it doesn't exist" do
      allow(config).to receive(:exist?).and_return(false)
      load
      expect(config).not_to have_received(:read)
    end

    it "reads secrets file if it it exists" do
      allow(secrets).to receive(:exist?).and_return(true)
      load
      expect(secrets).to have_received(:read)
    end

    it "does not read secrets file if it doesn't exist" do
      allow(secrets).to receive(:exist?).and_return(false)
      load
      expect(secrets).not_to have_received(:read)
    end

    it "prompts the user if config file is missing" do
      allow(config).to receive(:exist?).and_return(false)
      allow(prompt).to receive(:ask).and_return("my-org/my-pipeline")

      load

      expect(prompt).to have_received(:say)
      expect(prompt).to have_received(:ask).with(/What's the pipeline slug of the pipeline you want to watch/)
    end

    it "prompts the user if secrets file is missing"

    def load
      ConfigLoader.load(config, secrets, prompt)
    end

    def tty_config_double
      double(TTY::Config, :filename= => nil, :append_path => nil, :exist? => true, :read => nil, :fetch => nil)
    end
  end
end
