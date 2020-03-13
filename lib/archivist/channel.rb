module Archivist
  class Channel
    extend Memoist

    SLACKBOT_BOT_ID = "B01".freeze
    IGNORED_MESSAGE_TYPES = %w[
      channel_join
      channel_leave
      message_deleted
    ].freeze

    DEFAULT_ARCHIVABLE_DAYS = 30
    # This is one day less than the cycle length to allow for fuzziness in
    # run times.
    DAYS_AFTER_WARNING_BEFORE_ARCHIVING = 6

    WARNING_BLOCK_ID_PREFIX = "archivist-warn"

    attr_reader :channel, :log

    def initialize(channel)
      @channel = channel
      @log = Logger.new($stdout)
    end

    def id
      channel.id
    end
    memoize :id

    def name
      channel.name
    end
    memoize :name

    def member?
      channel.is_member || false
    end
    memoize :member?

    def general?
      channel.is_general || false
    end
    memoize :general?

    def report_target?
      id == Config.report_channel_id
    end
    memoize :report_target?

    def shared?
      channel.is_shared || channel.pending_shared&.any? || false
    end
    memoize :shared?

    def monitored?
      !not_monitored?
    end
    memoize :monitored?

    def not_monitored?
      if Config.use_default_rules
        never_monitored? || matching_rule&.skip || false
      else
        never_monitored? || matching_rule.nil? || matching_rule.skip || false
      end
    end
    memoize :not_monitored?

    def warnable?
      stale? && not_warned?
    end
    memoize :warnable?

    def archivable?
      stale? && warned?(min_days_ago: DAYS_AFTER_WARNING_BEFORE_ARCHIVING)
    end
    memoize :archivable?

    private

    def matching_rule
      Config.rules.detect { |rule| rule.match?(channel) }
    end
    memoize :matching_rule

    def never_monitored?
      general? || shared? || labeled_as_no_archive? || false
    end
    memoize :never_monitored?

    def labeled_as_no_archive?
      Config.no_archive_label.present? &&
        channel.purpose&.value&.include?(Config.no_archive_label) ||
        channel.topic&.value&.include?(Config.no_archive_label) ||
        false
    end
    memoize :labeled_as_no_archive?

    def stale?
      rule = Config.rules.detect { |rule| rule.match?(channel) }

      has_no_recent_real_messages?(max_days_ago: rule&.days)
    end
    memoize :stale?

    def warned?(min_days_ago: nil)
      rule = Config.rules.detect { |rule| rule.match?(channel) }

      has_warning_message?(
        min_days_ago: min_days_ago,
        # We ignore warnings outside of the stale range so that if something
        # went wrong, we'd warn again eventually.
        max_days_ago: rule&.days
      )
    end

    def not_warned?
      !warned?
    end

    def has_recent_messages?(max_days_ago: nil)
      log.info("Checking ##{ENV["CI"] ? id : name} for messages...")

      Client.last_messages_in(
        channel,
        max_days_ago: max_days_ago || DEFAULT_ARCHIVABLE_DAYS
      ) do |response|
        real_messages = response.messages.reject { |message|
          message.hidden ||
            message.bot_id == SLACKBOT_BOT_ID ||
            IGNORED_MESSAGE_TYPES.include?(message.subtype) ||
            (
              (message.subtype == "bot_message" || message.bot_id) &&
              message.blocks &&
              message.blocks[0].block_id.start_with?(WARNING_BLOCK_ID_PREFIX)
            )
        }

        if real_messages.any?
          log.info("   ...found messages")

          return true
        end
      end

      log.info("   ...no messages found")

      false
    end

    def has_no_recent_real_messages?(max_days_ago: nil)
      !has_recent_messages?(max_days_ago: max_days_ago)
    end

    def has_warning_message?(min_days_ago: nil, max_days_ago: nil)
      log.info("Checking ##{ENV["CI"] ? id : name} for recent warning messages...")

      Client.last_messages_in(
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
  end
end
