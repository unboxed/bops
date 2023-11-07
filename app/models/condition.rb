# frozen_string_literal: true

class Condition < ApplicationRecord
  belongs_to :condition_set

  validates :text, :reason, presence: true

  def checked?
    persisted? || errors.present?
  end

  def sort_key
    [title_key, timestamp_key, Float::INFINITY].compact.first
  end

  def review_title
    title.presence || "Other"
  end

  private

  def titles
    @titles ||= I18n.t(:conditions_list).values.pluck(:title)
  end

  def title_key
    titles.index(title)
  end

  def timestamp_key
    created_at&.to_i
  end
end
