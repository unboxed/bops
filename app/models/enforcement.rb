# frozen_string_literal: true

class Enforcement < ApplicationRecord
  include Caseable

  include EnforcementStatus

  STATUS_COLOURS = {
    closed: "red",
    not_started: "blue",
    under_investigation: "green"
  }.freeze

  # TODO: Drop this column after deployment to production
  self.ignored_columns += %i[boundary_geojson]

  composed_of :address,
    mapping: {
      address_1: :line_1,
      address_2: :line_2,
      town: :town,
      county: :county,
      postcode: :postcode
    }

  after_initialize -> { self.received_at ||= Time.zone.now }

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

  private

  def factory
    @factory ||= RGeo::Geographic.spherical_factory(srid: 4326)
  end
end
