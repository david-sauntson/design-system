# frozen_string_literal: true

Given("the Default Footer component is on the page") do
  @component = Footer::Default.new.tap(&:load)
end

Given("the Minimal Footer component is on the page") do
  @component = Footer::Minimal.new.tap(&:load)
end

Then("a report problem with this page link is present") do
  expect(@component).to have_website_feedback(text: I18n.t("cads.footer.website_feedback"))
end

Then("each header item has at least 1 link below it") do
  expect(@component.category_titles).to all have_links
end

Then("a copyright notice is present") do
  expect(@component).to have_copyright(text: I18n.t("cads.shared.copyright"))
end

Then("a company info is present") do
  expect(@component).to have_company_info
end
