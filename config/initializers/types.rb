# frozen_string_literal: true

ActiveSupport.on_load(:active_record) do
  require "types/policy_class_type"
  ActiveRecord::Type.register :policy_class, PolicyClassType
end
