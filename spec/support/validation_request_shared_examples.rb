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

    context "when calling valid?" do
      subject(:request) { described_class.new }

      describe "#user" do
        it "validates presence" do
          expect { request.valid? }.to change { request.errors[:user] }.to ["must exist"]
        end
      end

      describe "#planning_application" do
        it "validates presence" do
          expect { request.valid? }.to change { request.errors[:planning_application] }.to ["must exist"]
        end
      end
    end
  end

  describe "callbacks" do
    describe "::before_create #set_sequence" do
      it "sets a sequence on the record before it's created" do
        expect(request.sequence).to eq(1)

        another_request = create(request_type, planning_application: planning_application)
        expect(another_request.sequence).to eq(2)
      end
    end

    describe "::before_create #ensure_planning_application_not_closed_or_cancelled!" do
      context "when planning application is cancelled" do
        let(:planning_application) { create(:planning_application, :withdrawn) }

        it "raises an error" do
          expect do
            request
          end.to raise_error(
            ValidationRequest::ValidationRequestNotCreatableError, "Cannot create #{klass.name.titleize} when planning application has been closed or cancelled"
          )
        end
      end

      context "when planning application is closed" do
        let(:planning_application) { create(:planning_application, :closed) }

        it "raises an error" do
          expect do
            request
          end.to raise_error(
            ValidationRequest::ValidationRequestNotCreatableError, "Cannot create #{klass.name.titleize} when planning application has been closed or cancelled"
          )
        end
      end

      context "when planning application is not closed or cancelled" do
        let(:planning_application) { create(:planning_application, :invalidated) }

        it "does not raise an error" do
          expect do
            request
          end.not_to raise_error(ValidationRequest::ValidationRequestNotCreatableError)
        end
      end
    end

    describe "::before_destroy" do
      let(:planning_application) { create(:planning_application, :not_started) }

      context "with a pending request" do
        let(:request) do
          create(request_type, :pending, planning_application: planning_application)
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
