# frozen_string_literal: true

AfterConfiguration do
  CucumberInfo.set_session_id
end

Before do |test_case|
  CucumberInfo.test_case = test_case
  skip_this_scenario("Scenario is not permitted to run. See logs for details") if CucumberInfo.skip_scenario?
  I18n.locale = :en
  resize_window unless device?
  resize_window(320) if test_case.source_tag_names.include?("@small_screen") && !device?
  AutomationLogger.info("Running Scenario: #{test_case.name}")
  AutomationLogger.debug("BROWSERSTACK_CONFIGURATION_OPTIONS = #{ENV['BROWSERSTACK_CONFIGURATION_OPTIONS']}")
  AutomationLogger.debug("DOCKER_TAG = #{ENV['DOCKER_TAG']}")
end

After do |test_case|
  if test_case.failed?
    save_window_screenshot(test_case) unless device?
    AutomationLogger.info("Scenario: #{test_case.name} - Status: FAILED")
    AutomationLogger.error("ERROR: #{test_case.exception&.message}")
    AutomationLogger.error("ERROR TYPE: #{test_case.exception.class}")
    test_case.exception&.backtrace&.each&.with_index(1) do |backtrace_line, index|
      AutomationLogger.error("BACKTRACE #{index}) #{backtrace_line}")
    end
    CucumberInfo.scenario_result = "failed"
  else
    AutomationLogger.info("Scenario: #{test_case.name} - Status: #{test_case.status.upcase}")
  end
end
