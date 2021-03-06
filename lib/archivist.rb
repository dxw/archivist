require "active_support"
require "active_support/core_ext"
require "logger"
require "memoist"
require "securerandom"
require "slack-ruby-client"

require "archivist/config"

require "archivist/archive_channels"
require "archivist/channel"
require "archivist/client"
require "archivist/rule"

module Archivist
  def self.configure
    Config.configure
    Client.configure
  end
end
