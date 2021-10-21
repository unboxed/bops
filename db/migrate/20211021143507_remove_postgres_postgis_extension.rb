# frozen_string_literal: true

class RemovePostgresPostgisExtension < ActiveRecord::Migration[6.1]
  def up
    disable_extension("postgis") if extension_enabled?("postgis")
  end

  def down
    enable_extension("postgis")
  end
end
