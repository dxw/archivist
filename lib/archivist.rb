require "slack-ruby-client"

require "archivist/config"

module Archivist
  def self.configure(slack_token:)
    Config.configure(slack_token: slack_token)
  end
end
