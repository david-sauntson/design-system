# frozen_string_literal: true

Given("an Example Error Summary component is on the page") do
  @component = ErrorSummary::Example.new.tap(&:load)
end

Then("the component indicates there is a problem") do
  expect(@component).to have_heading
end

Then("the component shows the errors in a list format") do
  expect(@component).to have_errors
end
