# frozen_string_literal: true

require "rails_helper"

RSpec.describe DescriptionChangeValidationRequest do
  it_behaves_like("Auditable") do
    subject { create(:description_change_validation_request) }
  end
  let!(:planning_application) { create(:planning_application, :invalidated) }
  let!(:request) { create(:description_change_validation_request, :open) }

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

    context "when calling valid?" do
      let(:request) { build(:description_change_validation_request, planning_application: nil, user: nil) }

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
        request.close!
        another_request = create(:description_change_validation_request, planning_application: request.planning_application)
        expect(another_request.sequence).to eq(2)
      end
    end

    describe "::before_create #ensure_planning_application_not_closed_or_cancelled!" do
      context "when planning application is cancelled" do
        let(:planning_application) { create(:planning_application, :withdrawn) }
        let(:request) { build(:description_change_validation_request, planning_application:) }

        it "raises an error" do
          expect do
            request.save!
          end.to raise_error(
            ValidationRequest::ValidationRequestNotCreatableError, "Cannot create Description Change Validation Request when planning application has been closed or cancelled"
          )
        end
      end

      context "when planning application is closed" do
        let(:planning_application) { create(:planning_application, :closed) }
        let(:request) { build(:description_change_validation_request, planning_application:) }

        it "raises an error" do
          expect do
            request.save!
          end.to raise_error(
            ValidationRequest::ValidationRequestNotCreatableError, "Cannot create Description Change Validation Request when planning application has been closed or cancelled"
          )
        end
      end

      context "when planning application is not closed or cancelled" do
        let(:planning_application) { create(:planning_application, :invalidated) }

        it "does not raise an error" do
          expect do
            request
          end.not_to raise_error
        end
      end
    end

    describe "::after_create #create_validation_request!" do
      it "creates a validation request record with the associated requested id, type and planning application" do
        expect(request).to eq(
          ValidationRequest.find_by(type: "DescriptionChangeValidationRequest", planning_application_id: request.planning_application_id)
        )
      end
    end

    describe "::before_destroy" do
      let(:planning_application) { create(:planning_application, :not_started) }

      context "with a pending request" do
        let(:request) do
          create(:description_change_validation_request, planning_application:)
        end

        it "destroys the record" do
          request.update(state: "pending")
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

  describe "events" do
    let!(:request) { create(:description_change_validation_request, :open, planning_application:) }

    before { freeze_time }

    describe "#close" do
      it "sets a closed_at timestamp on the associated validation request" do
        request.close!

        expect(request.state).to eq("closed")
        expect(request.closed_at).to eq(Time.current)
      end
    end
  end
end
