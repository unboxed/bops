class CreateSiteVisits < ActiveRecord::Migration[6.0]
  def change
    create_table :site_visits do |t|
      t.string :notes
      t.binary :photo

      t.timestamps
    end
  end
end
