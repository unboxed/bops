# frozen_string_literal: true

require "rails_helper"

RSpec.describe "assigning planning application" do
  let(:local_authority) { create(:local_authority, :default) }
  let(:reviewer) { create(:user, :reviewer, local_authority:) }

  let!(:assessor) do
    create(
      :user,
      :assessor,
      local_authority:,
      name: "Jane Smith"
    )
  end

  let(:planning_application) do
    create(
      :planning_application,
      local_authority:
    )
  end

  context "when an LDC type" do
    it "lets a planning application be assigned to a user" do
      travel_to("2022-01-01")
      sign_in(reviewer)
      visit(planning_application_assign_users_path(planning_application))
      select("Jane Smith")
      click_button("Confirm")

      expect(page).to have_content("Assigned to: Jane Smith")

      perform_enqueued_jobs
      update_notification = ActionMailer::Base.deliveries.last

      expect(update_notification.to).to contain_exactly(assessor.email)

      expect(update_notification.subject).to eq(
        "BoPS case PlanX-22-00100-LDCP has a new update"
      )

      expect(Audit.last).to have_attributes(
        planning_application_id: planning_application.id,
        activity_type: "assigned",
        activity_information: "Jane Smith",
        user_id: reviewer.id
      )

      travel_back
    end
  end

  context "when a prior approval type" do
    before do
      prior_approval = create(:application_type, :prior_approval)
      planning_application.update(application_type: prior_approval)
    end

    it "lets a planning application be assigned to a user" do
      travel_to("2022-01-01")
      sign_in(reviewer)
      visit(planning_application_assign_users_path(planning_application))
      select("Jane Smith")
      click_button("Confirm")

      expect(page).to have_content("Assigned to: Jane Smith")

      perform_enqueued_jobs
      update_notification = ActionMailer::Base.deliveries.last

      expect(update_notification.to).to contain_exactly(assessor.email)

      expect(update_notification.subject).to include(
        "You have been assigned to a prior approval case"
      )

      expect(Audit.last).to have_attributes(
        planning_application_id: planning_application.id,
        activity_type: "assigned",
        activity_information: "Jane Smith",
        user_id: reviewer.id
      )

      travel_back
    end
  end

  context "when a planning application is assigned" do
    let(:planning_application) do
      create(
        :planning_application,
        local_authority:,
        user: assessor
      )
    end

    it "can be unnassigned" do
      sign_in(reviewer)
      visit(planning_application_assign_users_path(planning_application))
      select("Unassigned")
      click_button("Confirm")

      expect(page).to have_content("Assigned to: Unassigned")
    end
  end

  context "when there is an ActiveRecord Error raised" do
    before do
      allow_any_instance_of(PlanningApplication).to receive(:assign!).and_raise(ActiveRecord::ActiveRecordError, "an error message")
    end

    it "there is an error message and no update is persisted" do
      sign_in(reviewer)

      visit(planning_application_assign_users_path(planning_application))
      select("Jane Smith")
      click_button("Confirm")

      expect(page).to have_content("Couldn't assign user with error: an error message. Please contact support.")
    end
  end
end
