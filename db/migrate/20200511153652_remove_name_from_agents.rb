class RemoveNameFromAgents < ActiveRecord::Migration[6.0]
  def change

    remove_column :agents, :name, :string
  end
end
