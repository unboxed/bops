# frozen_string_literal: true

require "rails_helper"

RSpec.shared_examples "ValidationRequest" do |klass, request_type|
  let(:planning_application) { create(:planning_application, :invalidated) }
  let(:request) { create(request_type, planning_application: planning_application) }

  describe "validations" do
    it "validates that cancel_reason is present if the state is cancelled" do
      expect do
        request.update!(state: "cancelled")
      end.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Cancel reason can't be blank")
    end
  end

  describe "callbacks" do
    describe "::before_create" do
      it "sets a sequence on the record before it's created" do
        expect(request.sequence).to eq(1)

        another_request = create(request_type, planning_application: planning_application)
        expect(another_request.sequence).to eq(2)
      end

      context "when a planning application has been validated" do
        let(:planning_application) { create(:planning_application, :in_assessment) }

        it "prevents a #{request_type} validation request from being created" do
          expect do
            request
          end.to raise_error(ValidationRequest::ValidationRequestNotCreatableError,
                             "Cannot create #{klass.name} when planning application has been validated")
        end
      end
    end

    describe "::before_destroy" do
      context "with a pending request" do
        let(:request) do
          create(request_type, state: "pending", planning_application: planning_application)
        end

        it "destroys the record" do
          expect(request.destroy!).to be_truthy
        end
      end

      context "with a non pending request" do
        it "raises an error" do
          expect do
            request.destroy!
          end.to raise_error(ValidationRequest::NotDestroyableError,
                             "Only requests that are pending can be destroyed")
        end
      end
    end
  end
end
