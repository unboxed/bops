# frozen_string_literal: true

class DrawingsController < AuthenticationController
  def drawing_params
    params.require(:drawing).permit(:name, :plan, :planning_application_id)
  end
end
