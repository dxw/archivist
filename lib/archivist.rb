require "memoist"
require "slack-ruby-client"

require "archivist/config"

require "archivist/archive_channels"
require "archivist/rule"

module Archivist
  def self.configure
    Config.configure
  end
end
