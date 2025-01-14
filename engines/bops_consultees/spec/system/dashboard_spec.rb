# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Dashboard", type: :system do
  let!(:local_authority) { create(:local_authority, :default) }
  let(:consultation) { create(:consultation) }
  let(:consultee) { create(:consultee, consultation:) }
  let(:sgid) { consultee.sgid(expires_in: 1.day, for: "magic_link") }

  before do
    visit "/consultees/dashboard?sgid=#{sgid}"
  end

  context "with valid magic link" do
    it "I can view the dashboard" do
      expect(page).to have_current_path("/consultees/dashboard?sgid=#{sgid}")
      expect(page).to have_content("BOPS consultees")
    end
  end

  context "with expired magic link" do
    let!(:sgid) { consultee.sgid(expires_in: 1.minute, for: "magic_link") }

    it "I can't view the dashboard" do
      travel 2.minutes
      visit "/consultees/dashboard?sgid=#{sgid}"
      expect(page).not_to have_content("BOPS consultees")
      expect(page).to have_content("Magic link expired")
    end
  end

  context "with expired magic link for other sgid purpose" do
    let!(:sgid) { consultee.sgid(expires_in: 1.minute, for: "other_link") }

    it "I can't view the dashboard" do
      travel 2.minutes
      visit "/consultees/dashboard?sgid=#{sgid}"
      expect(page).not_to have_content("BOPS consultees")
      expect(page).not_to have_content("Magic link expired")
      expect(page).to have_content("Forbidden")
    end
  end

  context "with invalid sgid" do
    let!(:sgid) { consultee.sgid(expires_in: 1.day, for: "other_link") }

    it "I can't view the dashboard" do
      expect(page).not_to have_content("BOPS consultees")
      expect(page).to have_content("Forbidden")
    end
  end

  context "without sgid" do
    let!(:sgid) { nil }

    it "I can't view the dashboard" do
      expect(page).not_to have_content("BOPS consultees")
      expect(page).to have_content("Not Found")
    end
  end
end
