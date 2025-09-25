# frozen_string_literal: true

module PlanningApplications
  class NeighbourLettersController < AuthenticationController
    include CommitMatchable

    before_action :set_planning_application
    before_action :redirect_to_application_page, unless: :public_or_preapp?

    before_action :set_consultation
    before_action :set_neighbour, only: %i[update destroy]
    before_action :update_letter_statuses, only: %i[index]

    with_options only: :send_letters do
      before_action :ensure_public_portal_is_active
      before_action :ensure_neighbours_have_been_added
      before_action :require_reason_when_resending
    end

    def index
      respond_to do |format|
        format.html
      end
    end

    def update
      @neighbour.update!(neighbour_params)

      respond_to do |format|
        format.html do
          redirect_to planning_application_consultation_neighbour_letters_path(@planning_application)
        end
      end
    end

    def destroy
      @neighbour.destroy!

      respond_to do |format|
        format.html do
          redirect_to planning_application_consultation_neighbour_letters_path(@planning_application)
        end
      end
    end

    def send_letters
      ActiveRecord::Base.transaction do
        update_consultation!
        deliver_letters!
        send_neighbour_consultation_letter_copy
        create_review!
        record_audit_for_letters_sent!
      end

      respond_to do |format|
        format.html do
          redirect_to planning_application_consultation_neighbour_letters_path(@planning_application),
            flash: {sent_neighbour_letters: true}
        end
      end
    rescue Neighbour::AddressValidationError => e
      redirect_after_rescue(e)
    rescue ActiveRecord::RecordInvalid => e
      redirect_after_rescue(e)
    end

    private

    def neighbour_id
      Integer(params[:id])
    rescue ArgumentError
      raise ActionController::BadRequest, "Invalid neighbour id: #{params[:id].inspect}"
    end

    def set_neighbour
      @neighbour = @consultation.neighbours.find(neighbour_id)
    end

    def consultation_params
      params.require(:consultation).permit(
        :neighbour_letter_text,
        :resend_existing,
        :resend_reason,
        :deadline_extension,
        :polygon_geojson,
        neighbours_attributes: %i[id selected]
      )
    end

    def neighbour_params
      params.require(:neighbour).permit(:address)
    end

    def update_letter_statuses
      NeighbourLetterStatusUpdateJob.perform_later(@consultation)
    end

    def ensure_public_portal_is_active
      return if @planning_application.make_public?

      flash.now[:alert] = t(".make_public_html", href: make_public_planning_application_path(@planning_application))
      render :index and return
    end

    def ensure_neighbours_have_been_added
      return if neighbours_to_contact.present?

      flash.now[:alert] = t(".add_neighbours")
      render :index and return
    end

    def require_reason_when_resending
      return unless resend_existing?
      return if resend_reason.present?

      flash.now[:alert] = t(".require_resend_reason")
      render :index and return
    end

    def update_consultation!
      @consultation.update!(consultation_params.except(:resend_existing, :resend_reason).merge(status: "in_progress"), :apply_deadline_extension)
    end

    def send_neighbour_consultation_letter_copy
      @planning_application.send_neighbour_consultation_letter_copy_mail
    end

    def deliver_letters!
      LetterSendingService.new(@consultation.neighbour_letter_text, consultation: @consultation, resend_reason:, letter_type: :consultation).deliver_batch!(neighbours_to_contact)
    end

    def neighbours_to_contact
      consultation_params[:neighbours_attributes].to_h.map do |key, value|
        next unless value[:selected] == "1"

        @consultation.neighbours.find(value[:id].to_i)
      end.compact
    end

    def resend_existing?
      consultation_params[:resend_existing] == "true"
    end

    def resend_reason
      consultation_params[:resend_reason] if resend_existing?
    end

    def create_review!
      @consultation.create_neighbour_review! if @consultation.neighbour_review.blank? || @consultation.neighbour_review.to_be_reviewed?
    end

    def redirect_after_rescue(error)
      redirect_to planning_application_consultation_neighbour_letters_path(@planning_application), alert: error
    end

    def record_audit_for_letters_sent!
      Audit.create!(
        planning_application_id: @planning_application.id,
        user: Current.user,
        activity_type: "neighbour_letters_sent"
      )
    end

    def redirect_to_application_page
      redirect_to make_public_planning_application_path(@planning_application), alert: t(".make_public")
    end

    def public_or_preapp?
      @planning_application.make_public? || @planning_application.pre_application?
    end
  end
end
