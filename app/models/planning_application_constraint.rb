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
  after_commit :enqueue_consultee_sync, on: :create

  delegate :type, :category, :type_code, to: :constraint
  delegate :audits, :local_authority, :consultation, to: :planning_application

  scope :active, -> { where({removed_at: nil}) }
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

  def added?
    true
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

  def sync_consultees!
    return if consultation.blank? || constraint.blank?

    contacts_for_constraint = constraint.consultee_contacts.where(local_authority_id: local_authority.id)

    consultee_ids = contacts_for_constraint.map { |contact| find_or_create_consultee!(contact).id }.uniq

    existing_consultee_ids = planning_application_constraint_consultees.pluck(:consultee_id)
    additions = consultee_ids - existing_consultee_ids

    additions.each do |consultee_id|
      planning_application_constraint_consultees.find_or_create_by!(consultee_id: consultee_id)
    end
  end

  private

  def find_or_create_consultee!(contact)
    email = contact.email_address.strip.downcase

    attrs = {
      email_address: email,
      name: contact.name,
      origin: contact.origin,
      role: contact.role,
      organisation: contact.organisation
    }

    consultation.consultees.find_or_create_by!(attrs)
  end

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

  def enqueue_consultee_sync
    return if constraint_id.blank?

    SyncConstraintConsulteesJob.perform_later(id)
  end
end
