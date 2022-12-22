# frozen_string_literal: true

require "rails_helper"

RSpec.describe Policy do
  describe "#valid?" do
    let(:policy) { build(:policy) }

    it "is true for factory" do
      expect(policy.valid?).to be(true)
    end
  end

  describe ".complies" do
    before do
      create(:policy, :does_not_comply)
      create(:policy, :to_be_determined)
    end

    let!(:policy) { create(:policy, :complies) }

    it "returns policies with status of 'complies'" do
      expect(described_class.complies).to contain_exactly(policy)
    end
  end

  describe ".does_not_comply" do
    before do
      create(:policy, :complies)
      create(:policy, :to_be_determined)
    end

    let!(:policy) { create(:policy, :does_not_comply) }

    it "returns policies with status of 'does_not_comply'" do
      expect(described_class.does_not_comply).to contain_exactly(policy)
    end
  end

  describe ".to_be_determined" do
    before do
      create(:policy, :does_not_comply)
      create(:policy, :complies)
    end

    let!(:policy) { create(:policy, :to_be_determined) }

    it "returns policies with status of 'to_be_determined'" do
      expect(described_class.to_be_determined).to contain_exactly(policy)
    end
  end

  describe ".with_a_comment" do
    it "returns policies with a comment" do
      policy = create(:policy,
                      :complies,
                      section: "1A")

      create(:comment, commentable: policy)

      expect(described_class.with_a_comment).to eq [policy]
    end

    it "excludes policies without a comment" do
      create(:policy,
             :complies,
             section: "1A")

      expect(described_class.with_a_comment).to eq []
    end
  end

  describe ".existing_or_new_comment" do
    it "returns policies that do not comply" do
      policy = create(:policy,
                      :does_not_comply,
                      section: "1A")

      expect(described_class.commented_or_does_not_comply).to eq [policy]
    end

    %i[complies to_be_determined].each do |status|
      it "excludes policies that" do
        create(:policy,
               status,
               section: "1A")

        expect(described_class.commented_or_does_not_comply).to eq []
      end
    end

    %i[complies does_not_comply to_be_determined].each do |status|
      it "includes any commented legal clause" do
        policy = create(:policy,
                        status,
                        section: "1A")

        create(:comment, commentable: policy)

        expect(described_class.commented_or_does_not_comply).to eq [policy]
      end
    end

    it "orders by section" do
      last_section = create(:policy,
                            :does_not_comply,
                            section: "2B")
      first_section = create(:policy,
                             :complies,
                             section: "1A")

      create(:comment, commentable: first_section)

      expect(described_class.commented_or_does_not_comply).to eq [first_section, last_section]
    end
  end

  describe "#comment" do
    let(:policy) { create(:policy) }

    let!(:comment) do
      create(:comment, commentable: policy, created_at: 1.day.ago)
    end

    before do
      create(:comment, commentable: policy, created_at: 2.days.ago)
    end

    it "returns most recent persisted comment" do
      expect(policy.comment).to eq(comment)
    end

    context "when most recent comment is deleted" do
      before do
        create(
          :comment,
          commentable: policy,
          created_at: 1.day.ago,
          deleted_at: 1.hour.ago
        )
      end

      it "returns nil" do
        expect(policy.comment).to be_nil
      end
    end
  end

  describe "#previous_comments" do
    let(:policy) { create(:policy) }

    let!(:comment1) do
      create(:comment, commentable: policy, created_at: 1.day.ago)
    end

    let!(:comment2) do
      create(:comment, commentable: policy, created_at: 2.days.ago)
    end

    it "returns all but most recent comment" do
      expect(policy.previous_comments).to contain_exactly(comment2)
    end

    context "when most recent comment is deleted" do
      let!(:comment1) do
        create(
          :comment,
          commentable: policy,
          created_at: 1.day.ago,
          deleted_at: 1.hour.ago
        )
      end

      it "includes most recent comment" do
        expect(policy.previous_comments).to eq([comment2, comment1])
      end
    end
  end
end
