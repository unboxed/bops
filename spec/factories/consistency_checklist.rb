# frozen_string_literal: true

FactoryBot.define do
  factory :consistency_checklist do
    planning_application

    trait :complete do
      status { :complete }
    end

    trait :in_assessment do
      status { :in_assessment }
    end

    trait :all_checks_assessed do
      description_matches_documents { :yes }
      documents_consistent { :yes }
      proposal_details_match_documents { :yes }
      site_map_correct { :yes }
    end
  end
end
