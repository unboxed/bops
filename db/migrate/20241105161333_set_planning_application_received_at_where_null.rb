# frozen_string_literal: true

class SetPlanningApplicationReceivedAtWhereNull < ActiveRecord::Migration[7.1]
  def change
    up_only do
      PlanningApplication.find_each do |p|
        p.update(received_at: p.received_at || Time.next_immediate_business_day(p.created_at))
      end
    end
  end
end
