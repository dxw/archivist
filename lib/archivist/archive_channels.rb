module Archivist
  class ArchiveChannels
    extend Memoist

    IGNORED_MESSAGE_TYPES = %w[
      bot_message
      channel_join
      channel_leave
      message_deleted
    ].freeze

    DEFAULT_ARCHIVABLE_DAYS = 30
    # This is one day less than the cycle length to allow for fuzziness in
    # run times.
    DAYS_AFTER_WARNING_BEFORE_ARCHIVING = 6

    WARNING_BLOCK_ID_PREFIX = "archivist-warn"
    ARCHIVING_BLOCK_ID_PREFIX = "archivist-archive"

    WARNING_MESSAGE_BLOCKS = [
      {
        type: "section",
        text: {
          type: "mrkdwn",
          text: ":warning: *This channel will be archived soon due to lack of activity!* :warning:",
        },
      },
      {
        type: "section",
        text: {
          type: "mrkdwn",
          text:
            Config.no_archive_label ?
              "If this is unexpected and unwanted and you want to ask me to ignore it in future, add `#{Config.no_archive_label}` to the channel's description or topic and I will. If it's just too soon, but you don't want me to ignore the channel entirely, continue to use it (send a message) and I'll check again later." :
              "If you're not ready for this channel to be archived, continue to use it (send a message) and I'll check again later.",
        },
      },
      {
        type: "section",
        text: {
          type: "plain_text",
          text: "If the rules are wrong or need updating, you might need to modify my configuration. Let my maintainers for your workspace know!",
        },
      },
    ].freeze

    attr_reader :log

    def initialize
      @log = Logger.new(STDOUT)
    end

    def run
      channels_to_leave = not_monitored_channels.reject { |channel|
        report_channels.include?(channel)
      }
      channels_to_join = monitored_channels + report_channels

      leave_channels(channels_to_leave)
      join_new_channels(channels_to_join)

      warned = warn_channels(monitored_channels)
      archived = archive_channels(monitored_channels)

      send_report(archived, warned)
    end

    private

    def leave_channels(channels)
      channels.each do |channel|
        next unless channel.is_member

        log.info("Leaving ##{channel.name}")

        Config.slack_client.conversations_leave(channel: channel.id)
      end
    end

    def join_new_channels(channels)
      channels.each do |channel|
        next if channel.is_member

        log.info("Joining ##{channel.name}")

        Config.slack_client.conversations_join(channel: channel.id)
      end
    end

    def warn_channels(channels)
      channels_to_warn = channels.select { |channel| warnable?(channel) }

      channels_to_warn.each { |channel| warn_channel(channel) }

      channels_to_warn
    end

    def warn_channel(channel)
      blocks = WARNING_MESSAGE_BLOCKS.dup
      blocks[0][:block_id] = "#{WARNING_BLOCK_ID_PREFIX}-#{SecureRandom.uuid}"

      log.info("Warning ##{channel.name}")

      Config.slack_client.chat_postMessage(
        channel: channel.id,
        blocks: blocks
      )
    end

    def archive_channels(channels)
      channels_to_archive = channels.select { |channel| archivable?(channel) }

      channels_to_archive.each do |channel|
        log.info("Archiving ##{channel.name}")

        Config.slack_client.conversations_archive(channel: channel.id)
      end

      channels_to_archive
    end

    def send_report(archived, warned)
      return unless Config.report_channel_id

      unless archived.empty?
        log.info("Reporting on archived channels")

        Config.slack_client.chat_postMessage(
          channel: Config.report_channel_id,
          blocks: [
            {
              type: "section",
              text: {
                type: "plain_text",
                text: "I have archived the following inactive channels:",
              },
            },
            {
              type: "section",
              text: {
                type: "mrkdwn",
                text: archived.map { |channel| ":file_folder: ##{channel.name}" }.join("\n"),
              },
            },
          ]
        )
      end

      unless warned.empty?
        log.info("Reporting on warned channels")

        Config.slack_client.chat_postMessage(
          channel: Config.report_channel_id,
          blocks: [
            {
              type: "section",
              text: {
                type: "plain_text",
                text: "I will archive the following channels in a week if they remain inactive:",
              },
            },
            {
              type: "section",
              text: {
                type: "mrkdwn",
                text: warned.map { |channel| ":open_file_folder: ##{channel.name}" }.join("\n"),
              },
            },
          ]
        )
      end
    end

    def monitored_channels
      all_channels.select { |channel| monitored?(channel) }
    end
    memoize :monitored_channels

    def not_monitored_channels
      all_channels - monitored_channels
    end
    memoize :not_monitored_channels

    def report_channels
      return [] unless Config.report_channel_id

      all_channels.select { |channel| channel.id == Config.report_channel_id }
    end
    memoize :report_channels

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
    memoize :all_channels

    def monitored?(channel)
      !not_monitored?(channel)
    end
    memoize :monitored?

    def not_monitored?(channel)
      never_monitored =
        channel.is_general ||
        channel.is_shared ||
        channel.pending_shared&.any? ||
        (
          Config.no_archive_label &&
          channel.purpose&.value&.include?(Config.no_archive_label) ||
          channel.topic&.value&.include?(Config.no_archive_label)
        )

      rule = Config.rules.detect { |rule| rule.match?(channel) }

      if Config.use_default_rules
        never_monitored || rule&.skip
      else
        never_monitored || rule.nil? || rule.skip
      end
    end
    memoize :not_monitored?

    def warnable?(channel)
      stale?(channel) && not_warned?(channel)
    end
    memoize :warnable?

    def archivable?(channel)
      stale?(channel) &&
        warned?(channel, min_days_ago: DAYS_AFTER_WARNING_BEFORE_ARCHIVING)
    end
    memoize :archivable?

    def stale?(channel)
      rule = Config.rules.detect { |rule| rule.match?(channel) }

      has_no_recent_real_messages?(channel, max_days_ago: rule&.days)
    end
    memoize :stale?

    def warned?(channel, min_days_ago: nil)
      rule = Config.rules.detect { |rule| rule.match?(channel) }

      has_warning_message?(
        channel,
        min_days_ago: min_days_ago,
        # We ignore warnings outside of the stale range so that if something
        # went wrong, we'd warn again eventually.
        max_days_ago: rule&.days
      )
    end

    def not_warned?(channel, min_days_ago: nil)
      !warned?(channel, min_days_ago: min_days_ago)
    end

    def has_recent_real_messages?(channel, max_days_ago: nil)
      log.info("Checking ##{channel.name} for real messages...")

      last_messages(
        channel,
        max_days_ago: max_days_ago || DEFAULT_ARCHIVABLE_DAYS
      ) do |response|
        real_messages = response.messages.reject { |message|
          message.hidden ||
            message.bot_id ||
            IGNORED_MESSAGE_TYPES.include?(message.subtype)
        }

        if real_messages.any?
          log.info("   ...found real messages")

          return true
        end
      end

      log.info("   ...no real messages found")

      false
    end

    def has_no_recent_real_messages?(channel, max_days_ago: nil)
      !has_recent_real_messages?(channel, max_days_ago: max_days_ago)
    end

    def has_warning_message?(channel, min_days_ago: nil, max_days_ago: nil)
      log.info("Checking ##{channel.name} for recent warning messages...")

      last_messages(
        channel,
        # We run in small batches as we run this on channels that don't have
        # recent activity, so we expect the warning message to be very near
        # the end.
        limit: 5,
        min_days_ago: min_days_ago,
        max_days_ago: max_days_ago
      ) do |response|
        warning_message = response.messages.detect { |message|
          (message.subtype == "bot_message" || message.bot_id) &&
            message.blocks &&
            message.blocks[0].block_id.start_with?(WARNING_BLOCK_ID_PREFIX)
        }

        if warning_message
          message_sent_at = Time.new(warning_message.ts)

          log.info("   ...found warning message sent at #{message_sent_at}")

          return true if message_sent_at >= Date.today - DEFAULT_ARCHIVABLE_DAYS
        end
      end

      log.info("   ...no recent warning messages found")

      false
    end

    def last_messages(channel, limit: nil, min_days_ago: nil, max_days_ago: nil, &block)
      Config.slack_client.conversations_history(
        # API parameters
        channel: channel.id,
        limit: limit,
        # Providing `latest` means the history is fetched most recent first.
        latest: min_days_ago.nil? ? Time.now : (Date.today - min_days_ago),
        oldest: max_days_ago && Date.today - max_days_ago,

        # Client configuration
        sleep_interval: 1,
        &block
      )
    end
  end
end
