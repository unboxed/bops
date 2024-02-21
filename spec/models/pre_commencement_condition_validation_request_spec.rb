# frozen_string_literal: true

require "rails_helper"

RSpec.describe PreCommencementConditionValidationRequest do
  include_examples "ValidationRequest", described_class, "pre_commencement_condition_validation_request"

  it_behaves_like("Auditable") do
    subject { create(:pre_commencement_condition_validation_request) }
  end

  describe "validations" do
    subject(:pre_commencement_condition_validation_request) { described_class.new }

    describe "#rejection_reason" do
      it "validates presence when approved is set to false" do
        planning_application = create(:planning_application, :invalidated)
        pre_commencement_condition_validation_request = described_class.new(approved: false, planning_application:)

        expect do
          pre_commencement_condition_validation_request.valid?
        end.to change {
          pre_commencement_condition_validation_request.errors[:base]
        }.to ["Please include a comment for the case officer to indicate why the pre-commencement condition has been rejected."]
      end
    end
  end
end
