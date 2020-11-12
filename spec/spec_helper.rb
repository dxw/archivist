$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

require "logger"
require "slack-ruby-client"
require "timecop"

require "archivist"

ENV["ARCHIVIST_SLACK_API_TOKEN"] = "testtoken"

Timecop.safe_mode = true

RSpec.configure do |c|
  c.before(:example) do
    allow_any_instance_of(Logger).to receive(:info)
  end
end
