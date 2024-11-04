# frozen_string_literal: true

class InformativesController < AuthenticationController
  before_action :set_informatives

  rescue_from Pagy::OverflowError do
    redirect_to informatives_path
  end

  def index
    respond_to do |format|
      format.json
    end
  end

  private

  def set_informatives
    @pagy, @informatives = pagy(current_local_authority.informatives.all_informatives(search_param), items: 10)
  end

  def search_param
    params.fetch(:q, "")
  end
end
