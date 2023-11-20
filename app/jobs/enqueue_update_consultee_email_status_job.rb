# frozen_string_literal: true

class EnqueueUpdateConsulteeEmailStatusJob < ApplicationJob
  queue_as :low_priority

  def perform
    Consultee::Email.overdue.find_each do |consultee_email|
      UpdateConsulteeEmailStatusJob.perform_later(consultee_email)
    end
  end
end
