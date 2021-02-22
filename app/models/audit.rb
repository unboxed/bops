class Audit < ApplicationRecord

  belongs_to :planning_application

  enum activity: {
    assessed: 1,
    archived: 2,
    assigned: 3,
    challenged: 4,
    created: 5,
    determined: 6,
    invalidated: 7,
    returned: 8,
    uploaded: 9,
    started: 10,
    withdrawn: 9
  }

  #Actions where audit needs to be saved
  # creation
  # assignment
  # state change
  # document upload or archive

end
