# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Planning application updated tab spec" do
  let!(:local_authority) { create(:local_authority, :default) }

  let!(:user) { create(:user, name: "Assigned Officer") }
  let!(:assessor) { create(:user, :assessor, local_authority: local_authority) }

  let!(:audit1) { create(:audit, created_at: 3.days.ago, planning_application: planning_application1, activity_type: "approved") }
  let!(:audit2) { create(:audit, created_at: 1.day.ago, planning_application: planning_application2, activity_type: "challenged") }
  let!(:audit3) { create(:audit, created_at: 4.days.ago, planning_application: planning_application3, activity_type: "determined") }
  let!(:audit4) { create(:audit, created_at: 2.days.ago, planning_application: planning_application2) }
  let!(:audit5) { create(:audit, created_at: 5.days.ago, planning_application: planning_application3) }
  let!(:audit6) { create(:audit, created_at: 6.days.ago, planning_application: planning_application3) }
  let!(:audit7) { create(:audit, created_at: 5.days.ago, planning_application: planning_application4, user: user) }

  let(:planning_application1) do
    travel_to(10.days.ago) { create(:planning_application, local_authority: local_authority) }
  end
  let(:planning_application2) do
    travel_to(10.days.ago) { create(:planning_application, local_authority: local_authority) }
  end
  let(:planning_application3) do
    travel_to(10.days.ago) { create(:planning_application, local_authority: local_authority) }
  end
  # Create planning application that has an officer assigned
  let(:planning_application4) do
    travel_to(10.days.ago) { create(:planning_application, user: user) }
  end

  before do
    sign_in(assessor)
    visit(root_path)

    click_link "Updated"
  end

  it "lists the applications with the latest audit log entry" do
    expect(page).to have_content("This list shows applications which have been recently updated by a user other than the assigned officer.")

    within("#updated") do
      expect(page).to have_content("Updated")

      within("#planning_application_#{audit1.planning_application.id}") do
        expect(page).to have_content("23-00100-LDCP")
        expect(page).to have_content(audit1.planning_application.full_address)
        expect(page).to have_content(audit1.planning_application.description)
      end

      within("#audit_#{audit1.id}") do
        within(".govuk-inset-text") do
          expect(page).to have_content("Update: Recommendation approved")
          expect(page).to have_content(audit1.created_at.to_fs)
        end
      end

      within("#audit_#{audit2.id}") do
        within(".govuk-inset-text") do
          expect(page).to have_content("Update: Recommendation challenged")
          expect(page).to have_content(audit2.created_at.to_fs)
        end
      end

      within("#audit_#{audit3.id}") do
        within(".govuk-inset-text") do
          expect(page).to have_content("Update: Decision Published")
          expect(page).to have_content(audit3.created_at.to_fs)
        end
      end

      expect(page).not_to have_css("#audit_#{audit4.id}")
      expect(page).not_to have_css("#audit_#{audit5.id}")
      expect(page).not_to have_css("#audit_#{audit6.id}")
      expect(page).not_to have_css("#audit_#{audit7.id}")
    end

    # Now perform an update to a planning application
    visit edit_planning_application_path(planning_application2)

    fill_in "planning_application[payment_amount]", with: "105.00"

    click_button("Save")
    visit(root_path)
    click_link "Updated"

    within("#audit_#{Audit.last.id}") do
      within(".govuk-inset-text") do
        expect(page).to have_content("Update: Payment amount updated Changed from: £0.00 Changed to: £105.00")
      end
    end

    expect(page).to have_css("#planning_application_#{Audit.last.planning_application.id}")

    # Update takes precedent over the previous audit entry for the same planning application
    expect(page).not_to have_css("#audit_#{audit2.id}")
  end

  context "when there are updated planning applications outside my local authority" do
    let!(:other_local_authority) { create(:local_authority, :lambeth) }
    let!(:other_audit) { create(:audit, created_at: 1.day.ago, planning_application: other_planning_application) }

    let(:other_planning_application) do
      travel_to(10.days.ago) { create(:planning_application, local_authority: other_local_authority) }
    end

    it "doesn't show this planning application" do
      expect(page).not_to have_css("#audit_#{other_audit.id}")
      expect(page).not_to have_css("#planning_application_#{other_planning_application.id}")
    end
  end
end
