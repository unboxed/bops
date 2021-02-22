class CreateAudits < ActiveRecord::Migration[6.0]
  def change
    create_table :audits do |t|
      t.references :planning_application, null: false, foreign_key: true
      t.references :user
      t.string :activity

      t.timestamps
    end
  end
end
