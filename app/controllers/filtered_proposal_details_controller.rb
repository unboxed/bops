# frozen_string_literal: true

class FilteredProposalDetailsController < AuthenticationController
  def create
    planning_application = set_planning_application
    planning_application.hide_auto_answered_proposal_details = hide_auto_answered_proposal_details

    render(
      json: {
        html: render_to_string(
          partial: "planning_applications/proposal_details",
          locals: { planning_application: planning_application }
        )
      }
    )
  end

  private

  def hide_auto_answered_proposal_details
    ActiveModel::Type::Boolean.new.cast(
      planning_application_params[:hide_auto_answered_proposal_details]
    )
  end

  def planning_application_params
    params.require(:planning_application).permit(:hide_auto_answered_proposal_details)
  end
end
