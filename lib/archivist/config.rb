module Archivist
  class Config
    class << self
      attr_accessor :slack_client, :no_archive_label

      def configure
        @slack_client = Slack::Web::Client.new(token: ENV.fetch("ARCHIVIST_SLACK_API_TOKEN"))
        @no_archive_label = ENV.fetch("ARCHIVIST_NO_ARCHIVE_LABEL", nil)

        self
      end
    end
  end
end
