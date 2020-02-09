require "slack-ruby-client"

require "archivist/config"

require "archivist/archive_channels"

module Archivist
  def self.configure
    Config.configure
  end
end
