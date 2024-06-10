# frozen_string_literal: true

class UpdateConditionsCancelledAt < ActiveRecord::Migration[7.1]
  def change
    up_only do
      Condition.find_each do |condition|
        condition.update!(cancelled_at: Time.zone.now) if condition.condition_set.pre_commencement? && condition.validation_requests.where(state: "cancelled").any?
      end
    end
  end
end
