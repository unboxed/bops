# frozen_string_literal: true

require "rails_helper"

RSpec.describe PermittedDevelopmentRight, type: :model do
  describe "validations" do
    subject(:permitted_development_right) { described_class.new }

    describe "#removed_reason" do
      context "when removed" do
        let(:permitted_development_right) { create(:permitted_development_right, removed: true, removed_reason: nil) }

        it "validates presence for removed_reason" do
          expect { permitted_development_right }.to raise_error(
            ActiveRecord::RecordInvalid,
            "Validation failed: Removed reason can't be blank"
          )
        end
      end

      context "when not removed" do
        let(:permitted_development_right) { create(:permitted_development_right, :checked) }

        it "does not validates presence for removed_reason" do
          expect { permitted_development_right }.not_to raise_error
        end
      end
    end

    describe "#status" do
      it "validates presence" do
        expect { permitted_development_right.valid? }.to change { permitted_development_right.errors[:status] }.to ["can't be blank"]
      end
    end

    describe "#planning_application" do
      it "validates presence" do
        expect { permitted_development_right.valid? }.to change { permitted_development_right.errors[:planning_application] }.to ["must exist"]
      end
    end
  end

  describe "callbacks" do
    describe "::before_update #reset_removed_reason" do
      context "when choosing 'No' after previously providing a reason for removing the permitted development rights" do
        let(:permitted_development_right) { create(:permitted_development_right, :removed) }

        it "sets the removed reason to nil" do
          expect do
            permitted_development_right.update!(removed: false)
          end.to change(permitted_development_right, :removed_reason).from("Removal reason").to(nil)
        end
      end
    end
  end
end
