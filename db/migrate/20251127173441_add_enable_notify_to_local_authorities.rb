# frozen_string_literal: true

# rubocop:disable Rails/ThreeStateBooleanColumn
class AddEnableNotifyToLocalAuthorities < ActiveRecord::Migration[8.0]
  class LocalAuthority < ActiveRecord::Base; end

  def change
    add_column :local_authorities, :enable_notify, :boolean

    up_only do
      LocalAuthority.update_all(enable_notify: false)

      change_column_default :local_authorities, :enable_notify, true
      add_check_constraint :local_authorities, "enable_notify IS NOT NULL", name: "local_authorities_enable_notify_null", validate: false
    end
  end
end
# rubocop:enable Rails/ThreeStateBooleanColumn
