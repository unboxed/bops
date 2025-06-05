# frozen_string_literal: true

module BopsApplicants
  module ConsultationHelper
    CLOSED_STATUS = %w[closed withdrawn cancelled].freeze
    GRANTED_STATUS = %w[granted granted_not_required].freeze
    REFUSED_STATUS = %w[refused].freeze

    def consultation_end_date
      @consultation.end_date.to_fs
    end

    def consultation_in_progress?
      @consultation.end_date? && @consultation.end_date >= Date.current
    end

    def decision_notice_link
      govuk_button_link_to "View decision notice", decision_notice_url, new_tab: ""
    end

    def decision_notice_url
      main_app.decision_notice_public_planning_application_url(@planning_application.reference, host: bops_host)
    end

    def neighbour_comment_link
      govuk_button_link_to "Submit a comment", neighbour_comment_url
    end

    def neighbour_comment_url
      start_planning_application_neighbour_responses_path(@planning_application.reference)
    end

    def planning_application_consultation?
      @consultation.present?
    end

    def planning_application_closed?
      CLOSED_STATUS.include?(@planning_application.status)
    end

    def planning_application_determined?
      @planning_application.decision?
    end

    def planning_application_granted?
      GRANTED_STATUS.include?(@planning_application.decision)
    end

    def planning_application_refused?
      REFUSED_STATUS.include?(@planning_application.decision)
    end

    def planning_application_status
      decision_text = @planning_application.decision.presence

      undetermined_status =
        if planning_application_closed?
          "closed"
        elsif consultation_in_progress?
          "under consultation"
        else
          "in review"
        end

      status_text = decision_text || undetermined_status

      status_colour =
        if planning_application_granted?
          "green"
        elsif planning_application_refused?
          "red"
        else
          "grey"
        end

      govuk_tag(text: status_text.humanize, colour: status_colour)
    end
  end
end
