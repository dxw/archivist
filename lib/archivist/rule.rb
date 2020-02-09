module Archivist
  class Rule
    attr_reader :prefix, :days

    def initialize(prefix, days: nil)
      @prefix = prefix

      @days = days unless days.nil? || days.zero?
    end
  end
end
