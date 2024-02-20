# frozen_string_literal: true

class Condition < ApplicationRecord
  belongs_to :condition_set
  belongs_to :validation_request, optional: true, dependent: :destroy

  validates :text, :reason, presence: true

  after_create :create_validation_request, if: :pre_commencement?

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

  def create_validation_request
    update!(validation_request: ValidationRequest.create(type: "PreCommencementConditionValidationRequest", planning_application: condition_set.planning_application, post_validation: true, user: Current.user))
  end

  def pre_commencement?
    condition_set.pre_commencement?
  end
end
