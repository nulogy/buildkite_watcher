##
# Synopsis
# ========
#
# It encapsulates a value, and the success/failure state of the value. It
# also exposes methods for conditional execution/control flow depending
# on the success or failure of the result.
#
# This is a simpler instantiation of patterns like Promises in JavaScript,
# or std::result from Rust.
#
# You can think of it as a Promise from JavaScript, but synchronous:
#   * `on_success` is similar to `then`
#   * `on_failure` is similar to `catch`.
#
# Design Notes
# ============
#
# * It is explicitly designed to be binary. We do not support more than two
#   success/failure states. We don't usually observe more than two states in
#   practice, so this was deemed to be an acceptable tradeoff.
#
# Sample Usage
# ============
#
# NOTE: You can pass zero or more args via Result objects. The example below
# passes one arg via the success result, and two args via the failure result.
#
#   ##
#   # In controller
#   #
#   Service.new.run
#     .on_success do |arg1|
#       # ...
#     end
#     .on_failure do |arg1, arg2|
#       # ...
#     end
#   end
#
#   ##
#   # In service
#   #
#   Results::Result.success(arg1)
#   Results::Result.failure(arg1, arg2)
#
#   ##
#   # In service specs
#   #
#   result = Service.new.run
#   expect(result).to be_successful_and { |arg1|
#     expect(arg1).to eq("value1")
#   }
#   expect(result).to be_failed_and { |arg1, arg2|
#     expect(arg1).to eq("value1")
#     expect(arg2).to eq("value2")
#   }
#
module Results
  class Result
    class << self
      ##
      # Create a successful Result containing an arbitrary value.
      #
      def success(*result)
        new(true, result)
      end

      ##
      # Create a failed Result containing an arbitrary value.
      #
      def failure(*result)
        new(false, result)
      end

      ##
      # Aggregates an array of Results into a single Result,
      # collecting all successes or all failures.
      #
      # Is a Query, not a Command.
      #
      def array_all_or_none(results)
        array = []
        if results.all?(&:successful?)
          results.each { |result| result.map_success { |value| array << value } }
          success(array)
        else
          results.reject(&:successful?).each { |result| result.map_failure { |value| array << value } }
          failure(array)
        end
      end

      ##
      # Aggregates a hash of Results into a single Result,
      # collecting all successes or all failures.
      #
      # Is a Query, not a Command.
      #
      def hash_all_or_none(results)
        hash = {}
        if results.values.all?(&:successful?)
          results.each { |key, result| result.map_success { |value| hash.merge!(key => value) } }
          success(hash)
        else
          results.reject { |_, result| result.successful? }.each do |key, result|
            result.map_failure { |value| hash.merge!(key => value) }
          end
          failure(hash)
        end
      end
    end

    ##
    # Constructor.
    #
    # Accepts an arbitrary value +result+ and whether or not the value is
    # successful as +success+.
    #
    def initialize(success, result)
      @success = success
      @result = result
    end

    ##
    # Transforms the value contained by a successful Result according
    # to the provided block. Leaves failed Results unaltered.
    #
    # Is a Query, not a Command.
    #
    # Returns the value of the block, but wrapped in a successful Result.
    #
    def map_success
      return self unless @success
      self.class.success(yield(*@result))
    end

    ##
    # Transforms the value contained by a failed Result according
    # to the provided block. Leaves successful Results unaltered.
    #
    # Is a Query, not a Command.
    #
    # Returns the value of the block, but wrapped in a failed Result.
    #
    def map_failure
      return self if @success
      self.class.failure(yield(*@result))
    end

    ##
    # Control structure for executing the provided block *for effect only* on
    # a successful Result. Does nothing on failed Results.
    #
    # Is a Command, not a Query.
    #
    # Returns `self`.
    #
    def on_success
      return self unless @success
      yield(*@result)
      self
    end

    ##
    # Control structure for executing the provided block *for effect only* on a
    # failed Result. Does nothing on successful results.
    #
    # Is a Command, not a Query.
    #
    # Returns the value of the block, but wrapped in a failed Result.
    #
    def on_failure
      return self if @success
      yield(*@result)
      self
    end

    ##
    # Aliased reader for the success attribute.
    #
    def successful?
      @success
    end

    ##
    # The negation of `#successful?`
    #
    def failed?
      !successful?
    end

    ##
    # Two Results are equal if they contain the same value and success state.
    #
    def ==(other)
      successful? == other.successful? && result == other.result
    end

    protected

    attr_reader :result
  end
end
