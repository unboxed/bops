# frozen_string_literal: true

class ConsulteesController < AuthenticationController
  before_action :set_planning_application
  before_action :set_consultation
  before_action :set_consultee, only: %i[edit update]

  def edit
    respond_to do |format|
      format.html
    end
  end

  def create
    consultee = @consultation.consultees.new(consultee_params)
    consultee = @consultation.consultees.new if consultee.save
    render(json: { partial: consultees_partial(consultee) })
  end

  def update
    if @consultee.update(consultee_params)
      redirect_to after_update_consultees_path, notice: t(".success")
    else
      render :edit
    end
  end

  def destroy
    @consultation.consultees.find(params[:id]).destroy
    render(json: { partial: consultee_table_partial })
  end

  private

  attr_reader :planning_application

  def after_update_consultees_path
    # it's possible that the list of consultees is being edited before the
    # consultation summary has been saved and so we can't link to the edit path
    if (consultation_summary = planning_application.consultation_summary)
      edit_planning_application_assessment_detail_path(planning_application, consultation_summary,
                                                       category: "consultation_summary")
    else
      new_planning_application_assessment_detail_path(planning_application, category: "consultation_summary")
    end
  end

  def set_consultee
    @consultee = @consultation.consultees.find(Integer(params[:id]))
  end

  def consultees_partial(consultee)
    render_to_string(
      partial: "planning_applications/assessment_details/consultation_summary/consultees",
      locals: {
        planning_application:,
        consultee:,
        read_only: false
      }
    )
  end

  def consultee_table_partial
    render_to_string(
      partial: "planning_applications/assessment_details/consultation_summary/consultee_table",
      locals: {
        planning_application:,
        read_only: false
      }
    )
  end

  def consultee_params
    params.require(:consultee).permit(:name, :origin, :response)
  end
end
