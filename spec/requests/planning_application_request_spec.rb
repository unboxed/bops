# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "PlanningApplications", type: :request do
  describe "GET /index" do
    it "should redirect to login page" do
      get "/planning_applications/index"
      expect(response).to redirect_to("/users/sign_in")
    end
  end

  describe "PATCH #update" do
    let(:local_authority) { create :local_authority }
    let(:planning_application) { create :planning_application, local_authority: local_authority }

    subject {
      patch "/planning_applications/#{planning_application.id}",
        params: { planning_application: { status: status } }
    }

    before do
      sign_in user
    end

    context "for an assessor" do
      let(:user) { create :user, :assessor, local_authority: local_authority }

      context "setting the status to \"awaiting_determination\"" do
        let(:status) { :awaiting_determination }

        it "changes the status and redirects to the planning application"  do
          expect {
            subject
          }.to change {
            planning_application.reload.status
          }.to("awaiting_determination")

          expect(response.code).to eq "302"
          expect(response).to redirect_to planning_application_path(planning_application)
        end
      end

      context "setting the status to \"determined\"" do
        let(:status) { :determined }

        it "does not change the status and redirects to the root"  do
          expect {
            subject
          }.not_to change {
            planning_application.reload.status
          }

          expect(response.code).to eq "302"
          expect(response).to redirect_to root_path
        end
      end
    end

    context "for a reviewer" do
      let(:user) { create :user, :reviewer, local_authority: local_authority }

      context "setting the status to \"determined\"" do
        let(:status) { :determined }

        let(:mailer) { double }

        before do
          allow(PlanningApplicationMailer).to receive(:decision_notice_mail).and_return(mailer)
          allow(mailer).to receive(:deliver_now)
        end

        it "changes the status and redirects to the planning application"  do
          expect {
            subject
          }.to change {
            planning_application.reload.status
          }.to(
            "determined"
          )

          expect(response.code).to eq "302"
          expect(response).to redirect_to planning_application_path(planning_application)
        end
      end

      context "setting the status to \"awaiting_determination\"" do
        let(:status) { :awaiting_determination }

        it "does not change the status and redirects to the root"  do
          expect {
            subject
          }.not_to change {
            planning_application.reload.status
          }

          expect(response.code).to eq "302"
          expect(response).to redirect_to root_path
        end
      end
    end
  end
end
