# frozen_string_literal: true

namespace :jobs do
  desc "Close red line boundary change requests that have been open for more than 5 business days"
  task close_description_change: :environment do
    CloseRedLineBoundaryChangeValidationRequestJob.perform_later
  end
end
