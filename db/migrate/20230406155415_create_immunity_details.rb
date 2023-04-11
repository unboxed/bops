class CreateImmunityDetails < ActiveRecord::Migration[7.0]
  def change
    create_table :immunity_details do |t|
      t.datetime :start_date
      t.datetime :end_date
      t.references :planning_application
      t.timestamps
    end
  end
end
