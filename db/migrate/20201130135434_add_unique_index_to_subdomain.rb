class AddUniqueIndexToSubdomain < ActiveRecord::Migration[6.0]
  def change
    add_index :local_authorities, :subdomain, unique: true
  end
end
