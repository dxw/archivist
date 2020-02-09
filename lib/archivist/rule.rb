module Archivist
  class Rule
    attr_reader :prefix, :days

    def initialize(prefix, days: nil)
      @prefix = prefix

      @days = days unless days.nil? || days.zero?
    end

    def match?(channel)
      channel.name.start_with?(prefix)
    end

    def overlap?(rule)
      rule.prefix.start_with?(prefix) || prefix.start_with?(rule.prefix)
    end
  end
end
