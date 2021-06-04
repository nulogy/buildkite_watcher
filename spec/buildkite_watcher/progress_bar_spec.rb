require "buildkite_watcher/progress_bar"

module BuildkiteWatcher
  RSpec.describe ProgressBar do
    let(:spy) { IOSpy.new }
    let(:progress_bar) { ProgressBar.new(output: spy) }

    it "shows 0% progress" do
      progress_bar.update(0)
      progress_bar.print

      expect(spy.animated_lines).to include("ᗣ •·· ᗣ •·· ᗣ •·· ᗣ •·· ᗤ -- 0%")
    end

    it "updates percentage complete" do
      progress_bar.update(0)
      progress_bar.print

      progress_bar.update(50)
      progress_bar.fast_forward
      progress_bar.print

      progress_bar.update(100)
      progress_bar.fast_forward
      progress_bar.print

      expect(spy.animated_lines).to include("ᗣ •·· ᗣ •·· ᗣ •·· ᗣ •·· ᗤ -- 0%")
      expect(spy.lines).to include("ᗣ •·· ᗣ •·· ○ -- 50%")
      expect(spy.lines).to include("ᗤ -- 100%")
    end

    it "animates pacman" do
      progress_bar.print
      progress_bar.print

      expect(spy.animated_lines).to include("ᗣ •·· ᗣ •·· ᗣ •·· ᗣ •·· ᗤ -- 0%")
      expect(spy.animated_lines).to include("ᗣ •·· ᗣ •·· ᗣ •·· ᗣ •·· ○ -- 0%")
    end

    context "when finishing" do
      it "animates to 100% in four steps" do
        progress_bar.print

        progress_bar.finish

        progress_bar.print
        progress_bar.print
        progress_bar.print
        progress_bar.print

        expect(spy.animated_lines).to include(
          "ᗣ •·· ᗣ •·· ᗣ •·· ᗣ •·· ᗤ -- 0%",
          "ᗣ •·· ᗣ •·· ᗣ •·· ○ -- 100%",
          "ᗣ •·· ᗣ •·· ᗤ -- 100%",
          "ᗣ •·· ○ -- 100%",
          "ᗤ -- 100%",
        )
      end

      it "ignores additional updates" do
        progress_bar.finish
        progress_bar.print
        progress_bar.update(75)
        progress_bar.print

        expect(spy.animated_lines).to all(include("100%"))
      end
    end

    class IOSpy
      attr_reader :lines

      def initialize
        @lines = []
      end

      def puts(content)
        if escape_sequence?(content) || escape_sequence?(lines.last)
          lines << content
        else
          # this re-constructs the last line, so that we
          # don't inadvertantly modify a constant
          last_line = lines.last.dup + content
          lines[-1] = last_line
        end
      end
      alias print puts

      def animated_lines
        lines.reject(&method(:escape_sequence?))
      end

      def read
        lines.join("\n")
      end

      def to_s
        strings = ["Received lines:", "=========="]
        lines.each { |l| strings << l.inspect }
        strings.join("\n")
      end

      private

      def escape_sequence?(text)
        text.include?("\e[")
      end
    end
  end
end
