# frozen_string_literal: true

module PlanningApplications
  module Review
    class NotificationsController < AuthenticationController
      include CommitMatchable
      before_action :set_planning_application
      before_action :ensure_user_is_reviewer
      before_action :set_committee_decision

      def new
      end

      def edit
      end

      def show
      end

      def update
        ActiveRecord::Base.transaction do
          update_committee_decision!
          deliver_letters!
          send_email_to_applicant!
          record_audit_for_letters_sent!
          @planning_application.send_to_committee! unless @planning_application.in_committee?
        end

        respond_to do |format|
          format.html do
            redirect_to(planning_application_review_tasks_path(@planning_application),
              notice: t(".success"))
          end
        end
      rescue ActiveRecord::RecordInvalid => e
        redirect_after_rescue(e)
      end

      def update_committee_decision!
        @committee_decision.update!(committee_decision_params.except(:neighbour_letter_text))
      end

      def deliver_letters!
        neighbours_to_contact.each do |neighbour|
          if neighbour.neighbour_responses.last.email.present?
            SendCommitteeDecisionEmailJob.perform_later(neighbour, @planning_application.planning_application)
          else
            LetterSendingService.new(neighbour, @committee_decision.notification_content, letter_type: :committee).deliver!
          end
        end
      end

      def send_email_to_applicant!
        PlanningApplicationMailer.send_committee_decision_mail(@planning_application, Current.user)
      end

      private

      def neighbours_to_contact
        @planning_application.consultation.neighbours.with_responses
      end

      def set_committee_decision
        @committee_decision = @planning_application.committee_decision
      end

      def committee_decision_params
        params.require(:committee_decision).permit(
          :date_of_committee,
          :location,
          :link,
          :time,
          :late_comments_deadline,
          :notification_content
        )
      end

      def redirect_after_rescue(error)
        redirect_to edit_planning_application_review_committee_decision_notifications_path(@planning_application, @committee_decision), alert: error
      end

      def record_audit_for_letters_sent!
        Audit.create!(
          planning_application_id: @planning_application.id,
          user: Current.user,
          activity_type: "committee_details_sent"
        )
      end
    end
  end
end
