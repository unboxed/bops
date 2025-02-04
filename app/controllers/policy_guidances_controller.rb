# frozen_string_literal: true

class PolicyGuidancesController < AuthenticationController
  before_action :set_policy_guidances

  rescue_from Pagy::OverflowError do
    redirect_to policy_guidances_path
  end

  def index
    respond_to do |format|
      format.json
    end
  end

  private

  def set_policy_guidances
    @pagy, @policy_guidances = pagy(current_local_authority.policy_guidances.search(search_param), limit: 10)
  end

  def search_param
    params.fetch(:q, "")
  end
end
