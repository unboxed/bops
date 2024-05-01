# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Add informatives" do
  let(:default_local_authority) { create(:local_authority, :default) }
  let!(:api_user) { create(:api_user, name: "PlanX", local_authority: default_local_authority) }
  let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }

  let!(:planning_application) do
    create(:planning_application, :planning_permission, :in_assessment, local_authority: default_local_authority, api_user:, decision: "granted")
  end

  before do
    create(:local_authority_informative, local_authority: default_local_authority, title: "Section 106", text: "Must do 106")
    allow(Current).to receive(:user).and_return assessor

    sign_in assessor
    visit "/planning_applications/#{planning_application.id}"
    click_link "Check and assess"
  end

  it "I can add informatives", js: true do
    within("#add-informatives") do
      expect(page).to have_content "Not started"
      click_link "Add informatives"
    end

    expect(page).to have_selector("h1", text: "Add informatives")
    expect(page).to have_content "No informatives added yet"

    fill_in "Start typing to choose an informative from a list", with: "Section"
    page.find(:xpath, "//li[text()='Section 106']").click

    click_button "Add informative"

    expect(page).to have_content "Informative successfully added"

    expect(page).to have_content "Must do 106"

    page.find(:xpath, "//span[contains(text(), 'Add a custom informative')]").click

    expect(page).to have_content "Add a custom informative"

    fill_in "manual-title-input", with: "Informative 1"
    fill_in "manual-text-input", with: "Consider the trees"

    click_button "Add informative"

    expect(page).to have_content "Informative successfully added"

    expect(page).to have_content "Consider the trees"

    page.find(:xpath, "//span[contains(text(), 'Add a custom informative')]").click

    fill_in "manual-title-input", with: "Informative 2"
    fill_in "manual-text-input", with: "Consider the park"

    click_button "Add informative"

    expect(page).to have_content "Consider the park"

    click_link "Assess application"

    within("#add-informatives") do
      expect(page).to have_content "In progress"
    end

    click_link "Add informatives"

    click_link "Save and mark as complete"

    within("#add-informatives") do
      expect(page).to have_content "Completed"
    end
  end

  it "I can save and come back later" do
    within("#add-informatives") do
      expect(page).to have_content "Not started"
      click_link "Add informatives"
    end

    expect(page).to have_content "No informatives added yet"

    fill_in "Start typing to choose an informative from a list", with: "Section"
    page.find(:xpath, "//li[text()='Section 106']").click

    click_button "Save and come back later"

    expect(page).to have_content "Informative successfully added"

    within("#add-informatives") do
      expect(page).to have_content "In progress"
      click_link "Add informatives"
    end

    expect(page).to have_content "Must do 106"

    page.find(:xpath, "//span[contains(text(), 'Add a custom informative')]").click

    expect(page).to have_content "Add a custom informative"

    fill_in "manual-title-input", with: "Informative 1"
    fill_in "manual-text-input", with: "Consider the trees"

    click_button "Save and come back later"

    expect(page).to have_content "Informative successfully added"

    within("#add-informatives") do
      expect(page).to have_content "In progress"
      click_link "Add informatives"
    end

    expect(page).to have_content "Consider the trees"

    click_link "Save and mark as complete"

    within("#add-informatives") do
      expect(page).to have_content "Completed"
    end
  end

  it "I can edit informatives" do
    informative = create(:informative, informative_set: planning_application.informative_set)

    within("#add-informatives") do
      click_link "Add informatives"
    end

    expect(page).to have_content informative.text

    click_link "Edit"

    expect(page).to have_content "Edit informative"

    fill_in "manual-title-input", with: "My new title"
    fill_in "manual-text-input", with: "The new detail"

    click_button "Save informative"

    expect(page).to have_content "Informative successfully added"

    expect(page).to have_content "My new title"
    expect(page).to have_content "The new detail"
  end

  it "I can delete informatives" do
    informative = create(:informative, informative_set: planning_application.informative_set)

    within("#add-informatives") do
      click_link "Add informatives"
    end

    expect(page).to have_content informative.text

    click_link "Remove"

    expect(page).to have_content "Informative was successfully removed"
    expect(page).to have_content "No informatives added yet"
  end

  context "when changing the list position" do
    let(:informative_set) { planning_application.informative_set }
    let!(:informative_one) { create(:informative, informative_set:, title: "Title 1", text: "Text 1", position: 1) }
    let!(:informative_two) { create(:informative, informative_set:, title: "Title 2", text: "Text 2", position: 2) }
    let!(:informative_three) { create(:informative, informative_set:, title: "Title 3", text: "Text 3", position: 3) }

    it "I can drag and drop to sort the informatives" do
      click_link "Add informatives"
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

      click_link "Back"
      click_link "Add informatives"

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

      # Check the correct order on decision notice
      create(:recommendation, :assessment_in_progress, planning_application:)
      click_link "Back"
      click_link "Review and submit recommendation"

      within("#informatives-list") do
        expect(page).to have_selector("li:nth-of-type(1)", text: "Title 3")
        expect(page).to have_selector("li:nth-of-type(2)", text: "Title 2")
        expect(page).to have_selector("li:nth-of-type(3)", text: "Title 1")
      end
    end
  end

  it "shows errors" do
    click_link "Add informatives"

    expect(page).to have_content "No informatives added yet"

    click_button "Add informative"

    expect(page).to have_content "Fill in the title of the informative"
    expect(page).to have_content "Fill in the text of the informative"

    fill_in "manual-title-input", with: "My new title"
    fill_in "manual-text-input", with: "The new detail"

    click_button "Add informative"

    expect(page).to have_content "Informative successfully added"

    expect(page).to have_content "The new detail"

    click_link "Edit"

    expect(page).to have_content "Edit informative"

    fill_in "manual-title-input", with: ""
    fill_in "manual-text-input", with: ""

    click_button "Save informative"

    expect(page).to have_content "Fill in the title of the informative"
    expect(page).to have_content "Fill in the text of the informative"

    fill_in "manual-title-input", with: "My newer title"
    fill_in "manual-text-input", with: "The newer detail"

    click_button "Save informative"

    expect(page).to have_content "Informative successfully added"

    expect(page).to have_content "The newer detail"

    page.find(:xpath, "//span[contains(text(), 'Add a custom informative')]").click

    fill_in "manual-title-input", with: "My newer title"
    fill_in "manual-text-input", with: "The newer detail"

    click_button "Add informative"

    expect(page).to have_content("Title has already been taken")
    expect(page).to have_content("Text has already been taken")
  end

  it "I can mark the task as complete" do
    within("#add-informatives") do
      click_link "Add informatives"
    end

    click_link "Save and mark as complete"

    within("#add-informatives") do
      expect(page).to have_content "Complete"
    end
  end

  it "I can mark the task as complete and then add more informatives if I need to" do
    within("#add-informatives") do
      click_link "Add informatives"
    end

    click_link "Save and mark as complete"

    within("#add-informatives") do
      expect(page).to have_content "Complete"
    end

    click_link "Add informatives"

    click_link "+ Add informative"

    page.find(:xpath, "//span[contains(text(), 'Add a custom informative')]").click

    fill_in "manual-title-input", with: "Informative 1"
    fill_in "manual-text-input", with: "Consider the trees"

    click_button "Add informative"

    expect(page).to have_content "Informative successfully added"
    expect(page).to have_content "Informative 1"
    expect(page).to have_content "Consider the trees"

    click_link "Save and mark as complete"

    expect(page).to have_content "Informatives successfully saved"

    within("#add-informatives") do
      expect(page).to have_content "Complete"
    end
  end

  it "shows informatives on the decision notice" do
    create(:recommendation, :assessment_in_progress, planning_application:)
    informative = create(:informative, informative_set: planning_application.informative_set)

    visit "/planning_applications/#{planning_application.id}"
    click_link "Check and assess"
    click_link "Review and submit recommendation"

    expect(page).to have_content "Informatives"
    expect(page).to have_content informative.title
    expect(page).to have_content informative.text
  end
end
