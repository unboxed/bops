# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Planning Application show page", type: :system do
  let(:validated_at) { 10.business_days.until(Date.current) }
  let!(:api_user) { create :api_user }
  let!(:default_local_authority) { create(:local_authority, :default) }

  let(:proposal_details) do
    [
      {
        question: "What do you want to do?",
        responses: [{ value: "Modify or extend" }],
        metadata: { portal_name: "_root", auto_answered: true }
      },
      {
        question: "Is the property a house?",
        responses: [{ value: "Yes" }],
        metadata: { portal_name: "_root" }
      },
      {
        question: "What will the height of the new structure be?",
        responses: [{ value: "2.5m" }],
        metadata: { portal_name: "Dimensions", auto_answered: true }
      },
      {
        question: "Is the property in a world heritage site?",
        responses: [{ value: "No" }]
      }
    ].to_json
  end

  let!(:planning_application) do
    create(
      :planning_application,
      description: "Roof extension",
      application_type: "lawfulness_certificate",
      status: :in_assessment,
      validated_at: validated_at,
      local_authority: default_local_authority,
      payment_reference: "PAY123",
      payment_amount: 103.00,
      work_status: "proposed",
      uprn: "00773377",
      address_1: "7 Elm Grove",
      town: "London",
      postcode: "SE15 6UT",
      constraints: ["Conservation Area", "Listed Building"],
      api_user: api_user,
      proposal_details: proposal_details
    )
  end

  let(:assessor) { create :user, :assessor, local_authority: default_local_authority }

  context "as an assessor" do
    before do
      sign_in assessor
      visit planning_application_path(planning_application)
    end

    it "Site address is present" do
      expect(page).to have_text("7 Elm Grove, London, SE15 6UT")
    end

    it "Completed status is correct" do
      expect(page).to have_text("Work already started: No")
    end

    it "Planning application code is correct" do
      expect(page).to have_text("#{planning_application.created_at.year % 100}-00100-LDCP")
    end

    it "Target date is correct and label is turquoise" do
      expect(page).to have_text("Target date: #{planning_application.target_date}")
      expect(page).to have_css(".govuk-tag--turquoise")
      expect(page).to have_content("In assessment")
    end

    it "Applicant information accordion" do
      click_button "Application information"

      expect(page).to have_text("Site address: 7 Elm Grove, London, SE15 6UT")
      expect(page).to have_text("UPRN: 00773377")
      expect(page).to have_link("View site on Google Maps")
      expect(page).to have_text("Application type: Lawful Development Certificate (Proposed)")
      expect(page).to have_text("Description: Roof extension")
      expect(page).to have_text("PAY123")
      expect(page).to have_text("£103.00")

      within("#parish-name") do
        expect(page).to have_text("Parish:")
        expect(page).to have_text("Southwark, unparished area")
      end

      within("#ward") do
        expect(page).to have_text("Ward:")
        expect(page).to have_text("South Bermondsey")
        expect(page).to have_link(
          "View on mapit", href: "https://mapit.mysociety.org/postcode/SE156UT.html"
        )
      end

      within("#ward-type") do
        expect(page).to have_text("Ward type:")
        expect(page).to have_text("London borough ward")
        expect(page).to have_link(
          "View on mapit", href: "https://mapit.mysociety.org/postcode/SE156UT.html"
        )
      end
    end

    context "when no fee paid" do
      let!(:planning_application) do
        create(
          :planning_application,
          local_authority: default_local_authority,
          payment_reference: nil,
          payment_amount: nil
        )
      end

      it "shows the payment amount as £0.00" do
        visit planning_application_path(planning_application)
        click_button "Application information"

        expect(page).to have_row_for("Payment Amount", with: "£0.00")
        expect(page).to have_row_for("Payment Reference", with: "Exempt")
      end
    end

    it "Constraints accordion" do
      click_button "Constraints"

      expect(page).to have_text("Conservation Area")
    end

    it "Audit log accordion" do
      click_button "Audit log"

      expect(page).to have_text("Application received: #{planning_application.received_at}")
      expect(page).to have_text("Valid from: #{planning_application.valid_from}")
      expect(page).to have_text("Target date: #{planning_application.target_date}")
      expect(page).to have_text("Expiry date: #{planning_application.expiry_date}")
    end

    it "Result summary" do
      click_button "Result from #{api_user.name}"

      expect(page).to have_text("Planning permission / Permission needed")
      expect(page).to have_text(planning_application.result_heading)
      expect(page).to have_text(planning_application.result_description)
      expect(page).to have_text("Override")
    end

    it "displays the proposal details by group" do
      click_button("Proposal details")

      within("#proposal-details-section") do
        click_link("Main")

        expect(current_url).to have_target_id("main")

        group1 = find_all(".proposal-details-sub-list")[0]

        expect(group1).to have_content("1.  What do you want to do?")
        expect(group1).to have_content("2.  Is the property a house?")

        click_link("Dimensions")

        expect(current_url).to have_target_id("dimensions")

        group2 = find_all(".proposal-details-sub-list")[1]

        expect(group2).to have_content(
          "3.  What will the height of the new structure be?"
        )

        click_link("Other")

        expect(current_url).to have_target_id("other")

        group3 = find_all(".proposal-details-sub-list")[2]

        expect(group3).to have_content(
          "4.  Is the property in a world heritage site?"
        )
      end
    end

    it "lets user filter out auto answered proposal_details" do
      click_button("Proposal details")

      within("#proposal-details-section") do
        check("View ONLY applicant answers, hide 'Auto-answered by RIPA")

        expect(page).to have_link("Main")
        expect(page).not_to have_link("Dimensions")
        expect(page).to have_link("Other")

        group1 = find_all(".proposal-details-sub-list")[0]
        expect(group1).not_to have_content("1.  What do you want to do?")
        expect(group1).to have_content("2.  Is the property a house?")

        expect(page).not_to have_content(
          "3.  What will the height of the new structure be?"
        )

        group2 = find_all(".proposal-details-sub-list")[1]

        expect(group2).to have_content(
          "4.  Is the property in a world heritage site?"
        )
      end
    end

    it "lets user navigate back to top of proposal details section" do
      click_button("Proposal details")

      within("#proposal-details-section") do
        click_link("Dimensions")

        expect(current_url).to have_target_id("dimensions")

        first(:link, "Back to top").click

        expect(current_url).to have_target_id("accordion-default-heading-3")
      end
    end

    it "Contact information accordion" do
      click_button("Contact information")

      expect(page).to have_content("Applicant role type:")
      expect(page).to have_content(planning_application.user_role)

      expect(page).to have_content(planning_application.agent_first_name)
      expect(page).to have_content(planning_application.agent_last_name)
      expect(page).to have_content(planning_application.agent_phone)
      expect(page).to have_content(planning_application.agent_email)

      expect(page).to have_content(planning_application.applicant_first_name)
      expect(page).to have_content(planning_application.applicant_last_name)
      expect(page).to have_content(planning_application.applicant_phone)
      expect(page).to have_content(planning_application.applicant_email)
    end

    it "Consultation accordion" do
      click_button("Consultation")

      expect(page).to have_text("Consultation is not applicable for proposed permitted development.")
    end

    it "Application information accordion is minimised by default" do
      within(".govuk-grid-column-two-thirds.application") do
        expect(page).to have_button("Open all")
      end
    end

    it "Supporting information accordion is minimised by default" do
      within(".govuk-grid-column-one-third.supporting") do
        expect(page).to have_button("Open all")
      end
    end

    it "Assessment tasks are visible" do
      expect(page).to have_text("Submit recommendation")
    end
  end

  context "as an assessor when target date is within a week" do
    let(:validated_at) { 40.business_days.until(Date.current) }

    before do
      sign_in assessor
      visit planning_application_path(planning_application)
    end

    it "Breadcrumbs contain reference to Application overview which is not linked" do
      within(find(".govuk-breadcrumbs__list", match: :first)) do
        expect(page).to have_text "Application"
        expect(page).to have_no_link "Application"
      end
    end

    it "Breadcrumbs contain link to applications index" do
      expect(page).to have_text "Home"
      expect(page).to have_link "Home"
    end
  end

  context "when work status is existing" do
    before do
      sign_in assessor
      planning_application.update!(work_status: "existing")
      visit planning_application_path(planning_application)
    end

    it "displays the correct application type" do
      expect(page).to have_text("Application type: Lawful Development Certificate (Existing)")
    end
  end

  context "when no result fields are present" do
    let!(:planning_application) do
      create :planning_application, :without_result,
             local_authority: default_local_authority
    end

    before do
      sign_in assessor
      visit planning_application_path(planning_application)
    end

    it "displays the correct text in the result accordion when no API user is given" do
      click_button "Result from application"

      expect(page).to have_text("No result")
      expect(page).to have_text("The application was not assessed on submission")
    end

    it "displays the correct text in the result accordion when API user is present" do
      planning_application.update!(api_user: api_user)
      visit planning_application_path(planning_application)
      click_button "Result from #{api_user.name}"

      expect(page).to have_text("No result")
      expect(page).to have_text("#{api_user.name} did not provide a result for this application")
    end
  end

  context "when no postcode has been set" do
    let!(:planning_application) { create(:planning_application, local_authority: default_local_authority, postcode: "") }

    before do
      sign_in assessor
      visit planning_application_path(planning_application)
    end

    it "displays no ward information in the application information section" do
      click_button "Application information"

      within("#ward") do
        expect(page).to have_text("A postcode is required for ward information")
      end

      within("#ward-type") do
        expect(page).to have_text("A postcode is required for ward information")
      end
    end
  end

  context "when I update an address or boundary geojson field" do
    let!(:planning_application) { create(:planning_application, :with_boundary_geojson, local_authority: default_local_authority) }

    before do
      sign_in assessor
      visit planning_application_path(planning_application)
    end

    it "displays a warning message in relevant sections after the update" do
      # No warning text before an update
      click_button "Site map"
      within("#site-map-section") do
        expect(page).to have_no_css("#govuk-warning-text")
      end

      click_button "Result from application"
      within("#results-section") do
        expect(page).to have_no_css("#govuk-warning-text")
      end

      click_button "Proposal details"
      within("#proposal-details-section") do
        expect(page).to have_no_css("#govuk-warning-text")
      end

      click_button "Constraints"
      within("#constraints-section") do
        expect(page).to have_no_css("#govuk-warning-text")
      end

      # Update address
      click_button "Application information"
      click_link "Edit details"
      fill_in "Address 2", with: "Another address"
      click_button "Save"

      # Now we see a warning text in relevant sections
      click_button "Site map"
      within("#site-map-section .govuk-warning-text") do
        expect(page).to have_content("This application has been updated. Please check the site map is correct.")
      end

      click_button "Result from application"
      within("#results-section .govuk-warning-text") do
        expect(page).to have_content("! Warning This application has been updated. The result may no longer be accurate.")
      end

      click_button "Proposal details"
      within("#proposal-details-section .govuk-warning-text") do
        expect(page).to have_content("! Warning This application has been updated. The proposal details may no longer be accurate. Please check all relevant details have been provided.")
      end

      click_button "Constraints"
      within("#constraints-section .govuk-warning-text") do
        expect(page).to have_content("This application has been updated. Please check the constraints are correct.")
      end
    end
  end

  context "when there is feedback from the applicant/agent on the planning application" do
    let!(:planning_application) { create(:planning_application, :with_feedback, local_authority: default_local_authority) }

    before do
      sign_in assessor
      visit planning_application_path(planning_application)
    end

    it "displays a warning message and the feedback text" do
      click_button "Result from application"
      within("#results-section") do
        within(".govuk-warning-text") do
          expect(page).to have_content("! Warning The applicant or agent believes this result is inaccurate.")
        end

        expect(page).to have_content("Reason given: \"feedback about the result\"")
      end

      click_button "Proposal details"
      within("#proposal-details-section") do
        within(".govuk-warning-text") do
          expect(page).to have_content("! Warning The applicant or agent believes the information about the property is inaccurate.")
        end

        expect(page).to have_content("Reason given: \"feedback about the property\"")
      end

      click_button "Constraints"
      within("#constraints-section") do
        within(".govuk-warning-text") do
          expect(page).to have_content("! Warning The applicant or agent believes the constraints are inaccurate.")
        end

        expect(page).to have_content("Reason given: \"feedback about the constraints\"")
      end
    end
  end
end
