# frozen_string_literal: true

require "rails_helper"

RSpec.describe TimeExtensionValidationRequest do
  include_examples "ValidationRequest", described_class, "time_extension_validation_request"

  it_behaves_like("Auditable") do
    subject { create(:time_extension_validation_request, planning_application: planning_application) }
  end

  describe "validations" do
    subject(:time_extension_validation_request) { described_class.new }

    describe "#rejection_reason" do
      it "validates presence when approved is set to false" do
        planning_application = create(:planning_application, :invalidated)
        time_extension_validation_request = described_class.new(approved: false, planning_application:)

        expect do
          time_extension_validation_request.valid?
        end.to change {
          time_extension_validation_request.errors[:base]
        }.to ["Please include a comment for the case officer to indicate why the time extension request has been rejected."]
      end
    end
  end
end
