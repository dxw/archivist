module Archivist
  class ArchiveChannels
    class << self
      def run
        join_new_channels(all_channels)
      end

      private

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
