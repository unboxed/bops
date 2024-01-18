# frozen_string_literal: true

require "rails_helper"

RSpec.describe AssessmentDetail do
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
          assessment_status:
        )
      end

      let(:consultation_summary) do
        create(
          :assessment_detail,
          :consultation_summary,
          entry: "",
          assessment_status:
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

      context "when assessment_status is complete" do
        let(:assessment_status) { :complete }

        it "validates presence for consultation_summary" do
          expect { consultation_summary }.to raise_error(
            ActiveRecord::RecordInvalid,
            "Validation failed: Entry can't be blank"
          )
        end
      end

      context "when assessment_status is in_progress" do
        let(:assessment_status) { :in_progress }

        it "does not validates presence for past_applications" do
          expect { past_applications }.not_to raise_error
        end

        it "does not validates presence for consultation_summary" do
          expect { consultation_summary }.not_to raise_error
        end
      end
    end

    describe "#assessment_status" do
      it "defaults to 'not_started'" do
        expect(described_class.new.assessment_status).to eq("not_started")
      end
    end

    described_class.categories.each_key do |category_type|
      let(:category) { described_class.new(category: category_type) }

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
        let(:planning_application) { create(:planning_application) }

        describe ".by_created_at_desc" do
          let!("#{category_type}1") do
            create(
              :assessment_detail,
              :"#{category_type}",
              created_at: 1.day.ago,
              planning_application:
            )
          end

          let!("#{category_type}2") do
            create(
              :assessment_detail,
              :"#{category_type}",
              created_at: Time.zone.now,
              planning_application:
            )
          end

          let!("#{category_type}3") do
            create(
              :assessment_detail,
              :"#{category_type}",
              created_at: 2.days.ago,
              planning_application:
            )
          end

          it "returns #{category_type} sorted by created at desc (i.e. most recent first)" do
            expect(described_class.by_created_at_desc).to eq([send(:"#{category_type}2"), send(:"#{category_type}1"), send(:"#{category_type}3")])
          end
        end
      end
    end
  end

  describe "#valid?" do
    let(:planning_application) { create(:planning_application) }

    let(:assessment_detail) do
      build(
        :assessment_detail,
        assessment_status:,
        category:,
        planning_application:,
        reviewer_verdict:,
        entry:,
        additional_information:
      )
    end

    let(:assessment_status) { :complete }
    let(:category) { :summary_of_work }
    let(:reviewer_verdict) { nil }
    let(:entry) { "entry" }
    let(:additional_information) { "additional details" }

    context "when additional_information is blank" do
      let(:additional_information) { nil }

      context "when category is 'past_applications' and assessment status is 'complete'" do
        let(:category) { :past_applications }
        let(:assessment_status) { :complete }

        it "returns false" do
          expect(assessment_detail.valid?).to be(false)
        end

        it "sets error" do
          assessment_detail.valid?

          expect(
            assessment_detail.errors.messages[:additional_information]
          ).to contain_exactly(
            "can't be blank"
          )
        end
      end

      context "when category is not past_applications and assessment status is 'complete'" do
        let(:category) { :summary_of_work }
        let(:assessment_status) { :complete }

        it "returns true" do
          expect(assessment_detail.valid?).to be(true)
        end
      end

      context "when category is past_applications and assessment status is not 'complete'" do
        let(:category) { :past_applications }
        let(:assessment_status) { :in_progress }

        it "returns true" do
          expect(assessment_detail.valid?).to be(true)
        end
      end
    end

    context "when entry is blank" do
      let(:entry) { nil }

      context "when reviewer_verdict is 'accepted'" do
        let(:reviewer_verdict) { :accepted }

        it "returns true" do
          expect(assessment_detail.valid?).to be(true)
        end
      end

      context "when reviewer_verdict is 'rejected'" do
        let(:reviewer_verdict) { :rejected }

        it "returns true" do
          expect(assessment_detail.valid?).to be(true)
        end
      end

      context "when reviewer_verdict is 'edited_and_accepted'" do
        let(:reviewer_verdict) { :edited_and_accepted }

        it "returns false" do
          expect(assessment_detail.valid?).to be(false)
        end

        it "sets error message" do
          assessment_detail.valid?

          expect(
            assessment_detail.errors.messages[:entry]
          ).to contain_exactly(
            "can't be blank"
          )
        end
      end
    end

    context "when no user is specified" do
      let(:user) { create(:user) }
      let(:assessment_detail) { build(:assessment_detail, user: nil) }

      before { Current.user = user }

      it "sets user to current user" do
        assessment_detail.valid?

        expect(assessment_detail.user).to eq(user)
      end
    end
  end

  describe "#update_required?" do
    context "when review_status is 'rcomplete' and reviewer_verdict is 'rejected'" do
      let(:assessment_detail) do
        build(
          :assessment_detail,
          review_status: :complete,
          reviewer_verdict: :rejected
        )
      end

      it "returns true" do
        expect(assessment_detail.update_required?).to be(true)
      end
    end

    context "when reveiw_status is 'complete' and reviewer_verdict is not 'rejected'" do
      let(:assessment_detail) do
        build(
          :assessment_detail,
          review_status: :complete,
          reviewer_verdict: :accepted
        )
      end

      it "returns true" do
        expect(assessment_detail.update_required?).to be(false)
      end
    end

    context "when review_status is not 'complete' and reviewer_verdict is 'rejected'" do
      let(:assessment_detail) do
        build(
          :assessment_detail,
          review_status: :in_progress,
          reviewer_verdict: :rejected
        )
      end

      it "returns true" do
        expect(assessment_detail.update_required?).to be(false)
      end
    end
  end

  describe "#existing_or_new_comment" do
    let(:assessment_detail) { create(:assessment_detail) }

    context "when there is no existing comment" do
      it "returns new comment" do
        expect(
          assessment_detail.existing_or_new_comment
        ).to be_instance_of(
          Comment
        )
      end
    end

    context "when there is an existing comment" do
      let!(:comment) { create(:comment, commentable: assessment_detail) }

      it "returns comment" do
        expect(assessment_detail.existing_or_new_comment).to eq(comment)
      end
    end
  end
end
