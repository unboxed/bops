# frozen_string_literal: true

require "rails_helper"

RSpec.describe HeadsOfTermsValidationRequest do
  include ActionDispatch::TestProcess::FixtureFile

  include_examples "ValidationRequest", described_class, "heads_of_terms_validation_request"

  let!(:application_type) { create(:application_type) }

  it_behaves_like("Auditable") do
    subject { create(:heads_of_terms_validation_request) }
  end

  describe "validations" do
    subject(:request) { build(:heads_of_terms_validation_request) }

    it "has a valid factory" do
      expect(request).to be_valid
    end

    describe "when another request exists" do
      let(:other_request) do
        build(
          :heads_of_terms_validation_request,
          planning_application: request.planning_application,
          owner: request.owner
        )
      end

      it "is not valid" do
        request.save

        expect do
          other_request.valid?
        end.to change {
          other_request.errors[:base]
        }.to ["An open request already exists for this term."]
      end
    end
  end
end
