# frozen_string_literal: true

class EnforcementsController < AuthenticationController
  before_action :set_enforcement, only: %i[show]
  before_action :set_enforcements, only: %i[index]

  def index
    respond_to do |format|
      format.html
    end
  end

  def show
    respond_to do |format|
      format.html
    end
  end

  private

  def set_enforcements
    @enforcements = current_local_authority
      .enforcements
      .joins(:case_record)
      .by_received_at_desc
  end

  def set_enforcement
    @enforcement = current_local_authority
      .enforcements
      .joins(:case_record)
      .find_by!(case_record: {id: params[:id]})
  end
end
