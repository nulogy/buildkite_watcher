# frozen_string_literal: true

module BuildkiteWatcher
  RSpec.describe ConfigLoader do
    let(:config) { tty_config_double }
    let(:secrets) { tty_config_double }

    it "reads config file if it exists" do
      allow(config).to receive(:exist?).and_return(true)
      ConfigLoader.load(config, secrets)
      expect(config).to have_received(:read)
    end

    it "does not read config file if it doesn't exist" do
      allow(config).to receive(:exist?).and_return(false)
      ConfigLoader.load(config, secrets)
      expect(config).not_to have_received(:read)
    end

    it "reads secrets file if it it exists" do
      allow(secrets).to receive(:exist?).and_return(true)
      ConfigLoader.load(config, secrets)
      expect(secrets).to have_received(:read)
    end

    it "does not read secrets file if it doesn't exist" do
      allow(secrets).to receive(:exist?).and_return(false)
      ConfigLoader.load(config, secrets)
      expect(secrets).not_to have_received(:read)
    end

    def tty_config_double
      double(TTY::Config, :filename= => nil, :append_path => nil, :exist? => true, :read => nil, :fetch => nil)
    end
  end
end
