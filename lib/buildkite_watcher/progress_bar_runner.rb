# frozen_string_literal: true

require "forwardable"

class ProgressBarRunner
  extend Forwardable

  TICK = 0.5

  def_delegators :@progress_bar, :update

  def initialize(progress_bar)
    @progress_bar = progress_bar
  end

  def start
    @thread =
      Thread.new do
        loop do
          progress_bar.print

          if progress_bar.done?
            progress_bar.clean_up
            break
          end

          sleep TICK
        end
      end
  end

  def stop
    progress_bar.finish

    @thread&.join
  end

  private

  attr_reader :progress_bar
end
