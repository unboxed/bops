# frozen_string_literal: true

class ConsulteesController < AuthenticationController
  before_action :set_planning_application

  def create
    consultee = planning_application.consultees.new(consultee_params)
    consultee = planning_application.consultees.new if consultee.save
    render(json: { partial: consultees_partial(consultee) })
  end

  def destroy
    planning_application.consultees.find(params[:id]).destroy
    render(json: { partial: consultee_table_partial })
  end

  private

  attr_reader :planning_application

  def consultees_partial(consultee)
    render_to_string(
      partial: "planning_application/assessment_details/consultation_summary/consultees",
      locals: {
        planning_application: planning_application,
        consultee: consultee,
        read_only: false
      }
    )
  end

  def consultee_table_partial
    render_to_string(
      partial: "planning_application/assessment_details/consultation_summary/consultee_table",
      locals: {
        planning_application: planning_application,
        read_only: false
      }
    )
  end

  def consultee_params
    params.require(:consultee).permit(:name, :origin)
  end
end
