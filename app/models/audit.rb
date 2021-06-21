class Audit < ApplicationRecord
  belongs_to :planning_application
  belongs_to :user, optional: true
  belongs_to :api_user, optional: true

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
    updated: "updated",
    uploaded: "uploaded",
    started: "started",
    withdrawn: "withdrawn",
    document_invalidated: "document_invalidated",
    document_changed_to_validated: "document_changed_to_validated",
    description_change_request_sent: "description_change_request_sent",
  }
end
