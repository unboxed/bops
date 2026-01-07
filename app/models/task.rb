# frozen_string_literal: true

class Task < ApplicationRecord
  STATUSES = %w[not_started in_progress completed cannot_start_yet action_required]
  enum :status, STATUSES.index_by(&:to_sym)

  belongs_to :parent, polymorphic: true
  has_many :tasks, -> { order(:position) }, as: :parent, dependent: :destroy, autosave: true

  validates :slug, :name, presence: true, strict: true
  validates :status, inclusion: STATUSES

  after_initialize do
    self.slug ||= name.to_s.parameterize
    self.status ||= "not_started"
  end

  def start
    completed? || update(status: :in_progress)
  end

  def start!
    start || raise_not_saved("start")
  end

  def complete
    update(status: :completed)
  end

  def complete!
    complete || raise_not_saved("complete")
  end

  def action_required
    update(status: :action_required)
  end

  def action_required!
    action_required || raise_not_saved("action_required")
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

  def top_level_ancestor
    top_level? ? self : parent.top_level_ancestor
  end

  def task_for(slug)
    Task.find_by!(slug: slug)
  end

  def title
    I18n.t("bops_enforcements.tasks.title.#{slug}", default: name)
  end

  def first_child
    return self if section.blank?

    tasks.first&.first_child
  end

  private

  def raise_not_saved(transition)
    raise ActiveRecord::RecordNotSaved, "Unable to #{transition} the task #{name.inspect}"
  end
end
