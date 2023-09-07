# frozen_string_literal: true

class AddPostgisExtensionToDatabase < ActiveRecord::Migration[7.0]
  def up
    enable_extension("postgis") unless extension_enabled?("postgis")
  end

  def down
    disable_extension("postgis") if extension_enabled?("postgis")
  end
end
