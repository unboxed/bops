# frozen_string_literal: true

class PlanningApplicationConstraint < ApplicationRecord
  include Auditable

  enum :status, %i[
    pending
    success
    failed
    not_found
    removed
  ].index_with(&:to_s)

  belongs_to :planning_application
  belongs_to :planning_application_constraints_query, optional: true
  belongs_to :constraint

  has_many :planning_application_constraint_consultees, dependent: :destroy,
    inverse_of: :planning_application_constraint
  has_many :consultees, through: :planning_application_constraint_consultees

  accepts_nested_attributes_for :planning_application_constraint_consultees, allow_destroy: true

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

  def entity_data
    (planning_data_dataset && planning_data_geojson) ? {planning_data_dataset => planning_data_geojson} : {}
  end

  def planning_data_dataset
    return if entity.blank?

    planning_data_geojson.dig(:properties, :dataset)
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

  def entity
    data&.pick("entity")
  end

  def planning_data_geojson
    return if entity.blank?

    @planning_data_geojson ||= Apis::PlanningData::Query.new.get_entity_geojson(entity)
  end
end
