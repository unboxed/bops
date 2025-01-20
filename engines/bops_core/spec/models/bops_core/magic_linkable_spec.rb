# frozen_string_literal: true

require "bops_core_helper"

RSpec.describe BopsCore::MagicLinkable, type: :model do
  let(:consultation) { create(:consultation) }
  let(:consultee) { create(:consultee, consultation:) }

  describe "#sgid" do
    it "generates a SGID with expiration time" do
      sgid = consultee.sgid(expires_in: 1.day, for: "magic_link")
      decoded = GlobalID::Locator.locate_signed(sgid, for: "magic_link")

      expect(decoded).to eq(consultee)
    end

    it "returns nil if SGID has expired" do
      sgid = consultee.sgid(expires_in: 1.second, for: "magic_link")
      travel 1.minute

      expect(GlobalID::Locator.locate_signed(sgid, for: "magic_link")).to be_nil
    end

    it "returns nil if SGID is invalid" do
      sgid = consultee.sgid(expires_in: 1.minute, for: "other_link")
      travel 1.minute

      expect(GlobalID::Locator.locate_signed(sgid, for: "magic_link")).to be_nil
    end
  end
end
