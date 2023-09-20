# frozen_string_literal: true

class PlanningApplicationConstraint < ApplicationRecord
  include Auditable

  belongs_to :planning_application
  belongs_to :planning_application_constraints_query, optional: true
  belongs_to :constraint

  after_create :audit_constraint_added!
  before_destroy :audit_constraint_removed!

  delegate :type, to: :constraint
  delegate :audits, to: :planning_application

  scope :active, -> { where({ removed_at: nil }) }
  scope :removed, -> { where.not({ removed_at: nil }) }

  private

  def audit_constraint_added!
    audit!(activity_type: "constraint_added", audit_comment: constraint.type_code)
  end

  def audit_constraint_removed!
    audit!(activity_type: "constraint_removed", audit_comment: constraint.type_code)
  end
end
