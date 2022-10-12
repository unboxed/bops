# frozen_string_literal: true

require "rails_helper"

RSpec.describe AssessmentDetail, type: :model do
  describe "validations" do
    describe "#entry" do
      let(:summary_of_work) { create(:assessment_detail, :summary_of_work, entry: "") }
      let(:additional_evidence) { create(:assessment_detail, :additional_evidence, entry: "") }
      let(:site_description) { create(:assessment_detail, :site_description, entry: "") }

      let(:past_applications) do
        create(
          :assessment_detail,
          :past_applications,
          entry: "",
          status: status
        )
      end

      it "validates presence for summary of work" do
        expect { summary_of_work }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Entry can't be blank")
      end

      it "does not validate presence for additional evidence" do
        expect { additional_evidence }.not_to raise_error
      end

      it "validates presence for for site description" do
        expect { site_description }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Entry can't be blank")
      end

      context "when status is completed" do
        let(:status) { :completed }

        it "validates presence for assessment_detail" do
          expect { past_applications }.to raise_error(
            ActiveRecord::RecordInvalid,
            "Validation failed: Entry can't be blank"
          )
        end
      end

      context "when status is in_progress" do
        let(:status) { :in_progress }

        it "does not validates presence for assessment_detail" do
          expect { past_applications }.not_to raise_error
        end
      end
    end

    described_class.categories.each_key do |category_type|
      let(:category) { described_class.new(category: category_type) }

      describe "#status" do
        it "validates presence" do
          expect { category.valid? }.to change { category.errors[:status] }.to ["can't be blank"]
        end
      end

      describe "#user" do
        it "validates presence" do
          expect { category.valid? }.to change { category.errors[:user] }.to ["must exist"]
        end
      end

      describe "#planning_application" do
        it "validates presence" do
          expect { category.valid? }.to change { category.errors[:planning_application] }.to ["must exist"]
        end
      end

      describe "scopes" do
        describe ".by_created_at_desc" do
          let!(:"#{category_type}1") { create(:assessment_detail, :"#{category_type}", created_at: Time.zone.now - 1.day) }
          let!(:"#{category_type}2") { create(:assessment_detail, :"#{category_type}", created_at: Time.zone.now) }
          let!(:"#{category_type}3") { create(:assessment_detail, :"#{category_type}", created_at: Time.zone.now - 2.days) }

          it "returns #{category_type} sorted by created at desc (i.e. most recent first)" do
            expect(described_class.by_created_at_desc).to eq([send("#{category_type}2"), send("#{category_type}1"), send("#{category_type}3")])
          end
        end
      end
    end
  end
end
