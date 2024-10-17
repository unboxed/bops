# frozen_string_literal: true

class PlanningApplicationConstraint < ApplicationRecord
  include Auditable

  enum status: {
    pending: "pending",
    success: "success",
    failed: "failed",
    not_found: "not_found",
    removed: "removed"
  }

  belongs_to :planning_application
  belongs_to :planning_application_constraints_query, optional: true
  belongs_to :constraint
  belongs_to :consultee, optional: true

  after_create :audit_constraint_added!
  after_update :audit_constraint_removed!, if: :identified_and_removed?
  before_destroy :audit_constraint_removed!

  delegate :type, :category, :type_code, to: :constraint
  delegate :audits, to: :planning_application

  scope :active, -> { where({removed_at: nil}) }
  scope :identified_by_planx, -> { where({identified_by: "PlanX"}) }
  scope :identified_by_others, -> { where({removed_at: nil, identified: true}).where.not({identified_by: "plax"}) }
  scope :removed, -> { where.not({removed_at: nil}) }

  def start_date
    data.first["start-date"] if data.present?
  end

  def description
    metadata["description"] if metadata
  end

  def dataset
    data&.pluck("dataset")
  end

  def checked?
    (identified? && !removed_at?) || !identified?
  end

  def entities
    data&.pluck("name", "entity")
  end

  def entity
    data&.pick("entity")
  end

  def entity_data
    {
      planning_data[:dataset] => convert_multipolygon_to_geojson(planning_data[:geometry])
    }
  end

  private

  def identified_and_removed?
    identified? && removed_at?
  end

  def audit_constraint_added!
    audit!(activity_type: "constraint_added", audit_comment: constraint.type_code)
  end

  def audit_constraint_removed!
    audit!(activity_type: "constraint_removed", audit_comment: constraint.type_code)
  end

  def planning_data
    @planning_data ||= Apis::PlanningData::Query.new.get_entity(entity)
  end

  def convert_multipolygon_to_geojson(wkt_string)
    if wkt_string.present?
      # Create a factory to parse the WKT
      factory = RGeo::Geographic.spherical_factory(srid: 4326)

      # Parse the WKT string (which is the MULTIPOLYGON)
      wkt_parser = RGeo::WKRep::WKTParser.new(factory)
      multipolygon = wkt_parser.parse(wkt_string)

      # Convert to GeoJSON
      geojson = RGeo::GeoJSON.encode(multipolygon)

      geojson
    end
  end
end
