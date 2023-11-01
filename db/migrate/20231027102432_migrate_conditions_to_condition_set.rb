# frozen_string_literal: true

class MigrateConditionsToConditionSet < ActiveRecord::Migration[7.0]
  class PlanningApplication < ActiveRecord::Base
    has_one :condition_set
    has_many :conditions
  end

  class ConditionSet < ActiveRecord::Base
    belongs_to :planning_application
    has_many :conditions
  end

  class Condition < ActiveRecord::Base
    belongs_to :planning_application
    belongs_to :condition_set
  end

  def change
    change_column_null :conditions, :planning_application_id, true

    up_only do
      PlanningApplication.joins(:conditions).find_each do |pa|
        condition_set = pa.condition_set || pa.create_condition_set!

        pa.conditions.update_all(condition_set_id: condition_set.id)
      end
    end
  end
end
