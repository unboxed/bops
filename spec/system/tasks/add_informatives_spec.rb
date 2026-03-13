# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Add informatives task", type: :system do
  let(:local_authority) { create(:local_authority, :default) }
  let!(:api_user) { create(:api_user, :planx, local_authority:) }
  let(:user) { create(:user, :assessor, local_authority:) }

  let(:planning_application) do
    create(:planning_application, :planning_permission, :in_assessment, local_authority:, api_user:, decision: "granted")
  end

  let(:task) { planning_application.case_record.find_task_by_slug_path!("check-and-assess/complete-assessment/add-informatives") }

  before do
    sign_in(user)
    visit "/planning_applications/#{planning_application.reference}"
    click_link "Check and assess"
  end

  it "can add a informative", capybara: true do
    within :sidebar do
      click_link "Add informatives"
    end

    expect(page).to have_content("No informatives added yet")
    toggle "Add new informative"
    fill_in "Enter title", with: "New custom informative"
    fill_in "Enter details of the informative", with: "Details of informative"
    click_button "Add informative"

    expect(page).to have_content("Informative was successfully added")
    expect(page).to have_content("New custom informative")
    expect(page).not_to have_content("No informatives added yet")
    expect(task.reload).to be_in_progress
  end

  it "validates informative fields" do
    within :sidebar do
      click_link "Add informatives"
    end

    toggle "Add new informative"
    click_button "Add informative"

    expect(page).to have_content("Enter informative")
    expect(page).to have_content("Enter details for this informative")
  end

  context "with existing informatives" do
    let!(:informative_set) { planning_application.informative_set }
    let!(:informative) { create(:informative, informative_set:) }
    let!(:informative_2) { create(:informative, informative_set:, title: "Informative 2", text: "Details about informative two") }

    it "can edit and informative and fields are pre-populated" do
      within :sidebar do
        click_link "Add informatives"
      end

      informative = planning_application.informative_set.informatives.first

      within("#informatives-list") do
        first(:link, "Edit").click
      end

      expect(page).to have_field("Enter title", with: informative.title)
      expect(page).to have_field("Enter details of the informative", with: informative.text)

      fill_in "Enter title", with: "Updated informative title"
      fill_in "Enter details of the informative", with: "Updated informative details"
      click_button "Save informative"

      expect(page).to have_content("Informative was successfully updated")
      expect(page).to have_content("Updated informative title")
    end

    it "can delete an informative", capybara: true do
      within :sidebar do
        click_link "Add informatives"
      end

      informatives_count = planning_application.informative_set.informatives.count

      within("#informatives-list") do
        accept_confirm do
          first(:link, "Remove").click
        end
      end

      expect(page).to have_content("Informative was successfully removed")
      expect(planning_application.informative_set.informatives.reload.count).to eq(informatives_count - 1)
    end
  end

  it "can mark informatives as complete" do
    within :sidebar do
      click_link "Add informatives"
    end

    click_button "Save and mark as complete"

    expect(page).to have_content("Informatives were successfully saved")
    expect(task.reload).to be_completed
  end

  it "can save as draft" do
    within :sidebar do
      click_link "Add informatives"
    end

    click_button "Save and come back later"

    expect(page).to have_content("Informatives draft was saved")
    expect(task.reload).to be_in_progress
  end

  context "when changing the list position" do
    let(:informative_set) { planning_application.informative_set }
    let!(:informative_one) { create(:informative, informative_set:, title: "Title 1", text: "Text 1", position: 1) }
    let!(:informative_two) { create(:informative, informative_set:, title: "Title 2", text: "Text 2", position: 2) }
    let!(:informative_three) { create(:informative, informative_set:, title: "Title 3", text: "Text 3", position: 3) }

    it "I can drag and drop to sort the informatives", :capybara, skip: "flaky" do
      within :sidebar do
        click_link "Add informatives"
      end
      expect(page).to have_selector("p", text: "Drag and drop informatives to change the order that they appear in the decision notice.")

      informative_one_handle = find("li.sortable-list", text: "Title 1")
      informative_two_handle = find("li.sortable-list", text: "Title 2")
      informative_three_handle = find("li.sortable-list", text: "Title 3")

      within("li.sortable-list:nth-of-type(1)") do
        expect(page).to have_selector("span", text: "Informative 1")
        expect(page).to have_selector("h2", text: "Title 1")
      end
      within("li.sortable-list:nth-of-type(2)") do
        expect(page).to have_selector("span", text: "Informative 2")
        expect(page).to have_selector("h2", text: "Title 2")
      end
      within("li.sortable-list:nth-of-type(3)") do
        expect(page).to have_selector("span", text: "Informative 3")
        expect(page).to have_selector("h2", text: "Title 3")
      end

      informative_one_handle.drag_to(informative_two_handle)

      within("li.sortable-list:nth-of-type(1)") do
        expect(page).to have_selector("span", text: "Informative 1")
        expect(page).to have_selector("h2", text: "Title 2")
      end
      within("li.sortable-list:nth-of-type(2)") do
        expect(page).to have_selector("span", text: "Informative 2")
        expect(page).to have_selector("h2", text: "Title 1")
      end
      within("li.sortable-list:nth-of-type(3)") do
        expect(page).to have_selector("span", text: "Informative 3")
        expect(page).to have_selector("h2", text: "Title 3")
      end
      expect(informative_one.reload.position).to eq(2)
      expect(informative_two.reload.position).to eq(1)
      expect(informative_three.reload.position).to eq(3)

      informative_one_handle.drag_to(informative_three_handle)

      within("li.sortable-list:nth-of-type(1)") do
        expect(page).to have_selector("span", text: "Informative 1")
        expect(page).to have_selector("h2", text: "Title 2")
      end
      within("li.sortable-list:nth-of-type(2)") do
        expect(page).to have_selector("span", text: "Informative 2")
        expect(page).to have_selector("h2", text: "Title 3")
      end
      within("li.sortable-list:nth-of-type(3)") do
        expect(page).to have_selector("span", text: "Informative 3")
        expect(page).to have_selector("h2", text: "Title 1")
      end
      expect(informative_one.reload.position).to eq(3)
      expect(informative_two.reload.position).to eq(1)
      expect(informative_three.reload.position).to eq(2)

      informative_three_handle.drag_to(informative_two_handle)

      within("li.sortable-list:nth-of-type(1)") do
        expect(page).to have_selector("span", text: "Informative 1")
        expect(page).to have_selector("h2", text: "Title 3")
      end
      within("li.sortable-list:nth-of-type(2)") do
        expect(page).to have_selector("span", text: "Informative 2")
        expect(page).to have_selector("h2", text: "Title 2")
      end
      within("li.sortable-list:nth-of-type(3)") do
        expect(page).to have_selector("span", text: "Informative 3")
        expect(page).to have_selector("h2", text: "Title 1")
      end
      expect(informative_one.reload.position).to eq(3)
      expect(informative_two.reload.position).to eq(2)
      expect(informative_three.reload.position).to eq(1)

      # Check the correct order on decision notice
      create(:recommendation, :assessment_in_progress, planning_application:)
      click_link "Back"
      within "#main-content" do
        click_link("Review and submit recommendation")
      end

      within("#informatives-list") do
        expect(page).to have_selector("li:nth-of-type(1)", text: "Title 3")
        expect(page).to have_selector("li:nth-of-type(2)", text: "Title 2")
        expect(page).to have_selector("li:nth-of-type(3)", text: "Title 1")
      end
    end
  end
end
