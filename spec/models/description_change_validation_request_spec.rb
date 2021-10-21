# frozen_string_literal: true

require "rails_helper"

RSpec.describe DescriptionChangeValidationRequest, type: :model do
  describe "validations" do
    let!(:request) { create(:description_change_validation_request) }

    it "has a valid factory" do
      expect(request).to be_valid
    end

    describe "when another description change request exists" do
      let(:other_request) do
        build(
          :description_change_validation_request,
          planning_application: request.planning_application
        )
      end

      it "is not valid" do
        request.planning_application.reload

        expect(other_request).not_to be_valid
      end
    end
  end
end
