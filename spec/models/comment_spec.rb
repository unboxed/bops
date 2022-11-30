# frozen_string_literal: true

require "rails_helper"

RSpec.describe Comment do
  describe "#valid?" do
    let(:comment) { build(:comment) }

    it "is true for factory" do
      expect(comment.valid?).to be(true)
    end
  end

  describe "#edited?" do
    context "when created_at and updated_at are the same" do
      let(:comment) { create(:comment) }

      it "returns false" do
        expect(comment.edited?).to be(false)
      end
    end

    context "when created_at and updated_at are different" do
      let(:comment) { create(:comment, created_at: 1.day.ago) }

      it "returns true" do
        expect(comment.edited?).to be(true)
      end
    end
  end

  describe "#save" do
    let(:user) { create(:user) }
    let(:comment) { build(:comment) }

    before { Current.user = user }

    it "sets the user" do
      comment.save
      expect(comment.user).to eq(user)
    end
  end
end
