# frozen_string_literal: true

require "types/policy_class_type"

ActiveRecord::Type.register :policy_class, PolicyClassType
