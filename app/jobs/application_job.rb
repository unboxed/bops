# frozen_string_literal: true

class ApplicationJob < ActiveJob::Base
  # Automatically retry jobs that encountered a deadlock
  # retry_on ActiveRecord::Deadlocked

  # Most jobs are safe to ignore if the underlying records
  # are no longer available discard_on ActiveJob::DeserializationError

  before_enqueue do |job|
    next unless Current.user

    if job.arguments.last.is_a?(Hash)
      job.arguments.last[:current_user] = Current.user
    else
      job.arguments << {current_user: Current.user}
    end
  end

  before_perform do |job|
    next unless job.arguments.last.is_a?(Hash)

    if job.arguments.last.key?(:current_user)
      Current.user = job.arguments.last.delete(:current_user)

      if job.arguments.last.empty?
        job.arguments.pop
      end
    end
  end
end
