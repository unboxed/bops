# frozen_string_literal: true

require "rails_helper"

RSpec.describe PlanningApplication::Notification do
  let(:planning_application) { create(:planning_application) }
  let(:planning_application_with_same_agent_and_applicant_email) do
    create(:planning_application, applicant_email: "email@example.com", agent_email: "Email@example.com")
  end

  describe "#send_decision_notice_mail" do
    context "when there is an applicant an agent email" do
      it "sends an email to both applicant and agent" do
        expect(PlanningApplicationMailer).to receive(:decision_notice_mail).twice.and_call_original

        planning_application.send_decision_notice_mail(host: "host")
      end
    end

    context "when applicant and agent email are the same" do
      it "sends only one email" do
        expect(PlanningApplicationMailer).to receive(:decision_notice_mail).once.and_call_original

        planning_application_with_same_agent_and_applicant_email.send_decision_notice_mail(host: "host")
      end
    end
  end

  describe "#send_validation_notice_mail" do
    context "when there is an applicant an agent email" do
      it "sends an email to both applicant and agent" do
        expect(PlanningApplicationMailer).to receive(:validation_notice_mail).twice.and_call_original

        planning_application.send_validation_notice_mail
      end
    end

    context "when applicant and agent email are the same" do
      it "sends only one email" do
        expect(PlanningApplicationMailer).to receive(:validation_notice_mail).once.and_call_original

        planning_application_with_same_agent_and_applicant_email.send_validation_notice_mail
      end
    end
  end

  describe "#send_receipt_notice_mail" do
    context "when there is an applicant an agent email" do
      it "sends an email to both applicant and agent" do
        expect(PlanningApplicationMailer).to receive(:receipt_notice_mail).twice.and_call_original

        planning_application.send_receipt_notice_mail
      end
    end

    context "when applicant and agent email are the same" do
      it "sends only one email" do
        expect(PlanningApplicationMailer).to receive(:receipt_notice_mail).once.and_call_original

        planning_application_with_same_agent_and_applicant_email.send_receipt_notice_mail
      end
    end
  end
end
