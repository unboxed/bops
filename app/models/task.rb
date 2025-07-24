# frozen_string_literal: true

class Task < ApplicationRecord
  belongs_to :parent, polymorphic: true

  has_many :tasks, -> { order(:position) }, as: :parent, dependent: :destroy, autosave: true

  before_save :set_slug

  validates :slug, :name, presence: true

  enum status: {
    not_started: "not_started",
    in_progress: "in_progress",
    completed: "completed"
  }

  def full_slug
    @full_slug ||= parent.is_a?(Task) ? "#{parent.full_slug}/#{slug}" : slug
  end

  def case_record
    @case_record ||= parent.try(:parent) || self
  end

  private

  def set_slug
    self.slug = name.parameterize
  end
end
