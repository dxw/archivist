module Archivist
  class Config
    class << self
      attr_accessor :slack_client, :no_archive_label, :use_default_rules

      def configure
        @slack_client = Slack::Web::Client.new(token: ENV.fetch("ARCHIVIST_SLACK_API_TOKEN"))
        @no_archive_label = ENV.fetch("ARCHIVIST_NO_ARCHIVE_LABEL", nil)
        @use_default_rules = ENV.fetch("ARCHIVIST_DISABLE_DEFAULTS", nil).nil?

        self
      end
    end
  end
end
