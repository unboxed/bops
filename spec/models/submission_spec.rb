# frozen_string_literal: true

require "rails_helper"

RSpec.describe Submission do
  describe "validations" do
    subject(:submission) { described_class.new }

    describe "#request_headers" do
      it "validates presence" do
        expect { submission.valid? }.to change { submission.errors[:request_headers] }.to ["can't be blank"]
      end
    end

    describe "#request_body" do
      it "validates presence" do
        expect { submission.valid? }.to change { submission.errors[:request_body] }.to ["can't be blank"]
      end
    end

    describe "#local_authority" do
      it "validates presence" do
        expect { submission.valid? }.to change { submission.errors[:local_authority] }.to ["must exist"]
      end
    end
  end

  describe "associations" do
    let(:local_authority) { create(:local_authority) }
    let(:submission) { create(:submission, :planning_portal, local_authority:) }
    let(:case_record) { build(:case_record, local_authority:, submission:) }
    let!(:planning_application) { create(:planning_application, case_record:) }

    describe "#local_authority" do
      it "returns the associated local authority" do
        expect(submission.local_authority).to eq(local_authority)
      end
    end

    describe "#planning_application" do
      it "returns the associated planning application" do
        expect(submission.planning_application).to eq(planning_application)
      end
    end

    describe "when the submission is destroyed" do
      it "does not delete the planning application" do
        expect { submission.destroy }.not_to change(PlanningApplication, :count)
      end

      it "nullifies the case record's submission_id" do
        submission.destroy
        expect(case_record.reload.submission_id).to be_nil
      end
    end
  end

  describe "scopes" do
    it "orders by created_at desc" do
      older = create(:submission, :planning_portal, created_at: 1.day.ago)
      newer = create(:submission, :planning_portal, created_at: 1.hour.ago)
      expect(Submission.by_created_at_desc.to_a).to eq([newer, older])
    end
  end

  describe "instance methods" do
    let(:submission) { build(:submission, :planning_portal, request_body:) }

    context "when submitted from planning portal" do
      let(:request_body) {
        {
          "applicationRef" => "ABC123",
          "documentLinks" => [
            {"documentLink" => "http://foo"},
            {"documentLink" => "http://bar"}
          ]
        }
      }

      describe "#application_reference" do
        it "reads applicationRef from the body" do
          expect(submission.application_reference).to eq("ABC123")
        end
      end

      describe "#document_link_urls" do
        it "plucks documentLink entries" do
          expect(submission.document_link_urls).to contain_exactly("http://foo", "http://bar")
        end
      end

      describe "#source" do
        it "is set to Planning Portal when initialising" do
          expect(submission.source).to eq("Planning Portal")
        end
      end
    end
  end

  describe "state transitions" do
    let(:submission) { create(:submission, :planning_portal) }

    around do |example|
      freeze_time { example.run }
    end

    it "starts in the submitted state" do
      expect(submission.status).to eq("submitted")
    end

    describe "#start!" do
      it "transitions to started and sets started_at" do
        expect { submission.start! }.to change(submission, :status).from("submitted").to("started")
        expect(submission.started_at).to eq(Time.current)
      end
    end

    describe "#fail!" do
      it "transitions to failed and sets failed_at" do
        expect { submission.fail! }.to change(submission, :status).from("submitted").to("failed")
        expect(submission.failed_at).to eq(Time.current)
      end
    end

    describe "#complete!" do
      before { submission.start! }

      it "transitions to completed and sets completed_at" do
        expect { submission.complete! }.to change(submission, :status).from("started").to("completed")
        expect(submission.completed_at).to eq(Time.current)
      end
    end

    context "event guards" do
      it "won't complete before start" do
        expect(submission.may_complete?).to be_falsey
        expect { submission.complete! }.to raise_error(AASM::InvalidTransition)
      end

      it "won't fail after completion" do
        submission.start!
        submission.complete!
        expect(submission.may_fail?).to be_falsey
        expect { submission.fail! }.to raise_error(AASM::InvalidTransition)
      end

      it "won't start twice" do
        submission.start!
        expect(submission.may_start?).to be_falsey
        expect { submission.start! }.to raise_error(AASM::InvalidTransition)
      end

      it "allows fail from started" do
        submission.start!
        expect(submission.may_fail?).to be_truthy
      end

      it "allows complete only from started" do
        submission.start!
        expect(submission.may_complete?).to be_truthy
      end
    end
  end
end
