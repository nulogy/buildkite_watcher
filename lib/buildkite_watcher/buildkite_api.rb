# frozen_string_literal: true

require "graphql/client"

module BuildkiteWatcher
  class BuildStatus
    attr_reader :errors

    def initialize(completed: 1, total: 1, success: false, error: false, errors: [])
      @completed = completed
      @total = total
      @success = success
      @error = error
      @errors = errors
    end

    def done?
      @completed >= @total
    end

    def percent
      return 100 if done?

      Integer(1.0 * @completed / @total * 100)
    end

    def success?
      @success
    end

    def error?
      @error
    end
  end

  class BuildkiteAPI
    PIPELINE_SLUG = "nulogy-corp/eco"
    HTTP =
      GraphQL::Client::HTTP.new("https://graphql.buildkite.com/v1") do
        def headers(context)
          { Authorization: "Bearer #{context[:token]}" }
        end
      end
    Schema = GraphQL::Client.load_schema("#{__dir__}/buildkite_graphql_schema.json")
    Client = GraphQL::Client.new(schema: Schema, execute: HTTP)

    BuildStatusQuery = Client.parse(<<~GRAPHQL)
      query($branch: [String!]) {
        pipeline(slug: "#{PIPELINE_SLUG}") {
          builds(branch: $branch, first: 1) {
            edges {
              node {
                number
                state
                jobs(first: 300) {
                  count
                  edges {
                    node {
                      ... on JobTypeCommand {
                        state
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    GRAPHQL

    private_constant :HTTP, :Schema, :Client, :BuildStatusQuery

    def initialize(token)
      @token = token
    end

    def build_status(branch)
      result = Client.query(BuildStatusQuery, variables: { branch: [branch] }, context: { token: @token })

      return BuildStatus.new(error: true, errors: result.errors.messages["data"]) unless result.data

      build_node = result.data.pipeline.builds.edges.first.node

      return BuildStatus.new(success: build_successful?(build_node)) if build_done?(build_node)

      BuildStatus.new(completed: completed_job_count(build_node), total: total_job_count(build_node))
    end

    private

    def build_done?(build_node)
      %w[PASSED FAILED CANCELED].include?(build_node.state)
    end

    def completed_job_count(build_node)
      completed_status = %w[FINISHED CANCELED SKIPPED]

      build_node.jobs.edges.map { |e| e.node.respond_to?(:state) ? e.node.state : nil }.compact.count do |e|
        completed_status.include?(e)
      end
    end

    def total_job_count(build_node)
      total_jobs = build_node.jobs.count
      jobs_without_status = build_node.jobs.edges.count { |e| !e.node.respond_to?(:state) }

      total_jobs - jobs_without_status
    end

    def build_successful?(build_node)
      build_node.state == "PASSED"
    end
  end
end
