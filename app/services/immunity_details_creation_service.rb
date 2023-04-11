# frozen_string_literal: true

class ImmunityDetailsCreationService
  def initialize(planning_application:)
    @planning_application = planning_application
  end

  def call 
    @immunity_details = @planning_application.proposal_details.select do |proposal_detail|
      proposal_detail.portal_name == "immunity-check"
    end

    immunity_detail = ImmunityDetail.new(planning_application: @planning_application)

    @immunity_details.each do |detail|
      if detail.question == "When were the works completed?"
        immunity_detail.end_date = detail.response_values.first
      end
    end

    immunity_detail.save!
  end

  private

  attr_reader :planning_application
end
