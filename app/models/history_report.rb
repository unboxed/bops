# frozen_string_literal: true

class HistoryReport < ApplicationRecord
  belongs_to :planning_application

  validates :raw, presence: true

  class << self
    def refresh
      HistoryReportJob.perform_later(planning_application)
    end
  end
end
