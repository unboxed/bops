# frozen_string_literal: true

class Task < ApplicationRecord
  enum :status, %i[not_started in_progress completed].index_with(&:to_s)

  belongs_to :parent, polymorphic: true
  has_many :tasks, -> { order(:position) }, as: :parent, dependent: :destroy, autosave: true

  before_save :set_slug

  validates :slug, :name, presence: true

  def full_slug
    @full_slug ||= parent.is_a?(Task) ? "#{parent.full_slug}/#{slug}" : slug
  end

  def case_record
    @case_record ||= parent.try(:parent) || self
  end

  def to_param
    full_slug
  end

  private

  def set_slug
    self.slug = name.parameterize
  end
end
