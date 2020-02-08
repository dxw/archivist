module Archivist
  class Config
    class << self
      attr_accessor :slack_client

      def configure(slack_token:)
        @slack_client = Slack::Web::Client.new(token: slack_token)

        self
      end
    end
  end
end
