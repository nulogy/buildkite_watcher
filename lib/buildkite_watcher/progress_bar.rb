# frozen_string_literal: true

module BuildkiteWatcher
  class ProgressBar
    PACMAN_OPEN = "ᗤ"
    PACMAN_CLOSED = "○"
    GHOST = "ᗣ"
    FULL_BAR = "ᗣ •·· ᗣ •·· ᗣ •·· ᗣ •·· "

    def initialize(output: $stdout)
      @output = output
      @mouth_open = true
      @current_animation_percent = 0
      @animate_to_percent = 0
      @animation_increment = 2
      @finishing_up = false

      ensure_cursor_is_restored
    end

    def print
      clear_row
      reset_cursor
      hide_cursor
      print_progress_bar
      print_percent

      update_animation
    end

    def done?
      !animating? && animation_complete?
    end

    def clean_up
      flush_row
      show_cursor
    end

    def update(percent_complete)
      return if @finishing_up

      @animate_to_percent = percent_complete
    end

    def finish
      @finishing_up = true
      update_animation_rate_to_finish_quickly
    end

    # for testing only
    def fast_forward
      @current_animation_percent = @animate_to_percent
    end

    private

    attr_reader :output

    def animating?
      @current_animation_percent < @animate_to_percent
    end

    def animation_complete?
      @current_animation_percent >= 100
    end

    def update_animation
      @mouth_open = !@mouth_open
      @current_animation_percent = animation_percent_step
    end

    def clear_row
      output.print("\e[2K")
    end

    def reset_cursor
      output.print("\e[1000D")
    end

    def hide_cursor
      output.print("\e[?25l")
    end

    def show_cursor
      output.print("\e[?25h")
    end

    def flush_row
      output.puts("")
    end

    def print_progress_bar
      output.print(progress_bar)
    end

    def progress_bar
      return PACMAN_OPEN if done?

      chars_to_take = FULL_BAR.length * (100 - animation_percent_step) / 100

      FULL_BAR[0...chars_to_take] + pacman
    end

    def animation_percent_step
      [@current_animation_percent + @animation_increment, @animate_to_percent, 100].min
    end

    def print_percent
      output.print(" -- #{@animate_to_percent}%")
    end

    def pacman
      @mouth_open ? PACMAN_OPEN : PACMAN_CLOSED
    end

    def update_animation_rate_to_finish_quickly
      @animate_to_percent = 100
      ticks_until_finished = 4

      percent_left = @animate_to_percent - @current_animation_percent
      step, rem = percent_left.divmod(ticks_until_finished)

      @animation_increment = rem.zero? ? step : step + 1
    end

    def ensure_cursor_is_restored
      prepend_handler("SIGINT") do |previous_handler|
        clean_up

        previous_handler.call
      end
    end

    def prepend_handler(signal)
      previous =
        Signal.trap(signal) do
          previous = -> { raise SignalException, signal } unless previous.respond_to?(:call)
          yield previous
        end
    end
  end
end
