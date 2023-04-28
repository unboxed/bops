# frozen_string_literal: true

class EvidenceGroupPresenter
  include Presentable
  presents :evidence_group

  def initialize(template, evidence_group)
    @template = template
    @evidence_group = evidence_group
  end

  def name
    evidence_group.tag.humanize.pluralize
  end

  def date_range
    if start_date.present?
      start_date.to_fs(:day_month_year_slashes) +
        (end_date.present? ? " to #{end_date.to_fs(:day_month_year_slashes)}" : "")
    else
      "dates unknown"
    end
  end

  private

  attr_reader :evidence_group
end
