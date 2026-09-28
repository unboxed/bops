# frozen_string_literal: true

class BackfillCaseRecordApplicationNumbers < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  class PlanningApplication < ActiveRecord::Base
    include Discard::Model

    self.discard_column = :deleted_at

    belongs_to :local_authority
  end

  class LocalAuthority < ActiveRecord::Base
    class ApplicationNumber < ActiveRecord::Base
      belongs_to :local_authority
    end

    has_many :application_numbers
    has_many :planning_applications
  end

  def change
    year = Time.zone.today.year
    up_only do
      LocalAuthority.find_each do |la|
        la.application_numbers.create! do |counter|
          counter.year = year
          counter.application_number = la.planning_applications
            .with_discarded
            .where(created_at: Time.zone.today.all_year)
            .maximum(:application_number) || 99
        end
      end
    end
  end
end
