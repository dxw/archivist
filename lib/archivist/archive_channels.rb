module Archivist
  class ArchiveChannels
    class << self
      extend Memoist

      def run
        all = all_channels
        not_monitored_channels = not_monitored(all)
        monitored_channels = monitored(all)

        leave_channels(not_monitored_channels)
        join_new_channels(monitored_channels)
        archive_channels(monitored_channels)
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

      def monitored(channels)
        channels.select { |channel| monitored?(channel) }
      end
      memoize :monitored

      def not_monitored(channels)
        channels - monitored(channels)
      end
      memoize :not_monitored

      def monitored?(channel)
        !not_monitored?(channel)
      end
      memoize :monitored?

      def not_monitored?(channel)
        never_monitored =
          channel.is_general ||
          channel.is_shared ||
          channel.pending_shared&.any? ||
          channel.purpose&.value&.include?(Config.no_archive_label) ||
          channel.topic&.value&.include?(Config.no_archive_label)

        if Config.use_default_rules
          never_monitored
        else
          rules_apply = Config.rules.any? { |rule| rule.match?(channel) }

          never_monitored || !rules_apply
        end
      end
      memoize :not_monitored?

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
          .select { |channel| archivable?(channel) }
          .each { |channel| archive_channel(channel) }
      end

      # TODO: Actually do the archiving!
      def archive_channel(channel)
        puts "Archiving ##{channel.name}"
      end

      def archivable?(channel)
        rule = Config.rules.detect { |rule| rule.match?(channel) }

        has_no_recent_real_messages?(channel, days_ago: rule&.days)
      end
      memoize :archivable?

      def has_recent_real_messages?(channel, days_ago: nil)
        Config.slack_client.conversations_history(
          channel: channel.id,
          oldest: Date.today - (days_ago || 30)
        ) do |response|
          real_messages = response.messages.reject { |message|
            message.hidden || IGNORED_MESSAGE_TYPES.include?(message.subtype)
          }

          return true if real_messages.any?
        end

        false
      end

      def has_no_recent_real_messages?(channel, days_ago: nil)
        !has_recent_real_messages?(channel, days_ago: days_ago)
      end
    end
  end
end
