class CreateConditions < ActiveRecord::Migration[7.0]
  def change
    create_table :conditions do |t|
      t.string :text
      t.text :reason
      t.references :planning_application, null: false
      t.timestamps
    end
  end
end

