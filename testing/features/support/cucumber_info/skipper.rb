# frozen_string_literal: true

module CucumberInfo
  class Skipper
    include Helpers::EnvVariables

    attr_reader :tags
    private :tags

    def initialize(tags)
      @tags = tags
    end

    def skip_scenario?
      return AutomationLogger.error("Scenario does NOT work on mobile phones") if not_mobile_check
      return AutomationLogger.error("Scenario does NOT work on iOS12") if not_ios12_check
      return AutomationLogger.error("Scenario does NOT work on Tablets") if not_tablet_check

      false
    end

    private

    def not_mobile_check
      iphone? && tags.include?("@not_mobile")
    end

    def not_ios12_check
      ios12? && tags.include?("@not_ios12")
    end

    def not_tablet_check
      (ipad? && tags.include?("@not_tablet")) ||
        (ipad? && tags.include?("@small_screen"))
    end
  end
end
