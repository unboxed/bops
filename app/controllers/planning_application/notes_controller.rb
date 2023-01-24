# frozen_string_literal: true

class PlanningApplication
  class NotesController < AuthenticationController
    before_action :set_planning_application

    def index
      @notes = @planning_application.notes
      @note = Note.new

      respond_to do |format|
        format.html
      end
    end

    def create
      @note = @planning_application.notes.new(note_params)
      @note.user = current_user

      respond_to do |format|
        if @note.save
          format.html do
            redirect_to planning_application_path(@planning_application), notice: "Note was successfully created."
          end
        else
          format.html { render :index }
        end
      end
    end

    private

    def set_planning_application
      planning_application = planning_applications_scope.find(planning_application_id)

      @planning_application = PlanningApplicationPresenter.new(view_context, planning_application)
    end

    def planning_applications_scope
      current_local_authority.planning_applications.includes(:notes)
    end

    def planning_application_id
      Integer(params[:planning_application_id])
    end

    def note_params
      params.require(:note).permit(:entry)
    end
  end
end
