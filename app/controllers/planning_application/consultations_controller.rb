# frozen_string_literal: true

class PlanningApplication
  class ConsultationsController < AuthenticationController
    include CommitMatchable

    before_action :set_planning_application
    before_action :set_consultation, except: %i[new create]
    before_action :assign_params, only: %i[update create]
    before_action :update_letter_statuses, only: %i[show edit]

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
      if @consultation.update!(@attributes)
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
        format.html { redirect_to edit_planning_application_consultation_path(@planning_application, @consultation) }
      end
    end

    def send_neighbour_letters
      return if @consultation.blank?

      @planning_application.send_neighbour_consultation_letter_copy_mail

      @consultation.neighbours.reject(&:letter_created?).each do |neighbour|
        LetterSendingService.new(neighbour).deliver!
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

    def set_planning_application
      planning_application = planning_applications_scope.find(planning_application_id)

      @planning_application = PlanningApplicationPresenter.new(view_context, planning_application)
    end

    def set_consultation
      @consultation = @planning_application.consultation
    end

    def planning_applications_scope
      current_local_authority.planning_applications
    end

    def planning_application_id
      Integer(params[:planning_application_id])
    end

    def consultation_params
      params.require(:consultation).permit(
        :planning_application_id,
        neighbours_attributes: %i[consultation_id address id]
      ).merge(status:)
    end

    def assign_params
      if params[:commit] == "Add neighbour"
        @attributes = consultation_params.clone
        @attributes[:neighbours_attributes][:"0"][:address] = params[:"input-autocomplete"]
      else
        @attributes = consultation_params
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
  end
end
