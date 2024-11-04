# frozen_string_literal: true

require "rails_helper"

RSpec.describe Appeal do
  let(:appeal) { create(:appeal) }

  describe "validations" do
    subject(:appeal) { described_class.new }

    describe "#lodged_at" do
      it "validates presence" do
        expect { appeal.valid? }.to change { appeal.errors[:lodged_at] }.to ["Enter the date when the appeal was lodged"]
      end
    end

    describe "#reason" do
      it "validates presence" do
        expect { appeal.valid? }.to change { appeal.errors[:reason] }.to ["Enter a reason for the appeal"]
      end
    end

    describe "#planning_application" do
      it "validates presence" do
        expect { appeal.valid? }.to change { appeal.errors[:planning_application] }.to ["must exist"]
      end
    end

    context "on create" do
      it "validates that lodged_at is on or before the current date" do
        travel_to(DateTime.new(2024, 11, 11)) do
          appeal.lodged_at = Date.current + 1.day
          expect(appeal.valid?).to be false
          expect(appeal.errors[:lodged_at]).to include("The date the appeal was lodged must be on or before today")
        end
      end
    end
  end

  describe "state machine" do
    it "initial state is lodged" do
      expect(appeal.status).to eq("lodged")
    end

    it "transitions from lodged to validated" do
      expect { appeal.mark_as_valid! }.to change { appeal.status }.from("lodged").to("validated")
    end

    it "transitions from validated to started" do
      appeal.mark_as_valid!
      expect { appeal.start! }.to change { appeal.status }.from("validated").to("started")
    end

    it "transitions from started to determined" do
      appeal.mark_as_valid!
      appeal.start!
      expect { appeal.determine! }.to change { appeal.status }.from("started").to("determined")
    end

    context "when attempting invalid transitions" do
      context "when in lodged state" do
        it "cannot transition to started" do
          expect { appeal.start! }.to raise_error(AASM::InvalidTransition)
        end

        it "cannot transition to determined" do
          expect { appeal.determine! }.to raise_error(AASM::InvalidTransition)
        end
      end

      context "when in validated state" do
        let(:appeal) { create(:appeal, :valid) }

        it "cannot transition to determined" do
          expect { appeal.determine! }.to raise_error(AASM::InvalidTransition)
        end
      end

      context "when in started state" do
        let(:appeal) { create(:appeal, :started) }

        it "cannot transition to validated" do
          expect { appeal.mark_as_valid! }.to raise_error(AASM::InvalidTransition)
        end
      end

      context "when in determined state" do
        let(:appeal) { create(:appeal, :determined) }

        it "cannot transition to started" do
          expect { appeal.start! }.to raise_error(AASM::InvalidTransition)
        end

        it "cannot transition to validated" do
          expect { appeal.mark_as_valid! }.to raise_error(AASM::InvalidTransition)
        end
      end
    end
  end

  describe "auditing" do
    it "audits status changes" do
      travel_to(DateTime.new(2024, 11, 11)) do
        appeal
        travel 1.hour

        expect {
          appeal.update(status: "validated", validated_at: Date.current)
        }.to change(Audit, :count).by(1)
        expect(appeal.audits.last.audit_comment).to include("Appeal status was updated to validated on 11 November 2024")
      end
    end

    it "audits decision changes" do
      travel_to(DateTime.new(2024, 11, 11)) do
        appeal
        travel 1.hour

        expect {
          appeal.update!(status: "determined", decision: "allowed", determined_at: Date.current - 1.day)
        }.to change(Audit, :count).by(2)

        expected_comments = [
          "Appeal status was updated to determined on 10 November 2024",
          "Appeal decision was updated to allowed on 10 November 2024"
        ]
        expect(appeal.audits.last(2).map(&:audit_comment)).to match_array(expected_comments)
      end
    end
  end
end
