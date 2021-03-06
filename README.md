# Buildkite Watcher

[![Gem Version](https://badge.fury.io/rb/buildkite_watcher.svg)](https://badge.fury.io/rb/buildkite_watcher)
[![CI Status](https://github.com/nulogy/buildkite_watcher/workflows/CI/badge.svg?branch=main)](https://github.com/nulogy/buildkite_watcher/actions?query=workflow%3ACI)

It continuously watches the most recent buildkite job running the current git branch and notifies on build status changes.

![Notification Screenshot](docs/notification_screenshot.png)

## Installation

Run this command:

    gem install buildkite_watcher

## Usage

From your project's root directory, run:

    bw

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

### To release a new version

1. Update `CHANGELOG.md`
1. Update the version number in `version.rb`
1. Run `bundle install`
1. Commit the changes
1. Run `bundle exec rake release`

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/nulogy/buildkite_watcher.
