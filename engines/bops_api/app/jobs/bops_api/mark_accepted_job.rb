# frozen_string_literal: true

module BopsApi
  class MarkAcceptedJob < ApplicationJob
    queue_as :low_priority
    discard_on ActiveJob::DeserializationError

    def perform(planning_application)
      if processed?
        planning_application.with_lock do
          if planning_application.pending?
            planning_application.mark_accepted!
          end
        end
      else
        retry_job(wait: 5.minutes)
      end
    end

    private

    def processed?
      submissions_queue.size == 0
    end

    def submissions_queue
      Sidekiq::Queue.new("submissions")
    end
  end
end
