# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Decision notice" do
  let(:local_authority) { create(:local_authority, :default) }
  let(:application_type) { create(:application_type, :planning_permission) }
  let(:planning_application) do
    create(:planning_application, :determined, application_type:, local_authority:, decision:)
  end
  let(:decision) { "granted" }

  context "when not logged in" do
    before do
      visit "/public/planning_applications/#{planning_application.reference}/decision_notice"
    end

    context "when planning application has been determined" do
      it "shows a publicly available decision notice" do
        expect(page).to have_content("Decision notice")

        within(".govuk-tag.govuk-tag--green") do
          expect(page).to have_content("Granted")
        end

        expect(page).to have_css(".decision-notice")
      end

      context "when decision is to grant" do
        it "shows conditions on the notice" do
          expect(page).to have_selector("h3", text: "Conditions:")
        end

        context "when a pre-commencement condition has been approved but later cancelled" do
          let(:user) { create(:user, local_authority:) }
          let(:planning_application) do
            create(:planning_application, :awaiting_determination, application_type:, local_authority:, decision: "granted")
          end

          before do
            Current.user = user

            condition_set = planning_application.pre_commencement_condition_set
            approved_condition = create(:condition, condition_set:, title: "Approved condition")
            cancelled_condition = create(:condition, condition_set:, title: "Cancelled condition")

            create(:pre_commencement_condition_validation_request, owner: approved_condition, approved: true, state: "closed")
            create(:pre_commencement_condition_validation_request, owner: cancelled_condition, approved: true, state: "closed")
            cancelled_condition.update!(cancelled_at: Time.zone.today)

            planning_application.determine!

            visit "/public/planning_applications/#{planning_application.reference}/decision_notice"
          end

          it "does not show cancelled conditions on the notice" do
            within("#conditions-list") do
              expect(page).to have_content("Approved condition")
              expect(page).not_to have_content("Cancelled condition")
            end
          end
        end
      end

      context "when decision is to refuse" do
        let(:decision) { "refused" }

        it "does not show conditions on the notice" do
          expect(page).not_to have_selector("h3", text: "Conditions:")
        end
      end

      context "when local authority has an engagement statement" do
        let(:local_authority) do
          create(:local_authority, :default, engagement_statement: "We take a proactive approach and work positively with applicants.")
        end

        it "shows the proactive engagement section" do
          expect(page).to have_selector("h3", text: "Proactive engagement")
          expect(page).to have_content("We take a proactive approach and work positively with applicants.")
        end
      end

      context "when local authority does not have an engagement statement" do
        let(:local_authority) { create(:local_authority, :default, engagement_statement: nil) }

        it "does not show the proactive engagement section" do
          expect(page).not_to have_selector("h3", text: "Proactive engagement")
        end
      end
    end

    context "when planning application has not been determined" do
      let!(:planning_application) do
        create(:planning_application, :awaiting_determination, local_authority:)
      end

      it "shows a not found page" do
        expect(page).not_to have_content("Decision notice")
        expect(page).to have_content("Not Found")
      end
    end
  end

  context "when logged in" do
    let(:user) { create(:user, local_authority:) }

    before do
      sign_in(user)

      visit "/public/planning_applications/#{planning_application.reference}/decision_notice"
    end

    it "is accessible" do
      expect(page).to have_content("Decision notice")
    end
  end
end
