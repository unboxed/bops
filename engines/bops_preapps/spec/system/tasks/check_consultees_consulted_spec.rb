# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Check consultees", type: :system do
  let(:local_authority) { create(:local_authority, :default) }
  let(:planning_application) { create(:planning_application, :pre_application, local_authority:) }
  let(:user) { create(:user, local_authority:) }

  before do
    sign_in(user)
    visit "/planning_applications/#{planning_application.reference}/assessment/tasks"
  end

  it "Can complete and submit the form" do
    within ".bops-sidebar" do
      click_link "Check consultees consulted"
    end
    click_button "Confirm as checked"

    review = planning_application.reload.consultation.current_review
    expect(review.review_type).to eq("consultees_checked")
    expect(review.status).to eq("complete")
  end
end
