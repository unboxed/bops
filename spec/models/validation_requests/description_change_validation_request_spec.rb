# frozen_string_literal: true

require "rails_helper"

RSpec.describe ValidationRequest do
  it_behaves_like("Auditable") do
    subject { create(:validation_request, :description_change) }
  end

  describe "validations" do
    let!(:request) { create(:validation_request, :description_change) }

    it "has a valid factory" do
      expect(request).to be_valid
    end

    describe "when another description change request exists" do
      let(:other_request) do
        build(
          :validation_request, :description_change,
          planning_application: request.planning_application
        )
      end

      it "is not valid" do
        request.planning_application.reload

        expect(other_request).not_to be_valid
      end
    end

    describe "#response_due" do
      let(:request) do
        build(
          :validation_request, :description_change,
          created_at: DateTime.new(2022, 6, 20)
        )
      end

      it "returns date 5 working days after created_at" do
        expect(request.response_due).to eq(Date.new(2022, 6, 27))
      end
    end
  end
end