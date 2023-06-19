# frozen_string_literal: true

require "rails_helper"

RSpec.describe PlanningApplication::Notification do
  let(:planning_application) { create(:planning_application, agent_email: "agent@example.com", applicant_email: "applicant@example.com") }
  let(:planning_application_with_same_agent_and_applicant_email) do
    create(:planning_application, applicant_email: "email@example.com", agent_email: "Email@example.com")
  end
  let(:planning_application_with_only_agent_email) do
    create(:planning_application, applicant_email: nil, agent_email: "Email@example.com")
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

  describe "#send_neighbour_consultation_letter_copy" do
    context "when there is an applicant an agent email" do
      let!(:consultation) { create(:consultation, planning_application:) }

      it "sends an email to both applicant and agent" do
        expect(PlanningApplicationMailer).to receive(:neighbour_consultation_letter_copy_mail).with(planning_application, "agent@example.com").and_call_original
        expect(PlanningApplicationMailer).to receive(:neighbour_consultation_letter_copy_mail).with(planning_application, "applicant@example.com").and_call_original

        planning_application.send_neighbour_consultation_letter_copy_mail
      end
    end

    context "when applicant and agent email are the same" do
      let!(:consultation) { create(:consultation, planning_application: planning_application_with_same_agent_and_applicant_email) }

      it "sends only one email" do
        expect(PlanningApplicationMailer).to receive(:neighbour_consultation_letter_copy_mail).with(planning_application_with_same_agent_and_applicant_email, "email@example.com").and_call_original

        planning_application_with_same_agent_and_applicant_email.send_neighbour_consultation_letter_copy_mail
      end
    end

    context "when there is only an agent email" do
      let!(:consultation) { create(:consultation, planning_application: planning_application_with_only_agent_email) }

      it "sends only one email" do
        expect(PlanningApplicationMailer).to receive(:neighbour_consultation_letter_copy_mail).with(planning_application_with_only_agent_email, "email@example.com").and_call_original

        planning_application_with_only_agent_email.send_neighbour_consultation_letter_copy_mail
      end
    end
  end
end
