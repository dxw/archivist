module Archivist
  class Config
    class << self
      attr_reader :slack_client, :no_archive_label, :use_default_rules, :rules

      def configure
        ArchiveChannels.flush_cache

        @slack_client = Slack::Web::Client.new(token: ENV.fetch("ARCHIVIST_SLACK_API_TOKEN"))
        @no_archive_label = ENV.fetch("ARCHIVIST_NO_ARCHIVE_LABEL", nil)
        @use_default_rules = ENV.fetch("ARCHIVIST_DISABLE_DEFAULTS", nil).nil?
        @rules = parse_rules(ENV.fetch("ARCHIVIST_RULES", nil))

        self
      end

      private

      def parse_rules(rule_definitions)
        return [] if rule_definitions.nil?

        rules = rule_definitions
          .split(";")
          .map(&:strip)
          .map { |rule_definition|
            arguments = rule_definition
              .split(",")
              .map(&:strip)
              .map { |argument| argument.split("=").map(&:strip) }
              .to_h

            Rule.new(
              arguments.fetch("prefix"),
              days: arguments.fetch("days", "").to_i,
              skip: arguments.fetch("skip", "false") == "true"
            )
          }

        overlapping_rules = rules.select { |rule|
          rules.any? { |r| r != rule && rule.overlap?(r) }
        }

        if overlapping_rules.any?
          raise "The following rules overlap: #{overlapping_rules.map(&:prefix).join(", ")}"
        end

        rules
      end
    end
  end
end
