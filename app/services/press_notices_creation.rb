# frozen_string_literal: true

class PressNoticesCreation
  ATTRIBUTES = %i[
    published_at
    expired_at
    reference
  ].freeze

  def initialize(**params)
    ATTRIBUTES.each do |attribute|
      instance_variable_set(:"@#{attribute}", params[attribute])
    end
  end

  def perform
    importer
  end

  private

  attr_reader(*ATTRIBUTES)

  def importer
    planning_application = find_planning_application_by_previous_reference

    raise "No matching planning application found for reference: #{reference}" unless planning_application

    press_notice = PressNotice.find_or_initialize_by(
      planning_application_id: planning_application.id,
      published_at: published_at
    )

    press_notice.update!(
      published_at:,
      expired_at:,
      planning_application_id: planning_application.id
    )

    press_notice
  rescue => e
    Rails.logger.debug { "[IMPORT ERROR] #{e.class}: #{e.message}" }
    Rails.logger.debug press_notice&.errors&.full_messages&.join(", ")
    raise
  end

  def find_planning_application_by_previous_reference
    PlanningApplication.where("? = ANY (previous_references)", reference).first
  end
end
