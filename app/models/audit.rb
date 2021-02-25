class Audit < ApplicationRecord
  belongs_to :planning_application
  belongs_to :user

  enum activity: {
    approved: 1,
    assessed: 2,
    assigned: 3,
    archived: 4,
    challenged: 5,
    created: 6,
    determined: 7,
    invalidated: 8,
    returned: 9,
    uploaded: 10,
    started: 11,
    withdrawn: 12,
  }

  # Actions where audit needs to be saved
  # creation
  # assignment
  # state change
  # document upload or archive
end
