module Archivist
  class ArchiveChannels
    class << self
      def run
        channels = disposable_channels

        join_new_channels(channels)
      end

      private

      def disposable_channels(limit: 999)
        all_channels(limit: limit).reject { |channel|
          channel.is_general ||
            channel.is_shared ||
            channel.pending_shared.any?
        }
      end

      def all_channels(limit: 999)
        response = Config.slack_client.conversations_list(
          exclude_archived: true,
          limit: limit,
          types: "public_channel"
        )

        response.channels
      end

      def join_new_channels(channels)
        channels.each do |channel|
          next if channel.is_member

          Config.slack_client.conversations_join(channel: channel.id)
        end
      end
    end
  end
end
