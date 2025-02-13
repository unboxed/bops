# frozen_string_literal: true

require "rails_helper"

RSpec.describe Comment do
  describe "#valid?" do
    let(:comment) { build(:comment) }

    it "is true for factory" do
      expect(comment.valid?).to be(true)
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

  describe "#first?" do
    let(:evidence_group) { create(:evidence_group) }

    let(:comment) do
      create(:comment, commentable: evidence_group, created_at: 1.day.ago)
    end

    context "when there is no previous comment" do
      it "returns true" do
        expect(comment.first?).to be(true)
      end
    end

    context "when there is a previous comment" do
      before { create(:comment, commentable: evidence_group, created_at: 2.days.ago) }

      it "returns false" do
        expect(comment.first?).to be(false)
      end
    end

    context "when there is a previous deleted comment" do
      before do
        create(
          :comment,
          commentable: evidence_group,
          created_at: 3.days.ago,
          deleted_at: 1.day.ago
        )
      end

      it "returns true" do
        expect(comment.first?).to be(true)
      end
    end
  end

  describe "#deleted?" do
    context "when deleted_at is present" do
      let(:comment) { build(:comment, deleted_at: DateTime.current) }

      it "returns true" do
        expect(comment.deleted?).to be(true)
      end
    end

    context "when deleted_at is not present" do
      let(:comment) { build(:comment, deleted_at: nil) }

      it "returns false" do
        expect(comment.deleted?).to be(false)
      end
    end
  end
end
