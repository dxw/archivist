$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

require "logger"
require "slack-ruby-client"
require "timecop"

require "archivist"

ENV["ARCHIVIST_SLACK_API_TOKEN"] = "testtoken"

Timecop.safe_mode = true

RSpec.configure { |c| c.before(:example) { allow_any_instance_of(Logger).to receive(:info) } }
