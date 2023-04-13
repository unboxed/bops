# frozen_string_literal: true

class PostApplicationToStagingJob < ApplicationJob
  queue_as :low_priority

  def perform(local_authority, planning_application)
    Apis::Bops::Query.new.post(local_authority.subdomain, planning_application)
  end
end
