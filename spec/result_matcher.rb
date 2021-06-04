# frozen_string_literal: true

module Results
  module RspecMatchers
    module ResultMatcher
      RSpec::Matchers.define :be_successful_and do
        match(notify_expectation_failures: true) do |result|
          result.successful? && result.on_success(&block_arg)
        end

        description do
          errors = extract_errors(actual)
          break "be successful" if errors.blank?

          <<~ERROR_MESSAGE
            be successful, however encountered the following errors:
            #{errors.full_messages.join("\n")}
          ERROR_MESSAGE
        end

        def extract_errors(result)
          result.on_failure { |model| return model.errors if model.respond_to?(:errors) }
        end
      end
      RSpec::Matchers.alias_matcher(:have_succeeded_and, :be_successful_and)

      RSpec::Matchers.define :be_failed_and do
        match(notify_expectation_failures: true) do |result|
          !result.successful? && result.on_failure(&block_arg)
        end

        description { "be failed" }
      end
      RSpec::Matchers.alias_matcher(:have_failed_and, :be_failed_and)
    end
  end
end
