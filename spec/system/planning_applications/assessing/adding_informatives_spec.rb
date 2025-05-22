# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Add informatives", type: :system do
  let(:default_local_authority) { create(:local_authority, :default) }
  let!(:api_user) { create(:api_user, :planx, local_authority: default_local_authority) }
  let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }
  let(:reference) { planning_application.reference }

  shared_examples "an application type that supports informatives" do
    before do
      create(:local_authority_informative, local_authority: default_local_authority, title: "Section 106", text: "Must do 106")
      allow(Current).to receive(:user).and_return assessor

      sign_in assessor
      visit "/planning_applications/#{planning_application.reference}"
      click_link "Check and assess"
    end

    it "I can add informatives", js: true do
      within("#add-informatives") do
        expect(page).to have_content "Not started"
        click_link "Add informatives"
      end

      expect(page).to have_selector("h1", text: "Add informatives")
      expect(page).to have_content "No informatives added yet"
      expect(page).to have_selector("details[open]")

      fill_in "Enter a title", with: "Section"
      pick "Section 106", from: "#informative-title-field"

      click_button "Add informative"
      expect(page).to have_current_path("/planning_applications/#{reference}/assessment/informatives/edit")

      # The page redirects back to itself so sometimes have_current_path doesn't wait for the redirect
      with_retry do
        expect(page).to have_content "Informative was successfully added"
      end

      expect(page).to have_content "Must do 106"
      expect(page).to have_no_selector("details[open]")

      toggle "Add new informative"

      fill_in "Enter a title", with: "Informative 1"
      fill_in "Enter details of the informative", with: "Consider the trees"

      click_button "Add informative"
      expect(page).to have_current_path("/planning_applications/#{reference}/assessment/informatives/edit")

      # The page redirects back to itself so sometimes have_current_path doesn't wait for the redirect
      with_retry do
        expect(page).to have_content "Informative was successfully added"
      end

      expect(page).to have_content "Consider the trees"
      expect(page).to have_no_selector("details[open]")

      toggle "Add new informative"

      fill_in "Enter a title", with: "Informative 2"
      fill_in "Enter details of the informative", with: "Consider the park"

      click_button "Add informative"
      expect(page).to have_current_path("/planning_applications/#{reference}/assessment/informatives/edit")

      expect(page).to have_content "Consider the park"
      expect(page).to have_no_selector("details[open]")

      click_link "Assess application"

      within("#add-informatives") do
        expect(page).to have_content "In progress"
        click_link "Add informatives"
      end

      expect(page).to have_selector("h1", text: "Add informatives")
      expect(page).to have_no_selector("details[open]")

      click_button "Save and mark as complete"
      expect(page).to have_current_path("/planning_applications/#{reference}/assessment/tasks")

      within("#add-informatives") do
        expect(page).to have_content "Completed"
      end
    end

    it "I can save and come back later", :capybara do
      within("#add-informatives") do
        expect(page).to have_content "Not started"
        click_link "Add informatives"
      end

      expect(page).to have_selector("h1", text: "Add informatives")
      expect(page).to have_content "No informatives added yet"
      expect(page).to have_selector("details[open]")

      fill_in "Enter a title", with: "Section"
      pick "Section 106", from: "#informative-title-field"

      expect(page).to have_field "Enter details of the informative", with: "Must do 106"

      click_button "Add informative"
      expect(page).to have_current_path("/planning_applications/#{reference}/assessment/informatives/edit")

      # The page redirects back to itself so sometimes have_current_path doesn't wait for the redirect
      with_retry do
        expect(page).to have_content "Informative was successfully added"
      end

      click_button "Save and come back later"
      expect(page).to have_current_path("/planning_applications/#{reference}/assessment/tasks")
      expect(page).to have_content("Informatives were successfully saved")

      within("#add-informatives") do
        expect(page).to have_content "In progress"
        click_link "Add informatives"
      end

      expect(page).to have_content "Must do 106"
      expect(page).to have_no_selector("details[open]")

      toggle "Add new informative"

      fill_in "Enter a title", with: "Informative 1"
      fill_in "Enter details of the informative", with: "Consider the trees"

      click_button "Add informative"
      expect(page).to have_current_path("/planning_applications/#{reference}/assessment/informatives/edit")

      # The page redirects back to itself so sometimes have_current_path doesn't wait for the redirect
      with_retry do
        expect(page).to have_content "Informative was successfully added"
      end

      expect(page).to have_content "Consider the trees"
      expect(page).to have_no_selector("details[open]")

      click_button "Save and come back later"
      expect(page).to have_current_path("/planning_applications/#{reference}/assessment/tasks")

      within("#add-informatives") do
        expect(page).to have_content "In progress"
        click_link "Add informatives"
      end

      click_button "Save and mark as complete"
      expect(page).to have_current_path("/planning_applications/#{reference}/assessment/tasks")

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

      fill_in "informative-title-field", with: "My new title"
      fill_in "informative-text-field", with: "The new detail"

      click_button "Save informative"
      expect(page).to have_current_path("/planning_applications/#{reference}/assessment/informatives/edit")

      expect(page).to have_content "Informative was successfully saved"

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

      it "I can drag and drop to sort the informatives", :capybara, skip: "flaky" do
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

      fill_in "Enter a title", with: "My new title"
      fill_in "Enter details of the informative", with: "The new detail"

      click_button "Add informative"
      expect(page).to have_current_path("/planning_applications/#{reference}/assessment/informatives/edit")

      # The page redirects back to itself so sometimes have_current_path doesn't wait for the redirect
      with_retry do
        expect(page).to have_content "Informative was successfully added"
      end

      expect(page).to have_content "The new detail"

      click_link "Edit"

      expect(page).to have_content "Edit informative"

      fill_in "Enter a title", with: ""
      fill_in "Enter details of the informative", with: ""

      click_button "Save informative"
      expect(page).to have_current_path(%r{^/planning_applications/#{reference}/assessment/informatives/items/\d+})

      expect(page).to have_content "Fill in the title of the informative"
      expect(page).to have_content "Fill in the text of the informative"

      fill_in "Enter a title", with: "My newer title"
      fill_in "Enter details of the informative", with: "The newer detail"

      click_button "Save informative"
      expect(page).to have_current_path("/planning_applications/#{reference}/assessment/informatives/edit")

      expect(page).to have_content "Informative was successfully saved"
      expect(page).to have_content "The newer detail"

      fill_in "Enter a title", with: "My newer title"
      fill_in "Enter details of the informative", with: "The newer detail"

      click_button "Add informative"
      expect(page).to have_current_path("/planning_applications/#{reference}/assessment/informatives")

      expect(page).to have_content("There is already an informative with this title")
    end

    it "I can mark the task as complete" do
      within("#add-informatives") do
        click_link "Add informatives"
      end

      click_button "Save and mark as complete"
      expect(page).to have_current_path("/planning_applications/#{reference}/assessment/tasks")

      within("#add-informatives") do
        expect(page).to have_content "Complete"
      end
    end

    it "I can mark the task as complete and then add more informatives if I need to" do
      within("#add-informatives") do
        click_link "Add informatives"
      end

      click_button "Save and mark as complete"

      within("#add-informatives") do
        expect(page).to have_content "Complete"
      end

      click_link "Add informatives"
      expect(page).to have_selector("h1", text: "Add informatives")

      click_link "Edit informatives"
      expect(page).to have_selector("legend", text: "Add a new informative")
      expect(page).to have_selector("details[open]")

      fill_in "Enter a title", with: "Informative 1"
      fill_in "Enter details of the informative", with: "Consider the trees"

      click_button "Add informative"
      expect(page).to have_current_path("/planning_applications/#{reference}/assessment/informatives/edit")

      # The page redirects back to itself so sometimes have_current_path doesn't wait for the redirect
      with_retry do
        expect(page).to have_content "Informative was successfully added"
      end

      expect(page).to have_content "Informative 1"
      expect(page).to have_content "Consider the trees"
      expect(page).to have_no_selector("details[open]")

      click_button "Save and mark as complete"

      expect(page).to have_content "Informatives were successfully saved"

      within("#add-informatives") do
        expect(page).to have_content "Complete"
      end
    end

    it "shows informatives on the decision notice" do
      create(:recommendation, :assessment_in_progress, planning_application:)
      informative = create(:informative, informative_set: planning_application.informative_set)

      visit "/planning_applications/#{planning_application.reference}"
      click_link "Check and assess"
      click_link "Review and submit recommendation"

      expect(page).to have_content "Informatives"
      expect(page).to have_content informative.title
      expect(page).to have_content informative.text
    end
  end

  context "when the application is a full planning permission" do
    let!(:planning_application) do
      create(:planning_application, :planning_permission, :in_assessment, local_authority: default_local_authority, api_user:, decision: "granted")
    end

    it_behaves_like "an application type that supports informatives"
  end

  context "when the application is a LDC for a proposed development" do
    let!(:planning_application) do
      create(:planning_application, :ldc_proposed, :in_assessment, local_authority: default_local_authority, api_user:, decision: "granted")
    end

    it_behaves_like "an application type that supports informatives"
  end

  context "when the application is a LDC for an existing development" do
    let!(:planning_application) do
      create(:planning_application, :ldc_existing, :in_assessment, local_authority: default_local_authority, api_user:, decision: "granted")
    end

    it_behaves_like "an application type that supports informatives"
  end
end
