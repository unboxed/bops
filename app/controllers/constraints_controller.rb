# frozen_string_literal: true

class ConstraintsController < AuthenticationController
  before_action :set_planning_application
  before_action :ensure_constraint_edits_unlocked, only: %i[edit update]


  def edit; end

  def update
    if @planning_application.update(constraints: constraints_params[:constraints].compact_blank)
      redirect_to @planning_application, notice: "Constraints have been updated"
    else
      render :edit
    end
  end

  private

  def constraints_params
    params.require(:planning_application).permit(constraints: [])
  end

  def ensure_constraint_edits_unlocked
    render plain: "forbidden", status: :forbidden and return unless @planning_application.can_validate?
  end
end
