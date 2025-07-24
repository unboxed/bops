# frozen_string_literal: true

class Enforcements::ReportsController < AuthenticationController
  before_action :set_enforcement

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

  def enforcement_params
    params.require(:enforcement).permit(:urgent)
  end
end
