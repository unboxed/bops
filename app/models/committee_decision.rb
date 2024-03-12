# frozen_string_literal: true

class CommitteeDecision < ApplicationRecord
  belongs_to :planning_application

  validates :recommend, exclusion: {in: [nil]}

  REASONS = [
    "The application is on council owned land",
    "The application was made by the local authority",
    "The application was submitted by Councillors or officers employed by the council",
    "The application is for new buildings to provide 5 or more new homes (not flats)",
    "The application is for change of use of more than 1000sqm of non-residential floor space",
    "Other"
  ]

  before_update do
    assign_attributes(reasons: []) if !recommend
  end
end
