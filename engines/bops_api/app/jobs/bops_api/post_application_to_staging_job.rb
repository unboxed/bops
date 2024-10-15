# frozen_string_literal: true

module BopsApi
  class PostApplicationToStagingJob < ApplicationJob
    queue_as :low_priority

    def perform(local_authority, planning_application)
      if (submission = planning_application.params_v2)
        Apis::Bops::Query.new.post(local_authority.subdomain, submission)
      else
        Appsignal.report_error("Unable to find submission data for planning application with id: #{planning_application.id}")
      end
    end
  end
end
