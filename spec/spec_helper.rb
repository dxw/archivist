$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

require "slack-ruby-client"

require "archivist"
require "timecop"

ENV["ARCHIVIST_SLACK_API_TOKEN"] = "testtoken"

Timecop.safe_mode = true
