# frozen_string_literal: true

require "securerandom"

class CaseRecord < ApplicationRecord
  CHECK_FEE_SLUG = "check-and-validate/check-application-details/check-fee"
  CHECK_RED_LINE_BOUNDARY_SLUG = "check-and-validate/check-application-details/check-red-line-boundary"
  DRAW_RED_LINE_BOUNDARY_SLUG = "check-and-validate/check-application-details/draw-red-line-boundary"

  delegated_type :caseable, types: %w[Enforcement PlanningApplication], dependent: :destroy

  has_many :tasks, -> { order(:position) }, as: :parent, dependent: :destroy, autosave: true
  has_many :documents, dependent: :destroy

  belongs_to :local_authority
  belongs_to :user, optional: true
  belongs_to :submission, optional: true

  delegate :email, to: :user, prefix: true, allow_nil: true

  after_initialize :generate_uuid

  before_create :load_tasks!
  after_create :configure_boundary_task_visibility!

  def find_task_by_path!(*slugs)
    slugs.inject(self) do |parent, slug|
      parent.tasks.find_by!(slug: slug)
    end
  end

  def find_task_by_slug_path!(slug_path)
    find_task_by_path!(*slug_path.to_s.split("/"))
  end

  def find_task_by_slug_path(slug_path)
    find_task_by_slug_path!(slug_path)
  rescue ActiveRecord::RecordNotFound
    nil
  end

  def case_record
    self
  end

  private

  def generate_uuid
    self.id ||= SecureRandom.uuid_v7
  end

  def load_tasks!
    return if tasks.exists?
    return if planning_application? && !planning_application.pre_application?

    TaskLoader.new(self, caseable.task_workflow).load!
  rescue => e
    errors.add(:base, "Couldn’t create case record tasks workflow: #{e.message}")
    throw(:abort)
  end

  def reload_tasks!
    return if planning_application? && !planning_application.pre_application?

    TaskLoader.new(self, caseable.task_workflow).reload!
  end

  def configure_boundary_task_visibility!
    return unless planning_application?

    if planning_application.boundary_geojson.blank?
      find_task_by_slug_path(DRAW_RED_LINE_BOUNDARY_SLUG)&.update!(hidden: false)
      find_task_by_slug_path(CHECK_RED_LINE_BOUNDARY_SLUG)&.update!(hidden: true)
    end
  end
end
