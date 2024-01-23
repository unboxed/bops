# frozen_string_literal: true

require "rails_helper"

RSpec.describe "cloning a planning application" do
  let!(:local_authority) { create(:local_authority, :default) }
  let(:assessor) { create(:user, :assessor, local_authority:) }
  let(:api_user) { create(:api_user) }

  let!(:planning_application) do
    create(
      :planning_application,
      :from_planx,
      local_authority:,
      api_user:
    )
  end

  before do
    allow_any_instance_of(PlanningApplication).to receive(:can_clone?).and_return(true)

    sign_in(assessor)
    visit "/planning_applications/#{planning_application.id}"
  end

  context "when using v1 params" do
    before do
      stub_request(:get, "https://bops-upload-test.s3.eu-west-2.amazonaws.com/proposed-first-floor-plan.pdf")
        .to_return(
          status: 200,
          body: Rails.root.join("spec/fixtures/images/proposed-first-floor-plan.pdf").read,
          headers: {"Content-Type" => "application/pdf"}
        )
    end

    context "when I am able to clone a planning application" do
      it "I am successfully redirected to the cloned planning application" do
        # It does not send a receipt notice mail
        expect(PlanningApplicationMailer).not_to receive(:receipt_notice_mail)

        accept_confirm(text: "This will clone the planning application identical to how it was created via PlanX. Are you sure?") do
          click_link("Clone")
        end

        expect(page).to have_content("Planning application was successfully cloned")

        expect(PlanningApplication.all.count).to eq(2)

        cloned_planning_application = PlanningApplication.last
        expect(page).to have_current_path("/planning_applications/#{cloned_planning_application.id}")
        expect(page).to have_content("Planning application was successfully cloned")

        expect(JSON.parse(planning_application.params_v1)).to eq(JSON.parse(cloned_planning_application.params_v1))
        expect(planning_application.reference).not_to eq(cloned_planning_application.reference)
      end
    end

    context "when there is an error cloning a planning application" do
      before { allow_any_instance_of(PlanningApplication).to receive(:save!).and_raise(ActiveRecord::RecordInvalid) }

      it "I am presented with the error" do
        accept_confirm(text: "This will clone the planning application identical to how it was created via PlanX. Are you sure?") do
          click_link("Clone")
        end

        within(".govuk-notification-banner--alert") do
          expect(page).to have_content("Error cloning application with message: Record invalid.")
        end

        expect(PlanningApplication.all.count).to eq(1)
      end
    end

    context "when can_clone? returns false" do
      before { allow_any_instance_of(PlanningApplication).to receive(:can_clone?).and_return(false) }

      it "I am unable to clone and presented with an error" do
        accept_confirm(text: "This will clone the planning application identical to how it was created via PlanX. Are you sure?") do
          click_link("Clone")
        end

        within(".govuk-notification-banner--alert") do
          expect(page).to have_content("Cloning is not permitted in production")
        end

        expect(PlanningApplication.all.count).to eq(1)
      end
    end
  end

  context "when using v2 params" do
    let!(:planning_application) do
      create(
        :planning_application,
        :with_v2_params,
        local_authority:,
        api_user:
      )
    end

    let!(:application_type_pp) { create(:application_type, :planning_permission) }

    context "when I am able to clone a planning application" do
      it "I am successfully redirected to the cloned planning application" do
        # It does not send a receipt notice mail
        expect(PlanningApplicationMailer).not_to receive(:receipt_notice_mail)

        accept_confirm(text: "This will clone the planning application identical to how it was created via PlanX. Are you sure?") do
          click_link("Clone")
        end

        expect(page).to have_content("Planning application was successfully cloned")

        expect(PlanningApplication.all.count).to eq(2)

        cloned_planning_application = PlanningApplication.last
        expect(page).to have_current_path("/planning_applications/#{cloned_planning_application.id}")
        expect(page).to have_content("Planning application was successfully cloned")

        expect(planning_application.params_v2).to eq(cloned_planning_application.params_v2)
        expect(planning_application.reference).not_to eq(cloned_planning_application.reference)
      end
    end

    context "when there is an error cloning a planning application" do
      before { allow_any_instance_of(PlanningApplication).to receive(:save!).and_raise(ActiveRecord::RecordInvalid) }

      it "I am presented with the error" do
        accept_confirm(text: "This will clone the planning application identical to how it was created via PlanX. Are you sure?") do
          click_link("Clone")
        end

        within(".govuk-notification-banner--alert") do
          expect(page).to have_content("Error cloning application with message: Record invalid.")
        end

        expect(PlanningApplication.all.count).to eq(1)
      end
    end
  end

  context "when planning application was not created via PlanX i.e. there is no params_v1 value" do
    let(:planning_application) { create(:planning_application, local_authority:) }

    it "I am unable to clone and presented with an error" do
      visit "/planning_applications/#{planning_application.id}"

      accept_confirm(text: "This will clone the planning application identical to how it was created via PlanX. Are you sure?") do
        click_link("Clone")
      end

      within(".govuk-notification-banner--alert") do
        expect(page).to have_content("Planning application can not be cloned as it was not created via PlanX")
      end

      expect(PlanningApplication.all.count).to eq(1)
    end
  end
end
