class CreateLocalAuthorities < ActiveRecord::Migration[6.0]
  def change
    create_table :local_authorities do |t|
      t.string :name
      t.string :subdomain

      t.timestamps
    end
  end
end
