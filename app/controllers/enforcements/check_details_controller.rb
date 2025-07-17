# frozen_string_literal: true

class Enforcements::CheckDetailsController < AuthenticationController
  before_action :set_enforcement
  before_action :set_proposal_details

  def show
    respond_to do |format|
      format.html
    end
  end

  private

  def set_enforcement
    @enforcement = current_local_authority
      .enforcements
      .joins(:case_record)
      .find_by!(case_record: {id: params[:enforcement_id]})
  end

  def set_proposal_details
    @proposal_details = @enforcement.proposal_details
  end
end
