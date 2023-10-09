# frozen_string_literal: true

module PlanningApplications
  class ConsultationsController < AuthenticationController
    include ActionView::Helpers::SanitizeHelper
    include CommitMatchable

    before_action :set_planning_application
    before_action :set_consultation, except: %i[new create]
    before_action :assign_params, only: %i[update create]
    before_action :update_letter_statuses, only: %i[show edit]
    before_action :ensure_public_portal_is_active, only: :send_neighbour_letters
    before_action :set_geojson_features, only: %i[show edit update]

    def index
      respond_to do |format|
        format.html
      end
    end

    def show
      respond_to do |format|
        format.html
      end
    end

    def new
      @consultation = @planning_application.build_consultation
    end

    def edit
      respond_to do |format|
        format.html
      end
    end

    def create
      @consultation = @planning_application.build_consultation(@attributes)

      if @consultation.save!
        respond_to do |format|
          format.html { redirect_to planning_application_consultation_path(@planning_application, @consultation) }
        end
      else
        render :new
      end
    end

    def update
      if @consultation.update(@attributes)
        respond_to do |format|
          format.html { redirect_to planning_application_consultation_path(@planning_application, @consultation) }
        end
      else
        render :edit
      end
    end

    def destroy
      return unless @consultation.neighbours.find(params[:neighbour]).destroy

      respond_to do |format|
        format.html { redirect_to redirect_path }
      end
    end

    def send_neighbour_letters
      return if @consultation.blank?

      @consultation.update(neighbour_letter_text: consultation_params[:neighbour_letter_content])

      @planning_application.send_neighbour_consultation_letter_copy_mail

      # TODO: does this logic need to change when multiple letters can exist?
      @consultation.neighbours.reject(&:letter_created?).each do |neighbour|
        LetterSendingService.new(neighbour, consultation_params[:neighbour_letter_content]).deliver!
      end

      Audit.create!(
        planning_application_id: @consultation.planning_application.id,
        user: Current.user,
        activity_type: "neighbour_letters_sent"
      )

      respond_to do |format|
        format.html do
          redirect_to planning_application_consultation_path(@planning_application, @consultation),
                      flash: { sent_neighbour_letters: true }
        end
      end
    end

    private

    def consultation_params
      params.require(:consultation).permit(
        :planning_application_id,
        :neighbour_letter_content,
        neighbours_attributes: %i[consultation_id address id]
      ).merge(status:)
    end

    def assign_params
      if params[:commit] == "Add neighbour"
        @attributes = consultation_params.clone
        @attributes[:neighbours_attributes][:"0"][:address] = params[:"input-autocomplete"]
      else
        @attributes = consultation_params
                      .except(:neighbour_letter_content)
                      .merge(neighbour_letter_text: consultation_params[:neighbour_letter_content])
      end
    end

    def update_letter_statuses
      return if @consultation.neighbour_letters.none?

      # This is not ideal for now as will block the page loading, if it becomes a problem this would be
      # a good place for optimisation
      @consultation.neighbour_letters.each do |letter|
        letter.update_status unless letter.status == "received"
      end
    end

    def status
      save_progress? || add_neighbour? ? :in_progress : :complete
    end

    def ensure_public_portal_is_active
      return if @planning_application.make_public?

      flash.now[:alert] = sanitize "The planning application must be
      #{view_context.link_to 'made public on the BoPS Public Portal', make_public_planning_application_path(@planning_application)}
      before you can send letters to neighbours."

      render :show and return
    end

    def redirect_path
      if request.referer&.include?("edit")
        edit_planning_application_consultation_path(@planning_application, @consultation)
      else
        planning_application_consultation_path(@planning_application, @consultation)
      end
    end

    def set_geojson_features
      return unless @consultation.polygon_search

      @geojson_features = @consultation.polygon_search_and_boundary_geojson
    end
  end
end
