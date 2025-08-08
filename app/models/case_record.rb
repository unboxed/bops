# frozen_string_literal: true

require "securerandom"

class CaseRecord < ApplicationRecord
  CASEABLE_TYPES = %w[Enforcement PlanningApplication].freeze

  delegated_type :caseable, types: CASEABLE_TYPES, dependent: :destroy

  has_many :tasks, -> { order(:position) }, as: :parent, dependent: :destroy, autosave: true

  belongs_to :local_authority
  belongs_to :user, optional: true
  belongs_to :submission, optional: true

  after_initialize :generate_uuid

  before_create :load_tasks!

  def find_task_by_path!(*slugs)
    slugs.inject(self) do |parent, slug|
      parent.tasks.find_by!(slug: slug)
    end
  end

  def find_task_by_slug_path!(slug_path)
    find_task_by_path!(*slug_path.to_s.split("/"))
  end

  def case_record
    self
  end

  CASEABLE_TYPES.each do |type|
    define_method(:"build_#{type.underscore}") do |caseable_params|
      klass = type.constantize
      caseable = klass.new(caseable_params)
      caseable.case_record = self

      caseable
    end
  end

  private

  def generate_uuid
    self.id ||= SecureRandom.uuid_v7
  end

  def load_tasks!
    return if tasks.exists? || planning_application?

    key = caseable_type.underscore
    TaskLoader.new(self, key).load!
  rescue => e
    errors.add(:base, "Couldn’t create case record tasks workflow: #{e.message}")
    throw(:abort)
  end
end
