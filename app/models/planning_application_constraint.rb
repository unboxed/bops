# frozen_string_literal: true

class PlanningApplicationConstraint < ApplicationRecord
  include Auditable

  belongs_to :planning_application
  belongs_to :planning_application_constraints_query, optional: true
  belongs_to :constraint

  after_create :audit_constraint_added!
  before_destroy :audit_constraint_removed!

  delegate :name, to: :constraint
  delegate :audits, to: :planning_application

  private

  def audit_constraint_added!
    audit!(activity_type: "constraint_added", audit_comment: name)
  end

  def audit_constraint_removed!
    audit!(activity_type: "constraint_removed", audit_comment: name)
  end
end
