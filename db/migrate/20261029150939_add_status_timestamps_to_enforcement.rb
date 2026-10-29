# frozen_string_literal: true

class AddStatusTimestampsToEnforcement < ActiveRecord::Migration[8.1]
  def change
    add_column :enforcements, :in_validation_at, :datetime
    add_column :enforcements, :in_review_at, :datetime
    add_column :enforcements, :notice_overdue_at, :datetime
    add_column :enforcements, :notice_withdrawn_at, :datetime
    add_column :enforcements, :appeal_at, :datetime
    add_column :enforcements, :prosecution_at, :datetime
    add_column :enforcements, :requested_closure_at, :datetime
  end
end
