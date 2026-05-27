# frozen_string_literal: true

class ConditionsController < AuthenticationController
  before_action :set_conditions

  rescue_from Pagy::OverflowError do
    redirect_to conditions_path
  end

  def index
    respond_to do |format|
      format.json
    end
  end

  private

  def set_conditions
    @pagy, @conditions = pagy(current_local_authority.conditions.all_conditions(search_param), limit: 10)
  end

  def search_param
    params.fetch(:q, "")
  end
end
