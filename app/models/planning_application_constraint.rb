# frozen_string_literal: true

class PlanningApplicationConstraint < ApplicationRecord
  include Auditable

  belongs_to :planning_application
  belongs_to :planning_application_constraints_query, optional: true
  belongs_to :constraint

  after_create :audit_constraint_added!
  after_update :audit_constraint_removed!, if: :identified_and_removed?
  before_destroy :audit_constraint_removed!

  delegate :type, :category, :type_code, to: :constraint
  delegate :audits, to: :planning_application

  scope :active, -> { where({ removed_at: nil }) }
  scope :identified_by_planx, -> { where({ identified_by: "PlanX" }) }
  scope :identified_by_others, -> { where({ removed_at: nil, identified: true }).where.not({ identified_by: "plax" }) }
  scope :removed, -> { where.not({ removed_at: nil }) }

  def start_date
    data.first["start-date"] if data
  end

  def description
    metadata["description"] if metadata
  end

  def checked?
    (identified? && !removed_at?) || !identified?
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
end
