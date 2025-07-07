# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Assess immunity detail permitted development right", type: :system do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }

  let(:planning_application) do
    create(:planning_application, :in_assessment, local_authority: default_local_authority)
  end

  let!(:immunity_detail) do
    create(:immunity_detail, planning_application:)
  end

  let(:reference) { planning_application.reference }

  context "when assessing whether an application is immune" do
    before do
      sign_in assessor
      visit "/planning_applications/#{reference}"
      click_link("Check and assess")
      click_link("Immunity/permitted development rights")
    end

    context "when there are validation errors" do
      it "displays an error if an option for the decision has not been selected" do
        click_button "Save and mark as complete"

        expect(page).to have_content("There is a problem")
        expect(page).to have_content("Select Yes or No for whether the development is immune")
      end

      it "displays an error if no reason for a 'Yes' decision has been given" do
        choose "Yes, the development is immune"
        click_button "Save and mark as complete"

        expect(page).to have_content("Select one of the reasons why the development is immune")
        expect(page).to have_content("Enter a summary of the evidence and history provided as to why this development is immune")
      end

      it "displays an error if no reason or response to permitted development rights for a 'No' decision has been given" do
        choose "No, the development is not immune"
        click_button "Save and mark as complete"

        expect(page).to have_content("Enter a reason as to why this development is not immune")
        expect(page).to have_content("Select Yes or No for whether the permitted development rights have been removed")
      end

      it "displays an error if no reason for removing permitted development rights has been given" do
        choose "No, the development is not immune"
        choose "Yes, permitted development rights have been removed"
        click_button "Save and mark as complete"

        expect(page).to have_content("Enter the reason as to why the permitted development rights have been removed")
      end
    end

    context "when viewing the content", :capybara do
      before do
        Capybara.ignore_hidden_elements = true
      end

      after do
        Capybara.ignore_hidden_elements = false
      end

      it "I see the relevant information" do
        expect(page).to have_content("Immunity/permitted development rights")
        expect(page).to have_css("#planning-application-details")
        expect(page).to have_css("#constraints-section")
        expect(page).to have_css("#planning-history-section")

        expect(page).to have_content("On the balance of probabilities, is the development immune from enforcement action?")
        expect(page).not_to have_field("Immunity from enforcement summary")
        expect(page).not_to have_content("Have the permitted development rights relevant for this application been removed?")

        choose "Yes, the development is immune"
        expect(page).to have_field("Immunity from enforcement summary")
        expect(page).not_to have_content("Have the permitted development rights relevant for this application been removed?")

        choose "No, the development is not immune"
        expect(page).not_to have_field("Immunity from enforcement summary")
        expect(page).to have_content("Have the permitted development rights relevant for this application been removed?")
      end
    end

    context "when I assess whether the application is immune from enforcement" do
      it "I can choose 'Yes' and select a reason" do
        choose "Yes, the development is immune"

        expect(page).to have_field("No action has been taken within 10 years of substantial completion for a breach of planning control consisting of operational development where substantial completion took place on or after 25 April 2024")
        expect(page).to have_field("No action has been taken within 10 years for an unauthorised change of use to a single dwellinghouse where the change of use took place on or after 25 April 2024")
        expect(page).to have_field("No action has been taken within 4 years of substantial completion for a breach of planning control consisting of operational development where substantial completion took place before 25 April 2024")
        expect(page).to have_field("No action has been taken within 4 years for an unauthorised change of use to a single dwellinghouse where the change of use took place before 25 April 2024")
        expect(page).to have_field("No action has been taken within 10 years for any other breach of planning control (essentially other changes of use)")

        choose "No action has been taken within 4 years for an unauthorised change of use to a single dwellinghouse"
        fill_in "Immunity from enforcement summary", with: "A summary"

        click_button "Save and mark as complete"
        expect(page).to have_content("Immunity/permitted development rights response was successfully updated")

        expect(Review.enforcement.last).to have_attributes(
          owner_id: immunity_detail.id,
          assessor_id: assessor.id,
          status: "complete",
          review_status: "review_not_started",
          action: nil,
          specific_attributes: {
            "decision" => "Yes",
            "decision_reason" => "No action has been taken within 4 years for an unauthorised change of use to a single dwellinghouse where the change of use took place before 25 April 2024",
            "decision_type" => "unauthorised-change-before-2024-04-25",
            "summary" => "A summary",
            "review_type" => "enforcement"
          }
        )

        within("#immunity-permitted-development-rights") do
          expect(page).to have_link(
            "Immunity/permitted development rights",
            href: planning_application_assessment_assess_immunity_detail_permitted_development_right_path(planning_application)
          )
          expect(page).to have_content("Completed")
        end
      end

      it "I can choose 'Yes' and give an other reason" do
        choose "Yes, the development is immune"
        choose "Other reason"
        fill_in "Provide the other reason why this development is immune", with: "A reason for my decision"
        fill_in "Immunity from enforcement summary", with: "A summary"

        click_button "Save and mark as complete"
        expect(page).to have_content("Immunity/permitted development rights response was successfully updated")

        expect(Review.enforcement.last).to have_attributes(
          owner_id: immunity_detail.id,
          assessor_id: assessor.id,
          status: "complete",
          review_status: "review_not_started",
          specific_attributes: {
            "decision" => "Yes",
            "decision_reason" => "A reason for my decision",
            "decision_type" => "other",
            "summary" => "A summary",
            "review_type" => "enforcement"
          }
        )

        expect(PermittedDevelopmentRight.all.length).to eq(0)
      end

      it "I choose 'Yes' after originally selecting 'No'" do
        choose "No, the development is not immune"
        fill_in "Describe why the application is not immune from enforcement", with: "Application is not immune"

        choose "Yes, permitted development rights have been removed"
        fill_in "Describe how permitted development rights have been removed", with: "A reason"

        choose "Yes, the development is immune"
        choose "Other reason"
        fill_in "Provide the other reason why this development is immune", with: "A reason for my decision"
        fill_in "Immunity from enforcement summary", with: "A summary"

        click_button "Save and mark as complete"
        expect(page).to have_content("Immunity/permitted development rights response was successfully updated")

        expect(Review.where(owner_type: "ImmunityDetail").length).to eq(1)
        # No permitted development right response is created
        expect(PermittedDevelopmentRight.all.length).to eq(0)
      end

      it "I can choose 'No' and respond to the permitted development rights" do
        choose "No, the development is not immune"
        fill_in "Describe why the application is not immune from enforcement", with: "Application is not immune"

        choose "Yes, permitted development rights have been removed"
        fill_in "Describe how permitted development rights have been removed", with: "A reason"

        click_button "Save and mark as complete"
        expect(page).to have_content("Immunity/permitted development rights response was successfully updated")

        expect(Review.enforcement.last).to have_attributes(
          owner_id: immunity_detail.id,
          assessor_id: assessor.id,
          specific_attributes: {
            "decision" => "No",
            "decision_reason" => "Application is not immune",
            "review_type" => "enforcement"
          }
        )

        expect(PermittedDevelopmentRight.last).to have_attributes(
          assessor_id: assessor.id,
          removed: true,
          removed_reason: "A reason",
          status: "complete"
        )
      end

      it "I can view and edit my response", :capybara do
        choose "No, the development is not immune"
        fill_in "Describe why the application is not immune from enforcement", with: "Application is not immune"

        choose "Yes, permitted development rights have been removed"
        fill_in "Describe how permitted development rights have been removed", with: "A reason"

        click_button "Save and mark as complete"
        expect(page).to have_content("Immunity/permitted development rights response was successfully updated")

        # View show page
        click_link "Immunity/permitted development rights"

        expect(page).to have_content("Immunity/permitted development rights")
        expect(page).to have_css("#planning-application-details")
        expect(page).to have_css("#constraints-section")
        expect(page).to have_css("#planning-history-section")
        expect(page).to have_css(".immunity-section")

        expect(page).to have_content("Have the permitted development rights relevant for this application been removed?")
        expect(page).to have_content("Yes")
        expect(page).to have_content("A reason")

        expect(page).to have_content("On the balance of probabilities, is the development immune from enforcement action?")
        expect(page).not_to have_content("Immunity from enforcement summary")
        expect(page).to have_content("Assessor decision: No")
        expect(page).to have_content("Reason: Application is not immune")
        expect(page).to have_content("On the balance of probabilities, is the development immune from enforcement action?")

        # View edit page
        click_link "Edit immunity/permitted development rights"

        expect(page).to have_unchecked_field("Yes, the development is immune")
        expect(page).to have_checked_field("No, the development is not immune")
        expect(page).to have_field("Describe why the application is not immune from enforcement", with: "Application is not immune")

        expect(page).to have_checked_field("Yes, permitted development rights have been removed")
        expect(page).to have_unchecked_field("No, permitted development rights have not been removed")
        expect(page).to have_field("Describe how permitted development rights have been removed", with: "A reason")

        choose "Yes, the development is immune"
        choose "No action has been taken within 4 years for an unauthorised change of use to a single dwellinghouse"

        fill_in "Immunity from enforcement summary", with: "A summary"

        click_button "Save and mark as complete"
        expect(page).to have_content("Immunity/permitted development rights response was successfully updated")

        click_link "Immunity/permitted development rights"
        expect(page).to have_selector("h1", text: "Immunity/permitted development rights")

        click_link "Edit immunity/permitted development rights"
        expect(page).to have_content("On the balance of probabilities, is the development immune from enforcement action?")

        expect(page).to have_checked_field("Yes, the development is immune")
        expect(page).to have_unchecked_field("No, the development is not immune")
        expect(page).to have_checked_field("No action has been taken within 4 years for an unauthorised change of use to a single dwellinghouse")
        expect(page).to have_field("Immunity from enforcement summary", with: "A summary")

        click_button "Save and mark as complete"
        expect(page).to have_content("Immunity/permitted development rights response was successfully updated")

        expect(Review.enforcement.last).to have_attributes(
          owner_id: immunity_detail.id,
          assessor_id: assessor.id,
          specific_attributes: {
            "decision" => "Yes",
            "decision_reason" => "No action has been taken within 4 years for an unauthorised change of use to a single dwellinghouse where the change of use took place before 25 April 2024",
            "decision_type" => "unauthorised-change-before-2024-04-25",
            "review_type" => "enforcement",
            "summary" => "A summary"
          }
        )

        click_link "Immunity/permitted development rights"

        expect(page).not_to have_content("Have the permitted development rights relevant for this application been removed?")

        expect(page).to have_content("On the balance of probabilities, is the development immune from enforcement action?")
        expect(page).not_to have_content("Immunity from enforcement summary")
        expect(page).to have_content("Assessor decision: Yes")
        expect(page).to have_content("Reason: No action has been taken within 4 years for an unauthorised change of use to a single dwellinghouse")
        expect(page).to have_content("Summary: A summary")
      end
    end
  end

  context "when there is an open review" do
    let!(:review) do
      create(
        :review,
        :enforcement,
        owner: immunity_detail,
        decision: "Yes",
        decision_type: "other",
        decision_reason: "There is another reason",
        summary: "There is enough evidence"
      )
    end

    before do
      sign_in assessor
    end

    it "uses the existing review on the new page" do
      visit "/planning_applications/#{reference}/assessment/assess_immunity_detail_permitted_development_rights/new"

      expect(page).to have_checked_field("Yes, the development is immune")
      expect(page).to have_checked_field("Other reason")
      expect(page).to have_field("Provide the other reason why this development is immune", with: "There is another reason")
      expect(page).to have_field("Immunity from enforcement summary", with: "There is enough evidence")
    end
  end

  context "when planning application has not been validated yet" do
    let!(:planning_application) do
      create(:planning_application, :not_started, local_authority: default_local_authority)
    end

    it "does not allow me to visit the page" do
      sign_in assessor
      visit "/planning_applications/#{reference}"

      expect(page).not_to have_link("Immunity/permitted development rights")

      visit "/planning_applications/#{reference}/assessment/permitted_development_rights"

      expect(page).to have_content("The planning application must be validated before assessment can begin")
    end
  end

  context "when planning application is not possibly immune" do
    before { allow_any_instance_of(PlanningApplication).to receive(:possibly_immune?).and_return(false) }

    it "does not allow me to visit the page" do
      sign_in assessor
      visit "/planning_applications/#{reference}"

      click_link "Check and assess"
      expect(page).not_to have_link("Immunity/permitted development rights")

      expect {
        visit "/planning_applications/#{reference}/assessment/assess_immunity_detail_permitted_development_rights/new"
      }.to raise_error(BopsCore::Errors::ForbiddenError, "Planning application can't be immune")
    end
  end

  context "when it has no evidence attached" do
    it "I can view the information on the permitted development rights page" do
      create(:immunity_detail, planning_application:)
      sign_in assessor
      visit "/planning_applications/#{reference}/assessment/assess_immunity_detail_permitted_development_rights/new"

      expect(page).to have_content("Evidence cover: Unknown")
      expect(page).to have_content("Missing evidence (gap in time): No")
    end
  end

  context "when it has evidence attached" do
    let(:immunity_detail) do
      create(:immunity_detail, planning_application:)
    end

    before do
      sign_in assessor
    end

    it "lists the evidence in a single group for a single document" do
      document = create(:document, tags: %w[councilTaxBill])
      immunity_detail.add_document(document)
      visit "/planning_applications/#{reference}/assessment/assess_immunity_detail_permitted_development_rights/new"

      expect(page).to have_content("Council tax bills (1)")
    end

    it "lists the evidence in a single group for multiple documents of the same kind" do
      document1 = create(:document, tags: %w[councilTaxBill])
      document2 = create(:document, tags: %w[councilTaxBill])
      immunity_detail.add_document(document1)
      immunity_detail.add_document(document2)
      visit "/planning_applications/#{reference}/assessment/assess_immunity_detail_permitted_development_rights/new"

      expect(page).to have_content("Council tax bills (2)")
    end

    it "lists the evidence in multiple groups for multiple documents of different kind" do
      document1 = create(:document, tags: %w[councilTaxBill])
      document2 = create(:document, tags: %w[photographs.existing])
      immunity_detail.add_document(document1)
      immunity_detail.add_document(document2)
      visit "/planning_applications/#{reference}/assessment/assess_immunity_detail_permitted_development_rights/new"

      expect(page).to have_content("Council tax bills (1)")
      expect(page).to have_content("Photographs - existings (1)")
    end
  end
end
