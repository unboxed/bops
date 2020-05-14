# frozen_string_literal: true

RSpec::Matchers.define :have_completed_tag do
  match do |page|
    page.find(:xpath, "./strong[@class=\"govuk-tag app-task-list__task-completed\"]")
  end
end
