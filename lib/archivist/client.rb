module Archivist
  class Client
    class << self
      attr_reader :slack_client

      def configure
        @slack_client = Slack::Web::Client.new(token: Config.slack_api_token)
      end

      def list_public_channels
        channels = []

        slack_client.conversations_list(
          # API parameters
          exclude_archived: true,
          types: "public_channel",

          # Client configuration
          sleep_interval: 2
        ) do |response|
          new_channels = response.channels.map { |channel|
            Channel.new(channel)
          }

          channels.concat(new_channels)
        end

        channels
      end

      def join(channel)
        slack_client.conversations_join(channel: channel.id)
      end

      def leave(channel)
        slack_client.conversations_leave(channel: channel.id)
      end

      def archive(channel)
        slack_client.conversations_archive(channel: channel.id)
      end

      def post_to(channel, blocks:)
        post_to_id(channel.id, blocks: blocks)
      end

      def post_to_id(channel_id, blocks:)
        slack_client.chat_postMessage(
          channel: channel_id,
          blocks: blocks
        )
      end

      def last_messages_in(channel, limit: nil, min_days_ago: nil, max_days_ago: nil, &block)
        slack_client.conversations_history(
          # API parameters
          channel: channel.id,
          limit: limit,
          # Providing `latest` means the history is fetched most recent first.
          latest: min_days_ago.nil? ? Time.now.to_i : (Date.today - min_days_ago).to_time.to_i,
          oldest: max_days_ago && (Date.today - max_days_ago).to_time.to_i,

          # Client configuration
          sleep_interval: 1,
          &block
        )
      end
    end
  end
end
