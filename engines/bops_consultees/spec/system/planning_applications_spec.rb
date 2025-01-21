# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Planning applications", type: :system do
  let!(:local_authority) { create(:local_authority, :default) }
  let!(:planning_application) { create(:planning_application, :pre_application, local_authority:) }
  let!(:consultation) { create(:consultation, planning_application:) }
  let(:consultee) { create(:consultee, consultation:) }
  let(:sgid) { consultee.sgid(expires_in: 1.day, for: "magic_link") }
  let(:reference) { planning_application.reference }

  before do
    visit "/consultees/planning_applications/#{reference}?sgid=#{sgid}"
  end

  context "with valid magic link" do
    it "I can view the planning_application" do
      expect(page).to have_current_path("/consultees/planning_applications/#{reference}?sgid=#{sgid}")
      expect(page).to have_content(planning_application.full_address)
      expect(page).to have_content("Application number #{reference}")
    end
  end

  context "with expired magic link" do
    let!(:sgid) { consultee.sgid(expires_in: 1.minute, for: "magic_link") }

    it "I can see that the link has expired" do
      travel 2.minutes
      visit "/consultees/planning_applications/#{reference}?sgid=#{sgid}"
      expect(page).not_to have_content(planning_application.full_address)
      expect(page).not_to have_content(reference)
      expect(page).to have_content("Your magic link has expired. Click resend to generate another link.")
    end
  end

  context "with expired magic link for other sgid purpose" do
    let!(:sgid) { consultee.sgid(expires_in: 1.minute, for: "other_link") }

    it "I can't view the planning_application" do
      travel 2.minutes
      visit "/consultees/planning_applications/#{reference}?sgid=#{sgid}"
      expect(page).not_to have_content(reference)
      expect(page).not_to have_content("Your magic link has expired. Click resend to generate another link.")
      expect(page).to have_content("Not found")
    end
  end

  context "with invalid sgid" do
    let!(:sgid) { consultee.sgid(expires_in: 1.day, for: "other_link") }

    it "I can't view the planning application" do
      expect(page).not_to have_content(reference)
      expect(page).to have_content("Not found")
    end
  end

  context "without sgid" do
    let!(:sgid) { nil }

    it "I can't view the planning application" do
      expect(page).not_to have_content(reference)
      expect(page).to have_content("Not found")
    end
  end
end
