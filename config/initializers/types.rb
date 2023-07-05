# frozen_string_literal: true

require "types/enum_type"

ActiveModel::Type.register :enum, EnumType

ActiveSupport.on_load(:active_record) do
  require "types/policy_class_type"
  ActiveRecord::Type.register :policy_class, PolicyClassType
end
