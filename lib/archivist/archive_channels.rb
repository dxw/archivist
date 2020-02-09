module Archivist
  class ArchiveChannels
    class << self
      def run
        all = all_channels
        ignored_channels = ignored(all)
        disposable_channels = disposable(all)

        leave_channels(ignored_channels)
        join_new_channels(disposable_channels)
        archive_channels(disposable_channels)
      end

      private

      IGNORED_MESSAGE_TYPES = %w[
        bot_message
        channel_join
        channel_leave
        message_deleted
      ].freeze

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

      def ignored(channels)
        channels.select { |channel| ignore?(channel) }
      end

      def disposable(channels)
        channels.reject { |channel| ignore?(channel) }
      end

      def ignore?(channel)
        return true unless Config.use_default_rules

        channel.is_general ||
          channel.is_shared ||
          channel.pending_shared&.any? ||
          channel.purpose&.value&.include?(Config.no_archive_label) ||
          channel.topic&.value&.include?(Config.no_archive_label)
      end

      def leave_channels(channels)
        channels.each do |channel|
          next unless channel.is_member

          Config.slack_client.conversations_leave(channel: channel.id)
        end
      end

      def join_new_channels(channels)
        channels.each do |channel|
          next if channel.is_member

          Config.slack_client.conversations_join(channel: channel.id)
        end
      end

      def archive_channels(channels)
        channels
          .select { |channel| archive?(channel) }
          .each { |channel| archive_channel(channel) }
      end

      # TODO: Actually do the archiving!
      def archive_channel(channel)
        puts "Archiving ##{channel.name}"
      end

      def archive?(channel)
        has_no_recent_real_messages?(channel)
      end

      def has_recent_real_messages?(channel, days_ago: 30)
        Config.slack_client.conversations_history(
          channel: channel.id,
          oldest: Date.today - days_ago
        ) do |response|
          real_messages = response.messages.reject { |message|
            message.hidden || IGNORED_MESSAGE_TYPES.include?(message.subtype)
          }

          return true if real_messages.any?
        end

        false
      end

      def has_no_recent_real_messages?(channel)
        !has_recent_real_messages?(channel)
      end
    end
  end
end
