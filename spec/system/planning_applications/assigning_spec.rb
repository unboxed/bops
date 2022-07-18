# frozen_string_literal: true

require "rails_helper"

RSpec.describe "assigning planning application", type: :system do
  let(:local_authority) { create(:local_authority, :default) }
  let(:reviewer) { create(:user, :reviewer, local_authority: local_authority) }

  let!(:assessor) do
    create(
      :user,
      :assessor,
      local_authority: local_authority,
      name: "Jane Smith"
    )
  end

  let(:planning_application) do
    create(
      :planning_application,
      local_authority: local_authority,
      created_at: DateTime.new(2022, 1, 1)
    )
  end

  it "lets a planning application be assigned to a user" do
    sign_in(reviewer)
    visit(assign_planning_application_path(planning_application))
    choose("Jane Smith")
    click_button("Confirm")

    expect(page).to have_content("Assigned to: Jane Smith")

    perform_enqueued_jobs
    update_notification = ActionMailer::Base.deliveries.last

    expect(update_notification.to).to contain_exactly(assessor.email)

    expect(update_notification.subject).to eq(
      "BoPS case RIPA-22-00100-LDCP has a new update"
    )
  end
end
