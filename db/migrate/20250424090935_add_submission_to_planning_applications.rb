# frozen_string_literal: true

class AddSubmissionToPlanningApplications < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    add_reference :planning_applications, :submission, index: {algorithm: :concurrently}
  end
end
