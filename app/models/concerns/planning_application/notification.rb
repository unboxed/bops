# frozen_string_literal: true

class PlanningApplication
  module Notification
    extend ActiveSupport::Concern

    def send_decision_notice_mail(host)
      return unless applicant_and_agent_email.any?

      downcase_and_unique(applicant_and_agent_email).each do |email|
        PlanningApplicationMailer.decision_notice_mail(
          self,
          host,
          email
        ).deliver_later
      end
    end

    def send_validation_notice_mail
      return unless applicant_and_agent_email.any?

      downcase_and_unique(applicant_and_agent_email).each do |email|
        PlanningApplicationMailer
          .validation_notice_mail(self, email)
          .deliver_later
      end
    end

    def send_invalidation_notice_mail
      PlanningApplicationMailer
        .invalidation_notice_mail(self)
        .deliver_later
    end

    def send_receipt_notice_mail
      return unless applicant_and_agent_email.any?

      downcase_and_unique(applicant_and_agent_email).each do |email|
        PlanningApplicationMailer
          .receipt_notice_mail(self, email)
          .deliver_later
      end
    end

    def send_assigned_notification_to_assessor
      send_assigned_notification(user_email)
    end

    def send_update_notification_to_assessor
      send_update_notification(user_email)
    end

    def send_update_notification_to_reviewers
      send_update_notification(reviewer_group_email)
    end

    def send_neighbour_consultation_letter_copy_mail
      downcase_and_unique(applicant_and_agent_email).each do |email|
        PlanningApplicationMailer
          .neighbour_consultation_letter_copy_mail(self, email)
          .deliver_later
      end

      consultation.update!(letter_copy_sent_at: Time.current)
    end

    private

    def send_update_notification(to)
      return if to.blank?

      UserMailer.update_notification_mail(self, to).deliver_later
    end

    def send_assigned_notification(to)
      return if to.blank?

      UserMailer.assigned_notification_mail(self, to).deliver_later
    end

    def downcase_and_unique(array)
      array.map(&:downcase).uniq
    end
  end
end
