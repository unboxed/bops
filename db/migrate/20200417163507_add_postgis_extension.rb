class AddPostgisExtension < ActiveRecord::Migration[6.0]
  def up
    enable_extension("postgis") unless extension_enabled?("postgis")
  end

  def down
    disable_extension("postgis")
  end
end
