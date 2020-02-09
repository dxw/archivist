module Archivist
  class ArchiveChannels
    class << self
      def run
        channels = disposable_channels

        join_new_channels(channels)
        archive_channels(channels)
      end

      private

      def disposable_channels
        all_channels.reject { |channel|
          channel.is_general ||
            channel.is_shared ||
            channel.pending_shared.any?
        }
      end

      def all_channels
        channels = []

        Config.slack_client.conversations_list(
          # API parameters
          exclude_archived: true,
          types: "public_channel",

          # Client configuration
          sleep_interval: 2
        ) do |response|
          channels.concat(response.channels)
        end

        channels
      end

      def join_new_channels(channels)
        channels.each do |channel|
          next if channel.is_member

          Config.slack_client.conversations_join(channel: channel.id)
        end
      end

      def archive_channels(channels)
        channels.each { |channel| archive_channel(channel) }
      end

      # TODO: Actually do the archiving!
      def archive_channel(channel)
        puts "Archiving ##{channel.name}"
      end
    end
  end
end
