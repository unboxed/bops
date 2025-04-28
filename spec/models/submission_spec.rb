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
    let(:submission) { create(:submission, local_authority: local_authority) }
    let!(:planning_application) { create(:planning_application, submission: submission) }

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

      it "nullifies the planning application's submission_id" do
        submission.destroy
        expect(planning_application.reload.submission_id).to be_nil
      end
    end
  end

  describe "state transitions" do
    let(:submission) { create(:submission) }

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
  end
end
