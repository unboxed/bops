# frozen_string_literal: true

class CreateImmunityDetailsJob < ApplicationJob
  queue_as :urgent

  def perform(planning_application:)
    ImmunityDetailsCreationService.new(
      planning_application:
    ).call
  end
end
