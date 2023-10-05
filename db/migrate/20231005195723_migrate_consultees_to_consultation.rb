# frozen_string_literal: true

class MigrateConsulteesToConsultation < ActiveRecord::Migration[7.0]
  class PlanningApplication < ActiveRecord::Base
    has_one :consultation
    has_many :consultees
  end

  class Consultation < ActiveRecord::Base
    belongs_to :planning_application
    has_many :consultees
  end

  class Consultee < ActiveRecord::Base
    belongs_to :planning_application, optional: true
    belongs_to :consultation, optional: true
  end

  def change
    up_only do
      Consultee.find_each do |consultee|
        next if consultee.consultation_id?

        unless (planning_application = consultee.planning_application)
          raise "Detected an orphan consultee: #{consultee.inspect}"
        end

        consultee.consultation = \
          consultation || planning_application.create_consultation!

        consultee.save!
      end
    end
  end
end
