# frozen_string_literal: true

RSpec.shared_examples "Sortable" do |class_name|
  it "I can drag and drop to sort the items" do # rubocop:disable Rspec/ExampleLength
    expect(page).to have_selector("p", text: "Drag and drop #{class_name.pluralize} to change the order that they appear in the decision notice.")

    condition_one_handle = find("li.sortable-list", text: "Title 1")
    condition_two_handle = find("li.sortable-list", text: "Title 2")
    condition_three_handle = find("li.sortable-list", text: "Title 3")

    within("li.sortable-list:nth-of-type(1)") do
      expect(page).to have_selector("span", text: "Condition 1")
      expect(page).to have_selector("h2", text: "Title 1")
    end
    within("li.sortable-list:nth-of-type(2)") do
      expect(page).to have_selector("span", text: "Condition 2")
      expect(page).to have_selector("h2", text: "Title 2")
    end
    within("li.sortable-list:nth-of-type(3)") do
      expect(page).to have_selector("span", text: "Condition 3")
      expect(page).to have_selector("h2", text: "Title 3")
    end

    condition_one_handle.drag_to(condition_two_handle)

    within("li.sortable-list:nth-of-type(1)") do
      expect(page).to have_selector("span", text: "Condition 1")
      expect(page).to have_selector("h2", text: "Title 2")
    end
    within("li.sortable-list:nth-of-type(2)") do
      expect(page).to have_selector("span", text: "Condition 2")
      expect(page).to have_selector("h2", text: "Title 1")
    end
    within("li.sortable-list:nth-of-type(3)") do
      expect(page).to have_selector("span", text: "Condition 3")
      expect(page).to have_selector("h2", text: "Title 3")
    end
    expect(condition_one.reload.position).to eq(2)
    expect(condition_two.reload.position).to eq(1)
    expect(condition_three.reload.position).to eq(3)

    condition_one_handle.drag_to(condition_three_handle)

    within("li.sortable-list:nth-of-type(1)") do
      expect(page).to have_selector("span", text: "Condition 1")
      expect(page).to have_selector("h2", text: "Title 2")
    end
    within("li.sortable-list:nth-of-type(2)") do
      expect(page).to have_selector("span", text: "Condition 2")
      expect(page).to have_selector("h2", text: "Title 3")
    end
    within("li.sortable-list:nth-of-type(3)") do
      expect(page).to have_selector("span", text: "Condition 3")
      expect(page).to have_selector("h2", text: "Title 1")
    end
    expect(condition_one.reload.position).to eq(3)
    expect(condition_two.reload.position).to eq(1)
    expect(condition_three.reload.position).to eq(2)

    condition_three_handle.drag_to(condition_two_handle)

    within("li.sortable-list:nth-of-type(1)") do
      expect(page).to have_selector("span", text: "Condition 1")
      expect(page).to have_selector("h2", text: "Title 3")
    end
    within("li.sortable-list:nth-of-type(2)") do
      expect(page).to have_selector("span", text: "Condition 2")
      expect(page).to have_selector("h2", text: "Title 2")
    end
    within("li.sortable-list:nth-of-type(3)") do
      expect(page).to have_selector("span", text: "Condition 3")
      expect(page).to have_selector("h2", text: "Title 1")
    end
    expect(condition_one.reload.position).to eq(3)
    expect(condition_two.reload.position).to eq(2)
    expect(condition_three.reload.position).to eq(1)

    click_link "Back"
    click_link "Add #{class_name.pluralize}"

    within("li.sortable-list:nth-of-type(1)") do
      expect(page).to have_selector("span", text: "Condition 1")
      expect(page).to have_selector("h2", text: "Title 3")
    end
    within("li.sortable-list:nth-of-type(2)") do
      expect(page).to have_selector("span", text: "Condition 2")
      expect(page).to have_selector("h2", text: "Title 2")
    end
    within("li.sortable-list:nth-of-type(3)") do
      expect(page).to have_selector("span", text: "Condition 3")
      expect(page).to have_selector("h2", text: "Title 1")
    end

    if condition_set.pre_commencement?
      # Check the correct order on decision notice
      click_button "Confirm and send to applicant"
      condition_set.validation_requests.each { |vr| vr.update(approved: true) }
      create(:recommendation, :assessment_in_progress, planning_application:)
      click_link "Back"
      click_link "Review and submit recommendation"

      within("#conditions-list") do
        expect(page).to have_selector("li:nth-of-type(1)", text: "Title 3")
        expect(page).to have_selector("li:nth-of-type(2)", text: "Title 2")
        expect(page).to have_selector("li:nth-of-type(3)", text: "Title 1")
      end
    end
  end
end
