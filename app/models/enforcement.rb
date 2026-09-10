# frozen_string_literal: true

class Enforcement < ApplicationRecord
  include Caseable

  include EnforcementStatus

  include Auditable

  has_many :audits, as: :auditable

  delegate :documents, to: :case_record

  STATUS_COLOURS = {
    closed: "red",
    not_started: "blue",
    under_investigation: "green"
  }.freeze

  composed_of :address,
    mapping: {
      address_1: :line_1,
      address_2: :line_2,
      town: :town,
      county: :county,
      postcode: :postcode
    }

  after_initialize -> { self.received_at ||= Time.zone.now }
  after_create :audit_created!
  after_update :audit_updated!

  AUDIT_ATTRIBUTES = %w[
    address_1
    address_2
    county
    description
    postcode
    proposal_details
    town
    uprn
  ].freeze

  scope :by_received_at_desc, -> { order(received_at: :desc) }
  delegate :to_s, to: :address

  def boundary_geojson
    return if boundary.blank?

    features = boundary.map do |geometry|
      RGeo::GeoJSON::Feature.new(geometry)
    end

    collection = RGeo::GeoJSON::FeatureCollection.new(features)
    RGeo::GeoJSON.encode(collection)
  end

  def boundary_geojson=(value)
    geojson = RGeo::GeoJSON.decode(value, geo_factory: factory)

    geometries =
      case geojson
      when RGeo::GeoJSON::FeatureCollection
        geojson.map { |feature| feature.geometry }
      when RGeo::GeoJSON::Feature
        [geojson.geometry]
      else
        raise ArgumentError, "Unexpected GeoJSON entity - it must be Feature or FeatureCollection"
      end

    collection = factory.collection(geometries)
    self.boundary = collection
  end

  def to_param
    case_record.id
  end

  def proposal_details
    Array(super).each_with_index.map do |hash, index|
      ProposalDetail.new(hash, index)
    end
  end

  def status_tag_colour
    STATUS_COLOURS[status.to_sym]
  end

  def days_from
    created_at.to_date.business_days_until(Time.previous_business_day(Date.current))
  end

  def latitude
    lonlat&.y
  end

  def longitude
    lonlat&.x
  end

  def complainant
    @complainant ||= Complainant.new(submission.request_body&.dig("data", "complainant"))
  end

  def task_workflow
    model_name.singular
  end

  def url_helpers
    BopsEnforcements::Engine.routes.url_helpers
  end

  def full_address
    "#{address_1}, #{town}, #{postcode}"
  end

  def reference
    case_record.id
  end

  private

  def factory
    @factory ||= RGeo::Geographic.spherical_factory(srid: 4326)
  end

  def audit_created!
    audit!(activity_type: "created", activity_information: Current.api_user&.name || Current.user&.name)
  end

  def audit_updated!
    return unless saved_changes?

    saved_changes.keys.intersection(AUDIT_ATTRIBUTES).map do |attribute_name|
      next if saved_change_to_attribute(attribute_name).all? { |value| value.blank? || value.try(:zero?) }

      original_attribute = saved_change_to_attribute(attribute_name).first
      new_attribute = saved_change_to_attribute(attribute_name).second

      audit!(activity_type: "updated",
        activity_information: attribute_name.humanize,
        audit_comment: "Changed from: #{original_attribute} \r\n Changed to: #{new_attribute}")
    end
  end
end
