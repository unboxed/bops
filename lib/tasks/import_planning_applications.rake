# frozen_string_literal: true

namespace :import do
  desc "Import planning applications from CSV with local_authority_id"
  task planning_applications: :environment do
    abort("Please provide LOCAL_AUTHORITY") if ENV["LOCAL_AUTHORITY"].blank?
    csv_path = ENV["CSV"]
    local_authority_name = ENV["LOCAL_AUTHORITY"]

    unless csv_path && local_authority_name
      broadcast "Usage: rake import:planning_applications CSV=path/to/file.csv LOCAL_AUTHORITY=Southwark"
      exit 1
    end

    PlanningApplicationsImportService.new(
      csv_path: csv_path,
      local_authority_name: ENV["LOCAL_AUTHORITY"]
    ).run
  end

  def broadcast(message)
    puts message
    Rails.logger.info message
  end
end
