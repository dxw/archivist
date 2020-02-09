$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

require "slack-ruby-client"

require "archivist"

ENV["ARCHIVIST_SLACK_API_TOKEN"] = "testtoken"
