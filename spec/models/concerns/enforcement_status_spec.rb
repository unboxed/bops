# frozen_string_literal: true

require "rails_helper"

RSpec.describe EnforcementStatus do
  RSpec.shared_examples "EnforcementStateMachineEvents" do |state, permitted|
    let(:all_events) { %i[start_investigation close] }

    subject(:enforcement) do
      case state.to_s
      when "not_started" then create(:enforcement)
      when "under_investigation", "closed" then create(:enforcement, state.to_sym)
      else raise "Unknown state: #{state}"
      end
    end

    it "permits only the expected events from #{state}" do
      permitted.each { |ev| expect(enforcement.public_send("may_#{ev}?")).to be(true) }
      (all_events - permitted).each { |ev| expect(enforcement.public_send("may_#{ev}?")).to be(false) }
    end
  end

  describe "states" do
    context "when not started" do
      it_behaves_like "EnforcementStateMachineEvents", "not_started", %i[start_investigation close]
    end

    context "when under investigation" do
      it_behaves_like "EnforcementStateMachineEvents", "under_investigation", %i[close]
    end

    context "when closed" do
      it_behaves_like "EnforcementStateMachineEvents", "closed", %i[]
    end
  end

  describe "transitions & timestamps" do
    context "when I start the enforcement" do
      subject(:enforcement) { create(:enforcement) } # not_started

      before { enforcement.update!(under_investigation_at: 1.hour.ago) }

      it "sets the status to under_investigation" do
        enforcement.start_investigation
        expect(enforcement.status).to eq "under_investigation"
      end

      it "sets the timestamp for under_investigation_at to now" do
        freeze_time do
          enforcement.start_investigation
          expect(enforcement.under_investigation_at).to eql(Time.zone.now)
        end
      end
    end

    context "when I close the enforcement from not_started" do
      subject(:enforcement) { create(:enforcement) }

      before { enforcement.update!(closed_at: 1.hour.ago) }

      it "sets the status to closed" do
        enforcement.close
        expect(enforcement.status).to eq "closed"
      end

      it "sets the timestamp for closed_at to now" do
        freeze_time do
          enforcement.close
          expect(enforcement.closed_at).to eql(Time.zone.now)
        end
      end
    end

    context "when I close the enforcement from under_investigation" do
      subject(:enforcement) { create(:enforcement, :under_investigation) }

      before { enforcement.update!(closed_at: 1.hour.ago) }

      it "sets the status to closed" do
        enforcement.close
        expect(enforcement.status).to eq "closed"
      end

      it "sets the timestamp for closed_at to now" do
        freeze_time do
          enforcement.close
          expect(enforcement.closed_at).to eql(Time.zone.now)
        end
      end
    end
  end

  describe "no direct assignment (enum writers blocked by AASM)" do
    it "raises when using enum bang writer" do
      enforcement = create(:enforcement)
      expect { enforcement.closed! }.to raise_error(AASM::NoDirectAssignmentError)
    end

    it "allows transitions via AASM events" do
      enforcement = create(:enforcement)
      enforcement.close
      expect(enforcement).to be_closed
    end
  end
end
