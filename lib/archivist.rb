require "logger"
require "memoist"
require "securerandom"
require "slack-ruby-client"

require "archivist/config"
require "archivist/client"

require "archivist/archive_channels"
require "archivist/rule"

module Archivist
  def self.configure
    Config.configure
    Client.configure
  end
end
