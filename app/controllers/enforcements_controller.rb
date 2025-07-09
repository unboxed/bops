# frozen_string_literal: true

class EnforcementsController < AuthenticationController
  before_action :set_enforcement, only: %i[show]

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
      .find_by!(case_record: {id: params[:id]})
  end
end
