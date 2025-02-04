# frozen_string_literal: true

class PolicyReferencesController < AuthenticationController
  before_action :set_policy_references

  rescue_from Pagy::OverflowError do
    redirect_to policy_references_path
  end

  def index
    respond_to do |format|
      format.json
    end
  end

  private

  def set_policy_references
    @pagy, @policy_references = pagy(current_local_authority.policy_references.search(search_param), limit: 10)
  end

  def search_param
    params.fetch(:q, "")
  end
end
