# frozen_string_literal: true

require "rails_helper"

RSpec.describe Audit do
  describe "validations" do
    subject(:audit) { described_class.new }

    describe "#activity_type" do
      it "validates presence" do
        expect { audit.valid? }.to change { audit.errors[:activity_type] }.to ["can't be blank"]
      end
    end

    describe "#planning_application" do
      it "validates presence" do
        expect { audit.valid? }.to change { audit.errors[:planning_application] }.to ["must exist"]
      end
    end

    describe "#validation_request" do
      let(:planning_application) { create(:planning_application) }
      let(:audit) { planning_application.audits.last }

      context "when there is an associated request" do
        let!(:validation_request) do
          create(
            :red_line_boundary_change_validation_request,
            planning_application: planning_application
          )
        end

        it "returns the correct request" do
          expect(audit.validation_request).to eq(validation_request)
        end
      end

      context "when there is no associated request" do
        it "returns nil" do
          expect(audit.validation_request).to be_nil
        end
      end
    end
  end
end
