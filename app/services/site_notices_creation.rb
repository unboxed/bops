# frozen_string_literal: true

class SiteNoticesCreation
  ATTRIBUTES = %i[
    reference
    displayed_at
    expiry_date
    planning_application_id
    required
  ].freeze

  def initialize(**params)
    ATTRIBUTES.each do |attribute|
      value = params[attribute]
      value = value.is_a?(String) ? value.strip : value
      instance_variable_set(:"@#{attribute}", value)
    end
  end

  def perform
    importer
  end

  private

  attr_reader(*ATTRIBUTES)

  def importer
    planning_application_id = find_index(reference)
    return nil if planning_application_id.blank?

    site_notice = SiteNotice.new(**site_notice_attributes.merge(planning_application_id: planning_application_id))

    site_notice.save!
  rescue => e
    Rails.logger.debug { "[IMPORT ERROR] #{e.class}: #{e.message}" }
    Rails.logger.debug e.record&.errors&.full_messages&.join(", ")
    raise
  end

  def find_index(reference)
    PlanningApplication
      .where("previous_references @> ARRAY[?]::varchar[]", reference)
      .pick(:id)
  end

  def site_notice_attributes
    {
      displayed_at:,
      expiry_date:,
      planning_application_id:,
      required: true
    }
  end
end