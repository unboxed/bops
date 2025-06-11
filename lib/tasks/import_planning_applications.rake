# frozen_string_literal: true

namespace :import do
  desc "Import planning applications from CSV with local_authority_id"
  task planning_applications: :environment do
    csv_path = ENV["CSV"]
    authority_id = ENV["AUTHORITY_ID"]

    unless csv_path && authority_id
      puts "Usage: rake import:planning_applications CSV=path/to/file.csv AUTHORITY_ID=123"
      exit 1
    end

    PlanningApplicationsImportService.new(
      csv_path: csv_path,
      authority_id: authority_id
    ).run
  end
end
