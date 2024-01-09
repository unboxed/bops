# frozen_string_literal: true

require "rails_helper"

RSpec.describe ValidationRequestUpdateService, type: :service do
  describe "#call" do
    let!(:assessor) { create(:user, :assessor) }
    let!(:planning_application) { create(:planning_application, :invalidated, user: assessor) }
    let!(:validation_request) { create(:ownership_certificate_validation_request, planning_application:, state: "open") }

    let!(:params) do
      ActionController::Parameters.new(
        {
          "data" => {
            "approved" => "true",
            "rejection_reason" => "",
            "params" => {
              "certificate_type" => "a"
            }
          }
        }
      )
    end

    let(:update_validation_request) do
      described_class.new(
        validation_request:, params:
      ).call!
    end

    context "when successful" do
      it "updates the validation request" do
        expect { update_validation_request }.to change(validation_request, :approved).from(nil).to(true)
      end

      it "closes the validation request" do
        expect { update_validation_request }.to change(validation_request, :state).from("open").to("closed")
      end

      it "creates an audit" do
        expect do
          update_validation_request
        end.to change(Audit, :count).by(1)

        expect(Audit.last.activity_type).to eq("ownership_certificate_validation_request_received")
      end

      it "updates the planning officer" do
        expect { update_validation_request }
          .to have_enqueued_job
          .on_queue("low_priority")
          .with(
            "UserMailer",
            "update_notification_mail",
            "deliver_now",
            args: [planning_application, assessor.email]
          )
      end

      context "request is approved" do
        it "updates the planning application" do
          expect { update_validation_request }.to change(planning_application, :valid_ownership_certificate).from(nil).to(true)
        end

        it "updates the certificate" do
          expect do
            update_validation_request
          end.to change(OwnershipCertificate, :count).by(1)

          expect(OwnershipCertificate.last.certificate_type).to eq "a"
        end
      end

      context "request is rejected" do
        let!(:params) do
          ActionController::Parameters.new(
            {
              "data" => {
                "approved" => "false",
                "rejection_reason" => "I don't agree",
                "params" => {}
              }
            }
          )
        end

        it "does not update the planning application" do
          expect { update_validation_request }.not_to change(planning_application, :valid_ownership_certificate)
        end

        it "updates the certificate" do
          expect do
            update_validation_request
          end.to change(OwnershipCertificate, :count).by(0)
        end
      end
    end

    context "when unsuccessful" do
      it "raises an error" do
        validation_request.update(state: "pending")

        expect { update_validation_request }.to raise_error(described_class::UpdateError)
      end
    end
  end
end
