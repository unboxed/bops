# frozen_string_literal: true

class RequirementsController < AuthenticationController
  before_action :set_requirements

  rescue_from Pagy::OverflowError do
    redirect_to requirements_path
  end

  def index
    respond_to do |format|
      format.json
    end
  end

  private

  def set_requirements
    @pagy, @requirements = pagy(current_local_authority.requirements.search(search_param), limit: 10)
  end

  def search_param
    params.fetch(:q, "")
  end
end
