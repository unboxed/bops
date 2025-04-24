# frozen_string_literal: true

class AddSubmissionForeignKeyToPlanningApplications < ActiveRecord::Migration[7.2]
  def change
    add_foreign_key :planning_applications, :submissions, validate: false
  end
end
