require "buildkite_watcher/buildkite_build_checker"

module BuildkiteWatcher
  RSpec.describe BuildkiteBuildChecker do
    let(:branch_name) { "Super-Cool-Feature" }
    let(:progress_bar) { double(:progress_bar).as_null_object }
    let(:checker) { described_class.new(branch_name, progress_bar, buildkite_api: api) }

    before do
      # reduce polling frequency while testing
      stub_const("#{BuildkiteBuildChecker}::POLLING_FREQUENCY", 0)
    end

    context "when build is already done" do
      context "when build is done" do
        let(:api) { double(:buildkite_api, build_status: BuildStatus.new(success: true)) }

        it "stops the progess bar" do
          allow(progress_bar).to receive(:stop)

          checker.run
        end

        context "when build was successful" do
          let(:api) { double(:buildkite_api, build_status: BuildStatus.new(success: true)) }

          it "returns a successful result" do
            expect(checker.run).to be_successful
          end
        end

        context "when build was a failure" do
          let(:api) { double(:buildkite_api, build_status: BuildStatus.new(success: false)) }

          it "returns a failure result" do
            expect(checker.run).to be_failed
          end
        end
      end
    end

    context "when build is running" do
      let(:api) { double(:buildkite_api).as_null_object }

      before do
        # stub two API calls
        allow(api).to receive(:build_status).and_return(
          BuildStatus.new(completed: 0, total: 1),
          BuildStatus.new(success: true),
        )
      end

      it "polls the api" do
        expect(api).to receive(:build_status).twice

        checker.run
      end

      it "starts the progress bar" do
        expect(progress_bar).to receive(:start).once

        checker.run
      end

      it "updates the progress bar" do
        expect(progress_bar).to receive(:update).with(0).ordered.once
        expect(progress_bar).to receive(:update).with(100).ordered.once

        checker.run
      end

      context "when build already has 50% progress" do
        before do
          allow(api).to receive(:build_status).and_return(
            BuildStatus.new(completed: 1, total: 2),
            BuildStatus.new(success: true),
          )
        end

        it "updates the progress bar with the progress" do
          expect(progress_bar).to receive(:update).with(50).ordered.once
          expect(progress_bar).to receive(:update).with(100).ordered.once

          checker.run
        end
      end

      context "when build is done" do
        it "stops the progress bar" do
          expect(progress_bar).to receive(:stop).once

          checker.run
        end

        context "when build is successful" do
          it "returns a success result" do
            expect(checker.run).to be_successful
          end
        end

        context "when build has failed" do
          before do
            allow(api).to receive(:build_status).and_return(
              BuildStatus.new(completed: 0, total: 1),
              BuildStatus.new(success: false),
            )
          end

          it "returns a failed result" do
            expect(checker.run).to be_failed
          end
        end
      end
    end

    context "when API returns an error" do
      let(:api) { double(:buildkite_api).as_null_object }

      before do
        allow(api).to receive(:build_status).and_return(
          BuildStatus.new(error: true),
          BuildStatus.new(error: true),
          BuildStatus.new(error: true, errors: ["I'm an error"]),
        )
      end

      it "initializes progress bar to 0" do
        expect(progress_bar).to receive(:update).with(0)

        checker.run
      end

      it "retrys a couple times" do
        expect(api).to receive(:build_status).thrice

        checker.run
      end

      it "returns a failure after the third error with error messages" do
        result = checker.run

        expect(result).to be_failed_and { |errors| expect(errors).to eq(["I'm an error"]) }
      end
    end
  end
end
