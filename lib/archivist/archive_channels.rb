module Archivist
  class ArchiveChannels
    WARNING_MESSAGE_BLOCKS = [
      {
        type: "section",
        text: {
          type: "mrkdwn",
          text: ":warning: *This channel will be archived soon due to lack of activity!* :warning:"
        }
      },
      {
        type: "section",
        text: {
          type: "mrkdwn",
          text:
            "If you're not ready for this channel to be archived, continue to use it (send a message) and I'll check again later."
        }
      },
      {
        type: "section",
        text: {
          type: "plain_text",
          text:
            "If the rules are wrong or need updating, you might need to modify my configuration. Let my maintainers for your workspace know!"
        }
      }
    ].freeze

    attr_reader :log

    def initialize
      @log = Logger.new($stdout)
    end

    def run
      leave_channels
      join_channels

      warned = warn_channels
      archived = archive_channels

      post_report(archived, warned)
    end

    private

    def leave_channels
      channels = Client.list_public_channels.reject { |channel| channel.monitored? || channel.report_target? }

      channels.each do |channel|
        next unless channel.member?

        log.info("Leaving ##{ENV["CI"] ? channel.id : channel.name}")

        Client.leave(channel)
      end
    end

    def join_channels
      channels = Client.list_public_channels.select { |channel| channel.monitored? || channel.report_target? }

      channels.each do |channel|
        next if channel.member?

        log.info("Joining ##{ENV["CI"] ? channel.id : channel.name}")

        Client.join(channel)
      end
    end

    def warn_channels
      channels = Client.list_public_channels.select { |channel| channel.monitored? && channel.warnable? }

      channels.each do |channel|
        blocks = WARNING_MESSAGE_BLOCKS.dup
        blocks[0][:block_id] = "#{Channel::WARNING_BLOCK_ID_PREFIX}-#{SecureRandom.uuid}"

        log.info("Warning ##{ENV["CI"] ? channel.id : channel.name}")

        Client.post_to(channel, blocks: blocks)
      end

      channels
    end

    def archive_channels
      channels = Client.list_public_channels.select { |channel| channel.monitored? && channel.archivable? }

      channels.each do |channel|
        log.info("Archiving ##{ENV["CI"] ? channel.id : channel.name}")

        Client.archive(channel)
      end

      channels
    end

    def post_report(archived, warned)
      return if Config.report_channel_id.blank?

      unless archived.empty?
        log.info("Reporting on archived channels")

        Client.post_to_id(
          Config.report_channel_id,
          blocks: [
            { type: "section", text: { type: "plain_text", text: "I have archived the following inactive channels:" } },
            {
              type: "section",
              text: {
                type: "mrkdwn",
                text: archived.map { |channel| ":file_folder: ##{channel.name}" }.join("\n")
              }
            }
          ]
        )
      end

      unless warned.empty?
        log.info("Reporting on warned channels")

        Client.post_to_id(
          Config.report_channel_id,
          blocks: [
            {
              type: "section",
              text: {
                type: "plain_text",
                text: "I will archive the following channels in a week if they remain inactive:"
              }
            },
            {
              type: "section",
              text: {
                type: "mrkdwn",
                text: warned.map { |channel| ":open_file_folder: ##{channel.name}" }.join("\n")
              }
            }
          ]
        )
      end
    end
  end
end
