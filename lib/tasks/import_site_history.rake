# frozen_string_literal: true

namespace :import do
  desc "Import planning applications"
  task planning_applications: :environment do
    local_authority = ENV["AUTHORITY"]
    if local_authority.nil?
      puts "Usage: rake import:planning_applications AUTHORITY=Buckinghamshire"
      exit 1
    end

    puts "Enqueuing ImportSiteHistoryJob for PlanningApplicationsCreation"
    ImportSiteHistoryJob.perform_now(
      local_authority_name: local_authority,
      create_class_name: "PlanningApplicationsCreation"
    )
  end

  desc "Import users"
  task planning_applications: :environment do
    local_authority = ENV["AUTHORITY"]
    if local_authority.nil?
      puts "Usage: rake import:users AUTHORITY=Buckinghamshire"
      exit 1
    end

    puts "Enqueuing ImportSiteHistoryJob for UsersCreation"
    ImportSiteHistoryJob.perform_now(
      local_authority_name: local_authority,
      create_class_name: "UsersCreation"
    )
  end
end
