# frozen_string_literal: true

namespace :jobs do
  desc "Close description change requests open for over 5 days"
  task close_description_change: :environment do
    CloseDescriptionChangeJob.perform_later
  end
end
