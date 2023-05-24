# frozen_string_literal: true

class PlanningApplication
  class ConsultationsController < AuthenticationController
    before_action :set_planning_application
    before_action :set_consultation, except: [:new, :create]
    before_action :mess_with_params, only: [:update, :create]

    def new
      @consultation = @planning_application.build_consultation
    end

    def edit
      respond_to do |format|
        format.html
      end
    end

    def update
      if @consultation.update!(@attributes)
        respond_to do |format|
          format.html { redirect_to edit_planning_application_consultation_path(@planning_application, @consultation) }
        end
      else
        render :edit
      end
    end

    def create
      @consultation = @planning_application.build_consultation(@attributes)

      if @consultation.save!
        respond_to do |format|
          format.html { redirect_to edit_planning_application_consultation_path(@planning_application, @consultation) }
        end
      else
        render :new
      end
    end

    def destroy
      if @consultation.neighbours.find(params[:neighbour]).destroy
        respond_to do |format|
          format.html { redirect_to edit_planning_application_consultation_path(@planning_application, @consultation) }
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
        neighbours_attributes: [:consultation_id, :address, :id]
      )
    end

    def mess_with_params
      if params[:commit] == "Add neighbour"
        @attributes = consultation_params.clone
        @attributes[:neighbours_attributes][:"0"][:address] = params[:"input-autocomplete"]
      else 
        @attributes = consultation_params
      end
    end
  end
end
