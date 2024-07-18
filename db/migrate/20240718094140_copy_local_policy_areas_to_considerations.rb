# frozen_string_literal: true

class CopyLocalPolicyAreasToConsiderations < ActiveRecord::Migration[7.1]
  class LocalPolicy < ActiveRecord::Base
    has_many :local_policy_areas
  end

  class LocalPolicyArea < ActiveRecord::Base
    belongs_to :local_policy
  end

  class ConsiderationSet < ActiveRecord::Base
    has_many :considerations
  end

  class Consideration < ActiveRecord::Base
    belongs_to :consideration_set
    acts_as_list scope: :consideration_set
  end

  def change
    up_only do
      LocalPolicy.preload(:local_policy_areas).find_each do |lp|
        cs = ConsiderationSet.find_or_create_by!(planning_application_id: lp.planning_application_id)

        lp.local_policy_areas.each do |lpa|
          cs.considerations.create! do |c|
            c.policy_area = lpa.area
            c.policy_references = [{"code" => nil, "description" => lpa.policies, "url" => nil}]

            if lpa.guidance.present?
              c.policy_guidance = [{"description" => lpa.guidance, "url" => nil}]
            end

            c.assessment = lpa.assessment.to_s
            c.conclusion = lpa.conclusion.to_s
          end
        end
      end
    end
  end
end
