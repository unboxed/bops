# frozen_string_literal: true

class Task < ApplicationRecord
  enum :status, %i[not_started in_progress completed].index_with(&:to_s)

  belongs_to :parent, polymorphic: true
  has_many :tasks, -> { order(:position) }, as: :parent, dependent: :destroy, autosave: true

  validates :slug, :name, presence: true, strict: true

  after_initialize do
    self.slug ||= name.to_s.parameterize
    self.status ||= "not_started"
  end

  def full_slug
    @full_slug ||= parent.is_a?(Task) ? "#{parent.full_slug}/#{slug}" : slug
  end

  def case_record
    @case_record ||= parent&.case_record || self
  end

  def to_param
    full_slug
  end

  def top_level?
    parent_type == "CaseRecord"
  end

  def task_for(slug)
    Task.find_by!(slug: slug)
  end
end
