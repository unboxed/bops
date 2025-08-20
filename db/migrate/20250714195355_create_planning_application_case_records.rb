# frozen_string_literal: true

class CreatePlanningApplicationCaseRecords < ActiveRecord::Migration[7.2]
  class PlanningApplication < ActiveRecord::Base; end
  class CaseRecord < ActiveRecord::Base; end

  def change
    up_only do
      PlanningApplication.all.find_each do |pa|
        CaseRecord.find_or_create_by!(
          caseable_id: pa.id,
          caseable_type: "PlanningApplication"
        ) do |record|
          record.local_authority_id = pa.attributes["local_authority_id"]
          record.user_id = pa.attributes["user_id"]
          record.submission_id = pa.attributes["submission_id"]
        end
      end
    end
  end
end
