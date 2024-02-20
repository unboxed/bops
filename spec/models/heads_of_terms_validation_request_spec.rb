# frozen_string_literal: true

require "rails_helper"

RSpec.describe HeadsOfTermsValidationRequest do
  include ActionDispatch::TestProcess::FixtureFile

  include_examples "ValidationRequest", described_class, "heads_of_terms_validation_request"

  it_behaves_like("Auditable") do
    subject { create(:heads_of_terms_validation_request) }
  end

  describe "validations" do
    subject(:heads_of_terms_validation_request) { described_class.new }

    describe "#document" do
      it "validates presence" do
        expect do
          heads_of_terms_validation_request.valid?
        end.to change {
          heads_of_terms_validation_request.errors[:document]
        }.to ["can't be blank"]
      end
    end
  end

  describe "::callbacks" do
    subject(:heads_of_terms_validation_request) { described_class.create }

    describe "::allows_only_one_open_heads_of_terms_request" do 
      it "only allows one open heads of term validation request" do 
        expect do 
          create(:heads_of_terms_validation_request, planning_application: heads_of_terms_validation_request.planning_application)
        end.to change {
          heads_of_terms_validation_request.errors[:document]
        }.to "Can't do that"
      end
    end
  end
end
