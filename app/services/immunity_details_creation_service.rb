# frozen_string_literal: true

class ImmunityDetailsCreationService
  def initialize(planning_application:)
    @planning_application = planning_application
  end

  def call
    transaction do
      immunity_detail = ImmunityDetail.new(planning_application: @planning_application)
      immunity_detail.end_date = application_end_date
      immunity_detail.save
    end
  end

  private

  attr_reader :planning_application

  def application_end_date
    @planning_application.find_proposal_detail("When were the works completed?").first.response_values.first
  end
end
