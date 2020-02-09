require "slack-ruby-client"

require "archivist/config"

require "archivist/archive_channels"

module Archivist
  def self.configure(slack_token:)
    Config.configure(slack_token: slack_token)
  end
end
