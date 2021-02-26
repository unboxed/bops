class Audit < ApplicationRecord
  belongs_to :planning_application
  belongs_to :user

  enum activity: {
    approved: "approved",
    assessed: "assessed",
    assigned: "assigned",
    archived: "archived",
    challenged: "challenged",
    created: "created",
    determined: "determined",
    invalidated: "invalidated",
    returned: "returned",
    uploaded: "uploaded",
    started: "started",
    withdrawn: "withdrawn",
  }
end
