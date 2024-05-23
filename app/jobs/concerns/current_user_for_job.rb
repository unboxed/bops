# frozen_string_literal: true

module CurrentUserForJob
  extend ActiveSupport::Concern

  attr_accessor :enqueueing_user

  def serialize
    super.tap do |job_data|
      if Current.user.present?
        job_data["enqueueing_user"] = Current.user.to_gid_param
      end
    end
  end

  def deserialize(job_data)
    super

    if job_data["enqueueing_user"]
      user = GlobalID::Locator.locate(job_data["enqueueing_user"])
      self.enqueueing_user = user
    end
  end

  included do
    before_perform do
      Current.user ||= enqueueing_user
    end
  end
end
