# frozen_string_literal: true

require "rainbow"
require "buildkite_watcher/version"
require "buildkite_watcher/progress_bar_runner"
require "buildkite_watcher/progress_bar"
require "buildkite_watcher/buildkite_build_checker"

# Command line utility that continuously watches for the buildkite job running current git HEAD and
# notifies on build status changes.
module BuildkiteWatcher
  class << self
    GRAPHQL_QUERY = <<~GRAPHQL
      query ($commitHash: [String!], $branch: [String!]) {
        pipeline(slug: "[TODO]") {
          commit_hash_builds: builds(commit: $commitHash, state: [PASSED, RUNNING, FAILED], first: 1) {
            edges {
              node {
                commit
                message
                state
                jobs(first: 1, step: { key: "aggregate_results" }) {
                  edges {
                    node {
                      ... on JobTypeCommand {
                        label
                        artifacts {
                          edges {
                            node {
                              downloadURL
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
          branch_builds: builds(branch: $branch, state: [PASSED, RUNNING, FAILED], first: 2) {
            edges {
              node {
                commit
                message
                state
                jobs(first: 1, step: { key: "aggregate_results" }) {
                  edges {
                    node {
                      ... on JobTypeCommand {
                        label
                        artifacts {
                          edges {
                            node {
                              downloadURL
                            }
                          }
                        }
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
    BUILDS_URL = "https://api.buildkite.com/v2/organizations/[org-name]/pipelines/[pipeline]/builds"
    BUILD_PASSED = "PASSED"
    BUILD_RUNNING = "RUNNING"
    BUILD_FAILED = "FAILED"
    BUILD_UNKNOWN_STATUS = "UNKNOWN"

    def result_watch
      Signal.trap("SIGINT") do
        puts
        puts Rainbow("Program interrupt received. Exiting.").red
        exit 1
      end

      previous_result = BUILD_UNKNOWN_STATUS
      loop do
        system("clear")
        new_result = result

        maybe_notify(previous_result, new_result)
        previous_result = new_result

        sleep 5
      end
    end

    # Scenarios:
    # - current commit doesn't have a build, no prior failed build
    # - current commit doesn't have a build, there is a prior failed build
    # - current commit has a build, is running, no prior failed build
    # - current commit has a build, is running, there is a prior failed build
    # - current commit has a build, has passed
    # - current commit has a build, has failed

    def result
      puts Rainbow("Branch: ").bright + Rainbow(branch_name)
      puts Rainbow("HEAD ➜  ").bright + Rainbow(commit_hash)
      puts

      buildkite_query = { query: GRAPHQL_QUERY, variables: { commitHash: commit_hash, branch: branch_name } }
      builds = fetch_build_data(buildkite_query)
      commit_hash_builds = simplify_builds_response_data(builds.commit_hash_builds)
      branch_builds = simplify_builds_response_data(builds.branch_builds)

      if commit_hash_builds.any?
        build = commit_hash_builds.first
        print_state(build.state)
        return build.state if build.state == BUILD_PASSED || branch_builds.empty?

        if build.state == BUILD_RUNNING && prior_build_failed?(branch_builds)
          puts
          puts Rainbow("Prior failure summary:").bright
          print_failures(prior_failed_build(branch_builds))
        elsif build.state == BUILD_FAILED
          print_failures(build)
        end
      else
        print_no_current_build

        return build.state if branch_builds.empty?

        puts
        puts Rainbow("Prior finished build summary:").bright
        puts

        build = branch_builds.first
        print_state(build.state)
        return build.state if build.state == BUILD_PASSED

        if last_build_failed?(branch_builds)
          puts
          puts Rainbow("Failure summary:").bright

          build = branch_builds.first
          print_failures(build)
        end
      end
      build.state
    rescue StandardError => e
      puts
      puts Rainbow("ERROR: #{e.message}").red
    end

    private

    def maybe_notify(previous_result, new_result)
      return if new_result == previous_result || previous_result == BUILD_UNKNOWN_STATUS

      case new_result
      when BUILD_PASSED
        system('osascript -e \'display notification "CI PASSED" with title "CI Result Watch" sound name "Glass"\'')
      when BUILD_FAILED
        system('osascript -e \'display notification "CI FAILED" with title "CI Result Watch" sound name "Basso"\'')
      end
    end

    def fetch_build_data(buildkite_query)
      response =
        JSON.parse(
          RestClient.post(
            "https://graphql.buildkite.com/v1",
            buildkite_query.to_json,
            { Authorization: "Bearer #{buildkite_token}", content_type: :json },
          ),
          object_class: OpenStruct,
        )

      response.data.pipeline
    end

    def simplify_builds_response_data(builds)
      simplified_builds = builds.edges.map(&:node)
      simplified_builds.map do |build|
        OpenStruct.new(
          commit: build.commit,
          message: build.message,
          state: build.state,
          aggregate_results_job: simplify_jobs_response_data(build.jobs),
        )
      end
    end

    def simplify_jobs_response_data(jobs)
      simplified_jobs = jobs.edges.map(&:node)
      simplified_jobs.map do |job|
        OpenStruct.new(label: job.label, artifacts: simplify_artifacts_response_data(job.artifacts))
      end.first
    end

    def simplify_artifacts_response_data(artifacts)
      artifacts.edges.map(&:node)
    end

    def print_state(state)
      case state
      when BUILD_PASSED
        puts Rainbow("CI Status: ").bright + Rainbow(state).green
      when BUILD_RUNNING
        puts Rainbow("CI Status: ").bright + Rainbow(state).yellow
      when BUILD_FAILED
        puts Rainbow("CI Status: ").bright + Rainbow(state).red
      end
    end

    def print_no_current_build
      no_builds_for_head_message =
        "Your HEAD pointer is at commit #{commit_hash} but Buildkite has no finished builds for this commit."
      puts Rainbow(no_builds_for_head_message).yellow
      puts Rainbow("Push the current branch to trigger a build.").bright.yellow
    end

    def last_build_failed?(builds)
      builds.first.state == BUILD_FAILED
    end

    def prior_build_failed?(builds)
      builds.second.present? && builds.second.state == BUILD_FAILED
    end

    def prior_failed_build(builds)
      builds.second
    end

    def print_failures(build)
      aggregate_result_job = build.aggregate_results_job

      unless aggregate_result_job&.artifacts&.any?
        puts
        return(
          puts Rainbow("Could not retrieve failures. Please check the Aggregate Results step of the CI pipeline.")
                 .yellow
        )
      end
      failures_artifact = aggregate_result_job.artifacts.first
      download_url = failures_artifact.downloadURL

      failures = fetch_failures(download_url)

      puts
      puts Rainbow("#{failures.count} failures from these specs:").yellow
      puts
      failures.map(&:name).map { |name| /\[(\w+)\] (.*): .*/.match(name).captures }.group_by(&:first)
        .each do |key, values|
        puts key
        values
          .map(&:second)
          .uniq
          .each do |failure_file|
            failure_file
            puts Rainbow(failure_file).red
          end
      end
    end

    def fetch_failures(download_url)
      JSON.parse(RestClient.get(download_url), object_class: OpenStruct)
    end

    def branch_name
      `git symbolic-ref --short HEAD`.strip
    end

    def commit_hash
      `git rev-parse HEAD`.strip
    end

    def buildkite_token
      @_buildkite_token ||= `cat ~/.buildkite_token`
    end
  end
end
