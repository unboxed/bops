# frozen_string_literal: true

module Tasks
  class SendLettersToNeighboursForm < Form
    self.task_actions = %w[send_letters]

    attribute :deadline_extension, :integer
    attribute :neighbour_letter_text, :string
    attribute :polygon_geojson
    attribute :resend_existing, :boolean
    attribute :resend_reason, :string

    attribute :neighbours_attributes

    delegate :consultation, to: :planning_application

    validates :deadline_extension, presence: true

    private

    def send_letters
      update_consultation!
      deliver_letters!
      send_neighbour_consultation_letter_copy!
      create_review!
      record_audit_for_letters_sent!

      @task.complete!
    end

    def neighbours_to_contact
      neighbours_params[:neighbours_attributes].to_h.select { |key, value|
        value[:selected] == "1"
      }.map { |key, value|
        consultation.neighbours.find(Integer(value[:id]))
      }.compact
    end

    def neighbours_params
      params.require(:tasks_send_letters_to_neighbours_form).permit(neighbours_attributes: %i[id selected])
    end

    def update_consultation!
      consultation.update!({neighbour_letter_text:, deadline_extension:, polygon_geojson:, status: "in_progress"}, :apply_deadline_extension)
    end

    def deliver_letters!
      LetterSendingService.new(consultation.neighbour_letter_text, consultation:, resend_reason:, letter_type: :consultation).deliver_batch!(neighbours_to_contact)
    end

    def send_neighbour_consultation_letter_copy!
      planning_application.send_neighbour_consultation_letter_copy_mail
    end

    def create_review!
      consultation.create_neighbour_review! if consultation.neighbour_review.blank? || consultation.neighbour_review.to_be_reviewed?
    end

    def record_audit_for_letters_sent!
      Audit.create!(
        planning_application_id: planning_application.id,
        user: Current.user,
        activity_type: "neighbour_letters_sent"
      )
    end
  end
end
