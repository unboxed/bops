# frozen_string_literal: true

ParameterType(
  name: "list",
  regexp: /"(.*)"/,
  transformer: ->(s) { s.split(/,\s+/) }
)

Given("I add the policy class(es) {list} to the application") do |classes|
  classes_step = classes.map { |name| "And I check \"Class #{name}\"" }.join("\n")

  steps %(
    Given I view the planning application
    And I press "Add assessment area"
    Then the page has a "Open legislation in new window" link with href "https://www.legislation.gov.uk/uksi/2015/596/schedule/2/made"
    And I choose "Part 1"
    And I press "Continue"
    #{classes_step}
    And I press "Add classes"
  )
end

Given("I remove the policy class(es) {list} from the application") do |classes|
  classes.each do |policy_class|
    steps %(
      Given I view the planning application
      And I press "Part 1, Class #{policy_class}"
      And I press "Remove class from assessment"
    )
  end
end

Then("there is a row for the {string} policy with a(n) {string} status") do |name, status|
  within("ul#assess-policy-section") do
    expect(page.find("li", text: name)).to have_text status
  end
end
