# frozen_string_literal: true

module PlanningApplications
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
            redirect_to planning_application_path(@planning_application), notice: t(".success")
          end
        else
          format.html { render :index }
        end
      end
    end

    private

    def planning_applications_scope
      super.includes(:notes)
    end

    def note_params
      params.require(:note).permit(:entry)
    end
  end
end
